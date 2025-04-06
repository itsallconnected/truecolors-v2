import time
import logging
import functools
import threading
from datetime import datetime

class Metrics:
    """
    Simple metrics collection for CrewAI bot performance monitoring
    """
    def __init__(self):
        self.metrics = {
            'request_count': 0,
            'error_count': 0,
            'response_times': [],
            'last_request_time': None,
            'avg_response_time': 0
        }
        self.metrics_lock = threading.Lock()
        self.logger = logging.getLogger('metrics')
    
    def increment_request(self):
        """Increment request counter"""
        with self.metrics_lock:
            self.metrics['request_count'] += 1
            self.metrics['last_request_time'] = datetime.now()
    
    def increment_error(self):
        """Increment error counter"""
        with self.metrics_lock:
            self.metrics['error_count'] += 1
    
    def record_response_time(self, time_ms):
        """Record response time in milliseconds"""
        with self.metrics_lock:
            self.metrics['response_times'].append(time_ms)
            # Keep only last 100 response times
            if len(self.metrics['response_times']) > 100:
                self.metrics['response_times'].pop(0)
            
            # Calculate average
            self.metrics['avg_response_time'] = sum(self.metrics['response_times']) / len(self.metrics['response_times'])
    
    def get_metrics(self):
        """Get current metrics"""
        with self.metrics_lock:
            return self.metrics.copy()
    
    def time_function(self, name):
        """Decorator to time function execution"""
        def decorator(func):
            @functools.wraps(func)
            async def wrapper(*args, **kwargs):
                start_time = time.time()
                try:
                    self.increment_request()
                    result = await func(*args, **kwargs)
                    return result
                except Exception as e:
                    self.increment_error()
                    raise e
                finally:
                    elapsed_time = (time.time() - start_time) * 1000  # Convert to ms
                    self.record_response_time(elapsed_time)
                    self.logger.info(f"{name} took {elapsed_time:.2f}ms")
            return wrapper
        return decorator
