import time
import hashlib
import threading
import logging

class ResponseCache:
    """
    Simple in-memory cache for bot responses to avoid duplicate processing
    """
    def __init__(self, max_size=100, ttl=3600):
        self.cache = {}
        self.max_size = max_size
        self.ttl = ttl  # Time to live in seconds
        self.lock = threading.Lock()
        self.logger = logging.getLogger('cache')
    
    def _generate_key(self, agent_name, task_name, content):
        """Generate a cache key based on request parameters"""
        key_string = f"{agent_name}:{task_name}:{content}"
        return hashlib.md5(key_string.encode()).hexdigest()
    
    def get(self, agent_name, task_name, content):
        """Get a cached response if it exists and is valid"""
        key = self._generate_key(agent_name, task_name, content)
        
        with self.lock:
            if key in self.cache:
                entry = self.cache[key]
                if time.time() - entry['timestamp'] < self.ttl:
                    self.logger.debug(f"Cache hit for {agent_name}/{task_name}")
                    return entry['response']
                else:
                    # Expired entry
                    self.logger.debug(f"Cache expired for {agent_name}/{task_name}")
                    del self.cache[key]
            
            return None
    
    def set(self, agent_name, task_name, content, response):
        """Store a response in the cache"""
        key = self._generate_key(agent_name, task_name, content)
        
        with self.lock:
            # Evict oldest entries if cache is full
            if len(self.cache) >= self.max_size:
                oldest_key = min(self.cache.items(), key=lambda x: x[1]['timestamp'])[0]
                del self.cache[oldest_key]
            
            self.cache[key] = {
                'response': response,
                'timestamp': time.time()
            }
            self.logger.debug(f"Cached response for {agent_name}/{task_name}")
    
    def clear(self):
        """Clear the entire cache"""
        with self.lock:
            self.cache.clear()
            self.logger.debug("Cache cleared")
    
    def clear_expired(self):
        """Clear only expired entries"""
        with self.lock:
            now = time.time()
            expired_keys = [k for k, v in self.cache.items() if now - v['timestamp'] > self.ttl]
            for key in expired_keys:
                del self.cache[key]
            
            if expired_keys:
                self.logger.debug(f"Cleared {len(expired_keys)} expired cache entries")
