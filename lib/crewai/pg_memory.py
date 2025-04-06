import psycopg2
from cryptography.fernet import Fernet
from langchain.memory.chat_memory import BaseChatMemory
import logging

class PostgresMemory(BaseChatMemory):
    def __init__(self, db_url, room_id, encryption_key):
        super().__init__()
        self.conn = psycopg2.connect(db_url)
        self.room_id = room_id
        self.fernet = Fernet(encryption_key)
        
    def load_memory_variables(self, inputs):
        try:
            with self.conn.cursor() as cur:
                cur.execute(
                    "SELECT encrypted_content FROM chat_messages WHERE room_id=%s ORDER BY created_at ASC LIMIT 100",
                    (self.room_id,)
                )
                rows = cur.fetchall()
                
                if not rows:
                    return {"chat_history": ""}
                    
                # Safely decrypt messages
                decrypted = []
                for row in rows:
                    try:
                        decrypted.append(self.fernet.decrypt(row[0]).decode())
                    except Exception as e:
                        logging.error(f"Failed to decrypt message: {e}")
                        # Skip this message
                        
                history = "\n".join(decrypted)
                
                # Summarize if needed
                summarized_history = self.summarize_if_needed(history)
                
                return {"chat_history": summarized_history}
        except Exception as e:
            logging.error(f"Error loading memory variables: {e}")
            # Return empty context so the conversation can still proceed
            return {"chat_history": ""}
            
    def save_context(self, inputs, outputs):
        try:
            # Get input content or use fallback
            input_content = inputs.get('input', '')
            
            # Get output content, checking multiple possible formats
            if hasattr(outputs, 'get'):
                output_content = outputs.get('reply', str(outputs))
            else:
                output_content = str(outputs)
            
            message = f"User: {input_content}\nAI: {output_content}"
            
            try:
                encrypted = self.fernet.encrypt(message.encode())
            except Exception as e:
                logging.error(f"Encryption error: {e}")
                # Fallback to simple encoding if encryption fails
                encrypted = f"ERROR_ENCRYPTING: {message}".encode()
            
            try:
                with self.conn.cursor() as cur:
                    cur.execute(
                        "INSERT INTO chat_messages (room_id, encrypted_content) VALUES (%s, %s)",
                        (self.room_id, encrypted)
                    )
                    self.conn.commit()
            except Exception as e:
                logging.error(f"Database error when saving context: {e}")
                # Try to reconnect if connection was lost
                try:
                    self.conn = psycopg2.connect(self.db_url)
                    with self.conn.cursor() as cur:
                        cur.execute(
                            "INSERT INTO chat_messages (room_id, encrypted_content) VALUES (%s, %s)",
                            (self.room_id, encrypted)
                        )
                        self.conn.commit()
                except Exception as reconnect_error:
                    logging.error(f"Reconnection failed: {reconnect_error}")
        except Exception as e:
            logging.error(f"Unexpected error in save_context: {e}")
            
    def clear(self):
        with self.conn.cursor() as cur:
            cur.execute("DELETE FROM chat_messages WHERE room_id=%s", (self.room_id,))
            self.conn.commit()

    def summarize_if_needed(self, history, max_tokens=8000):
        """Summarize history if it gets too long"""
        # Estimate token count (rough approximation)
        estimated_tokens = len(history.split()) * 1.3
        
        if estimated_tokens > max_tokens:
            # Connect to Ollama for summarization
            try:
                from langchain_ollama import ChatOllama
                
                summarizer = ChatOllama(
                    model="mixtral",
                    temperature=0.3  # Lower temperature for more factual summary
                )
                
                prompt = f"""
                Summarize the following conversation history concisely, focusing on key points 
                and preserving important information:
                
                {history}
                """
                
                summary = summarizer.invoke(prompt).text
                return f"[SUMMARY OF PREVIOUS CONVERSATION]: {summary}\n\n[RECENT MESSAGES]:\n"
            except Exception as e:
                logging.error(f"Failed to summarize history: {e}")
                # If summarization fails, truncate instead
                return "...[Earlier conversation omitted]...\n\n" + history[-4000:]
        
        return history