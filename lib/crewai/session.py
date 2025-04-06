import time
import threading
import logging
import uuid

class Session:
    """
    Represents a single user session with the bot
    """
    def __init__(self, user_jid, room_jid):
        self.id = str(uuid.uuid4())
        self.user_jid = user_jid
        self.room_jid = room_jid
        self.created_at = time.time()
        self.last_activity = time.time()
        self.metadata = {}
        self.context = {}
    
    def update_activity(self):
        """Update last activity timestamp"""
        self.last_activity = time.time()
    
    def is_expired(self, timeout=3600):
        """Check if session is expired based on inactivity"""
        return time.time() - self.last_activity > timeout

class SessionManager:
    """
    Manages user sessions for maintaining context between interactions
    """
    def __init__(self, session_timeout=3600):
        self.sessions = {}
        self.session_timeout = session_timeout  # Session timeout in seconds
        self.lock = threading.Lock()
        self.logger = logging.getLogger('session')
    
    def get_session(self, user_jid, room_jid):
        """Get an existing session or create a new one"""
        session_key = f"{user_jid}:{room_jid}"
        
        with self.lock:
            # Check if session exists and is not expired
            if session_key in self.sessions:
                session = self.sessions[session_key]
                if not session.is_expired(self.session_timeout):
                    session.update_activity()
                    return session
                else:
                    # Session expired, remove it
                    self.logger.debug(f"Session expired for {user_jid} in {room_jid}")
                    del self.sessions[session_key]
            
            # Create new session
            session = Session(user_jid, room_jid)
            self.sessions[session_key] = session
            self.logger.debug(f"Created new session for {user_jid} in {room_jid}")
            return session
    
    def update_session_context(self, user_jid, room_jid, key, value):
        """Update context for a specific session"""
        session = self.get_session(user_jid, room_jid)
        
        with self.lock:
            session.context[key] = value
            session.update_activity()
    
    def get_session_context(self, user_jid, room_jid, key, default=None):
        """Get context value from a session"""
        session = self.get_session(user_jid, room_jid)
        return session.context.get(key, default)
    
    def clear_session(self, user_jid, room_jid):
        """Clear a specific session"""
        session_key = f"{user_jid}:{room_jid}"
        
        with self.lock:
            if session_key in self.sessions:
                del self.sessions[session_key]
                self.logger.debug(f"Cleared session for {user_jid} in {room_jid}")
    
    def cleanup_expired_sessions(self):
        """Remove all expired sessions"""
        with self.lock:
            expired_keys = []
            for key, session in self.sessions.items():
                if session.is_expired(self.session_timeout):
                    expired_keys.append(key)
            
            for key in expired_keys:
                del self.sessions[key]
            
            if expired_keys:
                self.logger.debug(f"Cleaned up {len(expired_keys)} expired sessions") 