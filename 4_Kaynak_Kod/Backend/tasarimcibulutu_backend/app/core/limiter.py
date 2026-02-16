# Dosya Yolu: app/core/limiter.py

from slowapi import Limiter
from slowapi.util import get_remote_address

# Limiter'ı burada tanımlıyoruz, böylece her yerden çağrılabilir.
limiter = Limiter(key_func=get_remote_address, default_limits=["200/minute"])