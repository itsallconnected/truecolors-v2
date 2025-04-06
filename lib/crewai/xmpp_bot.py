import asyncio
import logging
from slixmpp import ClientXMPP
from crewai import Crew, Agent, Task
from langchain_ollama import ChatOllama
import yaml
import psycopg2
from cryptography.fernet import Fernet
from pg_memory import PostgresMemory
import time
from functools import wraps
import os
from metrics import Metrics
from cache import ResponseCache
from session import SessionManager

def retry_on_exception(max_retries=3, delay=2):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            retries = 0
            while retries < max_retries:
                try:
                    return await func(*args, **kwargs)
                except Exception as e:
                    retries += 1
                    if retries == max_retries:
                        raise
                    logging.warning(f"Error: {e}. Retrying in {delay} seconds... (Attempt {retries}/{max_retries})")
                    await asyncio.sleep(delay)
        return wrapper
    return decorator

class TrueColorsBot(ClientXMPP):
    def __init__(self, jid, password, db_url):
        super().__init__(jid, password)
        self.db_url = db_url
        self.load_config()
        
        # Rate limiting
        self.rate_limits = {}
        self.rate_limit_window = 60  # seconds
        self.rate_limit_max = 5      # requests per window
        
        # Add plugins
        self.register_plugin('xep_0045')  # Multi-User Chat
        self.register_plugin('xep_0199')  # XMPP Ping
        self.register_plugin('xep_0085')  # Chat State Notifications
        
        # Event handlers
        self.add_event_handler("session_start", self.start)
        self.add_event_handler("groupchat_message", self.on_groupchat)
        
        # Initialize metrics
        self.metrics = Metrics()
        
        # Initialize cache
        self.cache = ResponseCache()
        
        # Initialize session manager
        self.session_manager = SessionManager()
        
    def load_config(self):
        # Load agents and tasks from YAML
        with open("config/agents.yaml") as f:
            self.agent_configs = yaml.safe_load(f)
            
        with open("config/tasks.yaml") as f:
            self.task_configs = yaml.safe_load(f)
    
    async def start(self, event):
        await self.get_roster()
        self.send_presence()
        
        # Join rooms from database
        conn = psycopg2.connect(self.db_url)
        with conn.cursor() as cursor:
            cursor.execute("SELECT id, xmpp_jid FROM chat_rooms WHERE active = true")
            for row in cursor.fetchall():
                room_id, room_jid = row
                self.plugin['xep_0045'].join_muc(room_jid, self.boundjid.localpart)
                logging.info(f"Joined room: {room_jid}")
        conn.close()
    
    async def on_groupchat(self, msg):
        if msg['mucnick'] == self.boundjid.localpart:
            return
            
        body = msg['body'].strip()
        room_jid = msg['from'].bare
        user_jid = f"{msg['mucnick']}@{self.boundjid.domain}"
        
        # Check for agent commands
        for agent_name in self.agent_configs.keys():
            if body.startswith(f"@{agent_name}"):
                # Check rate limit
                if not self.check_rate_limit(user_jid):
                    self.send_message(mto=room_jid, 
                                     mbody=f"Rate limit exceeded. Please try again later.", 
                                     mtype='groupchat')
                    return
                    
                await self.process_agent_message(agent_name, body, room_jid)
                break
    
    @retry_on_exception(max_retries=3, delay=2)
    @metrics.time_function('process_agent_message')
    async def process_agent_message(self, agent_name, body, room_jid):
        # Get room info and encryption key
        conn = psycopg2.connect(self.db_url)
        with conn.cursor() as cursor:
            cursor.execute("SELECT id, room_key FROM chat_rooms WHERE xmpp_jid = %s", (room_jid,))
            result = cursor.fetchone()
            if not result:
                self.send_message(mto=room_jid, 
                                 mbody="Error: Room not registered in database", 
                                 mtype='groupchat')
                return
                
            room_id, encrypted_key = result
        conn.close()
        
        # Extract task from message
        parts = body.split(' ', 2)
        task_name = parts[1] if len(parts) > 1 else "default"
        content = parts[2] if len(parts) > 2 else ""
        
        # Encrypt content for Ollama (using room key)
        fernet = Fernet(encrypted_key)
        encrypted_content = fernet.encrypt(content.encode()).decode()
        
        try:
            # Initialize memory with encryption
            memory = PostgresMemory(
                db_url=self.db_url,
                room_id=room_id,
                encryption_key=encrypted_key
            )
            
            # Create agent
            agent_config = self.agent_configs[agent_name]
            agent = Agent(
                role=agent_config['role'],
                goal=agent_config['goal'],
                backstory=agent_config['backstory'],
                memory=memory,
                verbose=True,
                llm=ChatOllama(
                    model="mixtral",
                    temperature=0.7,
                    top_p=0.9,
                    max_tokens=4096
                )
            )
            
            # Create task with encrypted content
            if task_name in self.task_configs:
                task_config = self.task_configs[task_name]
                task = Task(
                    description=task_config['description'].format(content=f"ENCRYPTED:{encrypted_content}"),
                    expected_output=task_config['expected_output'],
                    agent=agent
                )
                
                # Run crew with single agent and task
                crew = Crew(
                    agents=[agent],
                    tasks=[task],
                    verbose=True
                )
                
                # Tell user we're processing
                self.send_message(mto=room_jid, 
                                 mbody=f"Processing request for {agent_name} / {task_name}...", 
                                 mtype='groupchat')
                
                # Run the crew and get encrypted result
                result = await asyncio.to_thread(crew.kickoff, inputs={"input": encrypted_content})
                
                # Decrypt the result before sending
                decrypted_result = fernet.decrypt(result.encode()).decode()
                
                # Send decrypted result back to room
                self.send_message(mto=room_jid, mbody=decrypted_result, mtype='groupchat')
                
                # Save the interaction in the database (still encrypted)
                await self.save_interaction(room_id, agent_name, task_name, encrypted_content, result)
                
            else:
                self.send_message(mto=room_jid, 
                                 mbody=f"Unknown task: {task_name}", 
                                 mtype='groupchat')
        except Exception as e:
            logging.error(f"Error processing message: {e}")
            self.send_message(mto=room_jid, 
                             mbody=f"Error: {str(e)}", 
                             mtype='groupchat')

    async def save_interaction(self, room_id, agent_name, task_name, input_content, result):
        """Save the interaction in the database for future reference"""
        conn = psycopg2.connect(self.db_url)
        try:
            with conn.cursor() as cursor:
                # Get room key for encryption
                cursor.execute("SELECT room_key FROM chat_rooms WHERE id = %s", (room_id,))
                room_key = cursor.fetchone()[0]
                
                # Encrypt content
                fernet = Fernet(room_key)
                encrypted_content = fernet.encrypt(f"Task: {task_name}\nInput: {input_content}\nResult: {result}".encode())
                
                # Save as a message
                cursor.execute(
                    "INSERT INTO chat_messages (room_id, agent_name, encrypted_content) VALUES (%s, %s, %s)",
                    (room_id, agent_name, encrypted_content)
                )
                conn.commit()
        except Exception as e:
            logging.error(f"Error saving interaction: {e}")
        finally:
            conn.close()

    def check_rate_limit(self, user_jid):
        """Check if user has exceeded rate limit"""
        now = time.time()
        
        # Clean up old entries
        for jid in list(self.rate_limits.keys()):
            if self.rate_limits[jid]['reset_time'] < now:
                del self.rate_limits[jid]
        
        # Check if user is in rate limits
        if user_jid not in self.rate_limits:
            self.rate_limits[user_jid] = {
                'count': 1,
                'reset_time': now + self.rate_limit_window
            }
            return True
        
        # Check if user has exceeded limit
        if self.rate_limits[user_jid]['count'] >= self.rate_limit_max:
            return False
        
        # Increment count
        self.rate_limits[user_jid]['count'] += 1
        return True