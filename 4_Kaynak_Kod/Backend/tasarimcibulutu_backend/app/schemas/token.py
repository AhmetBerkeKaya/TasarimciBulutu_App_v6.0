# schemas/token.py

from pydantic import BaseModel

class Token(BaseModel):
    access_token: str
    token_type: str
    # YENİ: refresh_token alanını ekliyoruz
    refresh_token: str

class TokenData(BaseModel):
    email: str | None = None

# YENİ: Refresh token endpoint'i için yeni bir schema
class RefreshTokenRequest(BaseModel):
    refresh_token: str
