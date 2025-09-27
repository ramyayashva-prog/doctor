# PaddleOCR FastAPI Microservice Package

__version__ = "1.0.0"
__author__ = "PaddleOCR Team"

# Import key services to make them available
try:
    from .services.enhanced_ocr_service import EnhancedOCRService
    from .services.ocr_service import OCRService
    from .services.webhook_service import WebhookService
    from .services.webhook_config_service import WebhookConfigService
    from .models.webhook_config import WebhookConfig, WebhookConfigCreate
    
    __all__ = [
        'EnhancedOCRService',
        'OCRService', 
        'WebhookService',
        'WebhookConfigService',
        'WebhookConfig',
        'WebhookConfigCreate'
    ]
except ImportError:
    # If imports fail, still allow the package to be imported
    __all__ = []
