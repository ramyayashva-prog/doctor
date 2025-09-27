from fastapi import APIRouter, File, UploadFile, HTTPException, Depends
from fastapi.responses import JSONResponse
import logging
from typing import Dict, Any, List
from datetime import datetime

from app.services.ocr_service import OCRService
from app.services.webhook_service import WebhookService
from app.services.webhook_config_service import WebhookConfigService
from app.services.enhanced_ocr_service import EnhancedOCRService
from app.models.schemas import (
    Base64ImageRequest, OCRResponse, HealthResponse, 
    LanguagesResponse, ServiceInfo, ErrorResponse
)
from app.models.webhook_config import (
    WebhookConfig, WebhookConfigCreate, WebhookConfigUpdate, WebhookResponse
)
from app.config import settings

logger = logging.getLogger(__name__)

# Create router
router = APIRouter()

# Dependency to get OCR service
def get_ocr_service() -> OCRService:
    """Dependency to get OCR service instance"""
    return OCRService()

# Dependency to get enhanced OCR service
def get_enhanced_ocr_service() -> EnhancedOCRService:
    """Dependency to get enhanced OCR service instance"""
    return EnhancedOCRService()

# Dependency to get webhook service
def get_webhook_service() -> WebhookService:
    """Dependency to get webhook service instance"""
    return WebhookService()

# Dependency to get webhook config service
def get_webhook_config_service() -> WebhookConfigService:
    """Dependency to get webhook config service instance"""
    return WebhookConfigService()

@router.get("/", response_model=ServiceInfo, tags=["Service Info"])
async def root():
    """Root endpoint - Service information"""
    return ServiceInfo(
        name=settings.APP_NAME,
        version=settings.APP_VERSION,
        description=settings.APP_DESCRIPTION,
        status="running"
    )

@router.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check(ocr_service: OCRService = Depends(get_ocr_service)):
    """Health check endpoint"""
    try:
        status = ocr_service.get_service_status()
        return HealthResponse(**status)
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(status_code=500, detail="Health check failed")

# Enhanced OCR endpoints (more specific, should come first)
@router.post("/ocr/enhanced/upload", response_model=OCRResponse, tags=["Enhanced OCR"])
async def enhanced_ocr_upload(
    file: UploadFile = File(...),
    enhanced_ocr_service: EnhancedOCRService = Depends(get_enhanced_ocr_service),
    webhook_service: WebhookService = Depends(get_webhook_service)
):
    """Extract text from uploaded file (PDF, TXT, DOC, DOCX, Images)"""
    try:
        # Enhanced debugging to clearly identify this endpoint
        logger.info("🚀 ENHANCED OCR ENDPOINT CALLED - Processing file with enhanced service")
        logger.info(f"Enhanced OCR upload - Filename: {file.filename}, Content-Type: {file.content_type}")
        
        # Validate file type first
        if not enhanced_ocr_service.validate_file_type(file.content_type, file.filename):
            logger.warning(f"Enhanced OCR: File type validation failed - Content-Type: {file.content_type}, Filename: {file.filename}")
            logger.warning(f"Enhanced OCR: Allowed types: {enhanced_ocr_service.allowed_types}")
            raise HTTPException(
                status_code=400, 
                detail=f"Enhanced OCR: Unsupported file type: {file.content_type}. Allowed types: {enhanced_ocr_service.allowed_types}"
            )
        
        logger.info(f"Enhanced OCR: File type validation passed for {file.filename}")
        
        # Read file content
        contents = await file.read()
        file_size = len(contents)
        
        logger.info(f"Enhanced OCR: Processing uploaded file: {file.filename}, size: {file_size} bytes, type: {file.content_type}")
        
        # Process file using enhanced OCR service
        result = await enhanced_ocr_service.process_file(
            file_content=contents,
            filename=file.filename
        )
        
        logger.info(f"Enhanced OCR: Successfully processed {file.filename}")
        
        # Send results to webhook (n8n) if processing was successful
        if result.get("success"):
            try:
                logger.info(f"🚀 Sending PDF results to webhook (n8n) for {file.filename}")
                webhook_results = await webhook_service.send_ocr_result(result, file.filename)
                
                # Log webhook delivery status
                for webhook_result in webhook_results:
                    if webhook_result["success"]:
                        logger.info(f"✅ Webhook sent successfully to {webhook_result['config_name']} ({webhook_result['url']})")
                    else:
                        logger.warning(f"❌ Webhook failed for {webhook_result['config_name']}: {webhook_result.get('error', 'Unknown error')}")
                
                # Add webhook status to result
                result["webhook_delivery"] = {
                    "status": "completed",
                    "results": webhook_results,
                    "timestamp": datetime.utcnow().isoformat()
                }
                
            except Exception as e:
                logger.error(f"❌ Error sending webhook for {file.filename}: {e}")
                result["webhook_delivery"] = {
                    "status": "failed",
                    "error": str(e),
                    "timestamp": datetime.utcnow().isoformat()
                }
        else:
            logger.warning(f"⚠️ OCR processing failed for {file.filename}, skipping webhook delivery")
        
        return OCRResponse(**result)
        
    except HTTPException:
        raise
    except ValueError as e:
        logger.warning(f"Validation error for file {file.filename}: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error processing uploaded file {file.filename}: {e}")
        raise HTTPException(status_code=500, detail=f"Error processing file: {str(e)}")

@router.get("/ocr/enhanced/formats", tags=["Enhanced OCR"])
async def get_supported_formats(
    enhanced_ocr_service: EnhancedOCRService = Depends(get_enhanced_ocr_service)
):
    """Get list of supported file formats"""
    try:
        formats = enhanced_ocr_service.get_supported_formats()
        return {
            "supported_formats": formats,
            "description": "File formats supported by enhanced OCR service"
        }
    except Exception as e:
        logger.error(f"Error getting supported formats: {e}")
        raise HTTPException(status_code=500, detail="Error retrieving supported formats")

# Regular OCR endpoints (more general, should come after)
@router.post("/ocr/upload", response_model=OCRResponse, tags=["OCR"])
async def ocr_upload(
    file: UploadFile = File(...),
    ocr_service: OCRService = Depends(get_ocr_service)
):
    """Extract text from uploaded image file"""
    try:
        # Enhanced debugging to clearly identify this endpoint
        logger.info("🖼️ REGULAR OCR ENDPOINT CALLED - Processing image with regular OCR service")
        logger.info(f"Regular OCR: Processing uploaded file: {file.filename}, Content-Type: {file.content_type}")
        
        # Read file content
        contents = await file.read()
        file_size = len(contents)
        
        logger.info(f"Regular OCR: Processing uploaded file: {file.filename}, size: {file_size} bytes")
        
        # Process image using OCR service
        result = await ocr_service.process_image_file(
            file_data=contents,
            filename=file.filename,
            content_type=file.content_type,
            file_size=file_size
        )
        
        logger.info(f"Regular OCR: Successfully processed {file.filename}")
        return OCRResponse(**result)
        
    except ValueError as e:
        logger.warning(f"Validation error for file {file.filename}: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error processing uploaded file {file.filename}: {e}")
        raise HTTPException(status_code=500, detail=f"Error processing file: {str(e)}")

@router.post("/ocr/base64", response_model=OCRResponse, tags=["OCR"])
async def ocr_base64(
    image_data: Base64ImageRequest,
    ocr_service: OCRService = Depends(get_ocr_service)
):
    """Extract text from base64 encoded image"""
    try:
        logger.info("Processing base64 encoded image")
        
        # Process base64 image using OCR service
        result = await ocr_service.process_base64_image(image_data.image)
        
        return OCRResponse(**result)
        
    except ValueError as e:
        logger.warning(f"Validation error for base64 image: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error processing base64 image: {e}")
        raise HTTPException(status_code=500, detail=f"Error processing base64 image: {str(e)}")

@router.get("/ocr/languages", response_model=LanguagesResponse, tags=["OCR"])
async def get_supported_languages(ocr_service: OCRService = Depends(get_ocr_service)):
    """Get list of supported languages"""
    try:
        languages = ocr_service.get_supported_languages()
        return LanguagesResponse(**languages)
    except Exception as e:
        logger.error(f"Error getting supported languages: {e}")
        raise HTTPException(status_code=500, detail="Error retrieving supported languages")

# Webhook Configuration Management Endpoints
@router.get("/webhook/configs", response_model=List[WebhookConfig], tags=["Webhook Config"])
async def get_all_webhook_configs(
    config_service: WebhookConfigService = Depends(get_webhook_config_service)
):
    """Get all webhook configurations"""
    try:
        configs = config_service.get_all_configs()
        return configs
    except Exception as e:
        logger.error(f"Error getting webhook configs: {e}")
        raise HTTPException(status_code=500, detail="Error retrieving webhook configurations")

@router.get("/webhook/configs/{config_id}", response_model=WebhookConfig, tags=["Webhook Config"])
async def get_webhook_config(
    config_id: str,
    config_service: WebhookConfigService = Depends(get_webhook_config_service)
):
    """Get specific webhook configuration by ID"""
    try:
        config = config_service.get_config(config_id)
        if not config:
            raise HTTPException(status_code=404, detail="Webhook configuration not found")
        return config
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting webhook config {config_id}: {e}")
        raise HTTPException(status_code=500, detail="Error retrieving webhook configuration")

@router.post("/webhook/configs", response_model=WebhookConfig, tags=["Webhook Config"])
async def create_webhook_config(
    config_data: WebhookConfigCreate,
    config_service: WebhookConfigService = Depends(get_webhook_config_service)
):
    """Create a new webhook configuration"""
    try:
        config = config_service.create_config(config_data)
        return config
    except Exception as e:
        logger.error(f"Error creating webhook config: {e}")
        raise HTTPException(status_code=500, detail="Error creating webhook configuration")

@router.put("/webhook/configs/{config_id}", response_model=WebhookConfig, tags=["Webhook Config"])
async def update_webhook_config(
    config_id: str,
    config_data: WebhookConfigUpdate,
    config_service: WebhookConfigService = Depends(get_webhook_config_service)
):
    """Update webhook configuration"""
    try:
        config = config_service.update_config(config_id, config_data)
        if not config:
            raise HTTPException(status_code=404, detail="Webhook configuration not found")
        return config
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating webhook config {config_id}: {e}")
        raise HTTPException(status_code=500, detail="Error updating webhook configuration")

@router.delete("/webhook/configs/{config_id}", tags=["Webhook Config"])
async def delete_webhook_config(
    config_id: str,
    config_service: WebhookConfigService = Depends(get_webhook_config_service)
):
    """Delete webhook configuration"""
    try:
        success = config_service.delete_config(config_id)
        if not success:
            raise HTTPException(status_code=404, detail="Webhook configuration not found")
        return {"message": "Webhook configuration deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting webhook config {config_id}: {e}")
        raise HTTPException(status_code=500, detail="Error deleting webhook configuration")

@router.post("/webhook/configs/{config_id}/enable", tags=["Webhook Config"])
async def enable_webhook_config(
    config_id: str,
    config_service: WebhookConfigService = Depends(get_webhook_config_service)
):
    """Enable webhook configuration"""
    try:
        success = config_service.enable_config(config_id)
        if not success:
            raise HTTPException(status_code=404, detail="Webhook configuration not found")
        return {"message": "Webhook configuration enabled successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error enabling webhook config {config_id}: {e}")
        raise HTTPException(status_code=500, detail="Error enabling webhook configuration")

@router.post("/webhook/configs/{config_id}/disable", tags=["Webhook Config"])
async def disable_webhook_config(
    config_id: str,
    config_service: WebhookConfigService = Depends(get_webhook_config_service)
):
    """Disable webhook configuration"""
    try:
        success = config_service.disable_config(config_id)
        if not success:
            raise HTTPException(status_code=404, detail="Webhook configuration not found")
        return {"message": "Webhook configuration disabled successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error disabling webhook config {config_id}: {e}")
        raise HTTPException(status_code=500, detail="Error disabling webhook configuration")

@router.post("/webhook/configs/{config_id}/test", tags=["Webhook Config"])
async def test_webhook_config(
    config_id: str,
    config_service: WebhookConfigService = Depends(get_webhook_config_service)
):
    """Test webhook configuration"""
    try:
        result = config_service.test_config(config_id)
        return result
    except Exception as e:
        logger.error(f"Error testing webhook config {config_id}: {e}")
        raise HTTPException(status_code=500, detail="Error testing webhook configuration")

@router.get("/webhook/configs/summary", tags=["Webhook Config"])
async def get_webhook_config_summary(
    config_service: WebhookConfigService = Depends(get_webhook_config_service)
):
    """Get webhook configuration summary"""
    try:
        summary = config_service.get_config_summary()
        return summary
    except Exception as e:
        logger.error(f"Error getting webhook config summary: {e}")
        raise HTTPException(status_code=500, detail="Error retrieving webhook configuration summary")

@router.get("/webhook/environment", tags=["Webhook Config"])
async def get_webhook_environment_info(
    config_service: WebhookConfigService = Depends(get_webhook_config_service)
):
    """Get webhook environment configuration information"""
    try:
        env_info = config_service.get_environment_info()
        return env_info
    except Exception as e:
        logger.error(f"Error getting webhook environment info: {e}")
        raise HTTPException(status_code=500, detail="Error retrieving webhook environment information")

# Webhook Service Endpoints
@router.get("/webhook/status", tags=["Webhook"])
async def get_webhook_status(webhook_service: WebhookService = Depends(get_webhook_service)):
    """Get webhook service status and configuration"""
    try:
        status = webhook_service.get_webhook_status()
        return {
            "webhook_status": status,
            "timestamp": datetime.utcnow().isoformat()
        }
    except Exception as e:
        logger.error(f"Error getting webhook status: {e}")
        raise HTTPException(status_code=500, detail="Error retrieving webhook status")

@router.post("/webhook/test", tags=["Webhook"])
async def test_webhook(
    webhook_service: WebhookService = Depends(get_webhook_service)
):
    """Test webhook delivery to n8n"""
    try:
        # Create test OCR data
        test_data = {
            "success": True,
            "filename": "test_pdf.pdf",
            "text_count": 3,
            "results": [
                {
                    "text": "Test Text 1",
                    "confidence": 0.95,
                    "bbox": [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]]
                },
                {
                    "text": "Test Text 2", 
                    "confidence": 0.98,
                    "bbox": [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]]
                },
                {
                    "text": "Test Text 3",
                    "confidence": 0.92,
                    "bbox": [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]]
                }
            ]
        }
        
        logger.info("🧪 Testing webhook delivery to n8n...")
        webhook_results = await webhook_service.send_ocr_result(test_data, "test_pdf.pdf")
        
        return {
            "message": "Webhook test completed",
            "test_data": test_data,
            "webhook_results": webhook_results,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Webhook test failed: {e}")
        raise HTTPException(status_code=500, detail=f"Webhook test failed: {str(e)}")

@router.get("/metrics", tags=["Monitoring"])
async def get_metrics():
    """Get service metrics (placeholder for monitoring)"""
    return {
        "timestamp": datetime.utcnow().isoformat(),
        "service": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "operational"
    }
