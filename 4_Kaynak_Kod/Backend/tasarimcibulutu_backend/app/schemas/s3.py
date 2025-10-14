# app/schemas/s3.py
from pydantic import BaseModel
from typing import Dict

class PresignedPostResponse(BaseModel):
    url: str
    fields: Dict[str, str]
    file_path: str