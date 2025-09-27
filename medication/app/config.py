import os
from typing import List, Dict, Any
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """Application configuration settings"""
    
    # Service Configuration
    APP_NAME: str = "PaddleOCR Microservice"
    APP_VERSION: str = "1.0.0"
    APP_DESCRIPTION: str = "A microservice for text recognition using PaddleOCR"
    
    # Server Configuration
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    DEBUG: bool = False
    
    # PaddleOCR Configuration
    PADDLE_OCR_LANG: str = "en"
    PADDLE_OCR_USE_ANGLE_CLS: bool = True
    PADDLE_OCR_SHOW_LOG: bool = False
    
    # CORS Configuration
    CORS_ORIGINS: List[str] = ["*"]
    CORS_ALLOW_CREDENTIALS: bool = True
    CORS_ALLOW_METHODS: List[str] = ["*"]
    CORS_ALLOW_HEADERS: List[str] = ["*"]
    
    # Logging Configuration
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    
    # Health Check Configuration
    HEALTH_CHECK_ENABLED: bool = True
    
    # File Upload Configuration
    MAX_FILE_SIZE: int = 10 * 1024 * 1024  # 10MB
    ALLOWED_IMAGE_TYPES: List[str] = ["image/jpeg", "image/png", "image/gif", "image/bmp", "image/tiff"]
    
    # Enhanced File Types Configuration (for PDF, TXT, DOC, DOCX processing)
    ALLOWED_ENHANCED_TYPES: List[str] = [
        # Images
        "image/jpeg", "image/png", "image/gif", "image/bmp", "image/tiff", "image/tif",
        
        # PDF documents (various MIME types)
        "application/pdf",  # Standard PDF
        "application/x-pdf",  # Alternative PDF MIME type
        "binary/octet-stream",  # Generic binary (some PDFs)
        
        # Text files
        "text/plain",  # TXT files
        "text/plain; charset=utf-8",  # TXT with charset
        "text/plain; charset=iso-8859-1",  # TXT with different charset
        
        # Word documents
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",  # DOCX
        "application/msword",  # DOC
        "application/vnd.ms-word",  # Alternative DOC MIME type
        
        # Generic binary and application types
        "application/octet-stream",  # Generic binary
        "application/binary",  # Alternative binary
        "binary/pdf",  # Some systems use this
        "application/force-download",  # Force download type
        
        # Content types that might be used
        "content/unknown",  # Unknown content type
        "application/x-download",  # Download type
        "application/unknown"  # Unknown application type
    ]
    
    # File extension mapping for enhanced processing
    ENHANCED_FILE_EXTENSIONS: Dict[str, List[str]] = {
        'pdf': ['.pdf'],
        'text': ['.txt', '.doc', '.docx'],
        'image': ['.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.tif']
    }
    
    # Webhook Configuration
    WEBHOOK_ENABLED: bool = True
    
    # Default webhook settings (these can be overridden via API)
    DEFAULT_WEBHOOK_URL: str = ""
    DEFAULT_WEBHOOK_METHOD: str = "POST"
    DEFAULT_WEBHOOK_TIMEOUT: int = 30
    DEFAULT_WEBHOOK_RETRY_ATTEMPTS: int = 3
    DEFAULT_WEBHOOK_RETRY_DELAY: int = 1
    
    # Default webhook headers (JSON format)
    DEFAULT_WEBHOOK_HEADERS: str = '{"Content-Type": "application/json"}'
    
    # Default webhook payload template (JSON format, leave empty for default)
    DEFAULT_WEBHOOK_PAYLOAD_TEMPLATE: str = ""
    
    # Webhook configuration file path (relative to application root)
    WEBHOOK_CONFIG_FILE: str = "webhook_configs.json"
    
    # Webhook security settings
    WEBHOOK_MAX_CONFIGS: int = 100
    WEBHOOK_ALLOW_EXTERNAL_URLS: bool = True
    WEBHOOK_REQUIRE_AUTHENTICATION: bool = False
    
    # Legacy webhook settings (for backward compatibility)
    N8N_WEBHOOK_URL: str = ""
    WEBHOOK_TIMEOUT: int = 30
    WEBHOOK_RETRY_ATTEMPTS: int = 3
    
    # Additional environment variables (optional)
    SENDER_EMAIL: str = ""
    SENDER_PASSWORD: str = ""
    MONGO_URI: str = ""
    DB_NAME: str = ""
    OPENAI_API_KEY: str = ""
    LLM_MODEL: str = ""
    MONGO_COLLECTION: str = ""
    QDRANT_URL: str = ""
    QDRANT_API_KEY: str = ""
    QDRANT_COLLECTION: str = ""
    EMBEDDING_MODEL: str = ""
    VECTOR_SIZE: str = ""
    TOP_K: str = ""
    RETRIEVAL_MIN_SCORE: str = ""
    
    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "ignore"  # Allow extra fields from environment variables

# Global settings instance
settings = Settings()
