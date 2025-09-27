import logging
import asyncio
import aiohttp
from typing import Dict, Any, Optional, List
from datetime import datetime
from app.services.webhook_config_service import WebhookConfigService

logger = logging.getLogger(__name__)

class WebhookService:
    """Service for sending webhooks using dynamic configurations"""
    
    def __init__(self):
        self.config_service = WebhookConfigService()
    
    async def send_ocr_result(self, ocr_data: Dict[str, Any], filename: Optional[str] = None) -> List[Dict[str, Any]]:
        """Send OCR results to all active webhook configurations"""
        active_configs = self.config_service.get_active_configs()
        
        logger.info(f"🔍 Webhook service: Found {len(active_configs)} active webhook configurations")
        
        if not active_configs:
            logger.warning("❌ No active webhook configurations found")
            # Log all configurations for debugging
            all_configs = self.config_service.get_all_configs()
            logger.info(f"📋 Total configurations available: {len(all_configs)}")
            for config in all_configs:
                logger.info(f"  - {config.name}: {config.url} (enabled: {config.enabled})")
            return []
        
        results = []
        
        for config in active_configs:
            logger.info(f"🚀 Sending webhook to: {config.name} ({config.url})")
            try:
                success = await self._send_webhook_with_config(config, ocr_data, filename)
                results.append({
                    "config_id": config.id,
                    "config_name": config.name,
                    "url": config.url,
                    "success": success,
                    "timestamp": datetime.utcnow().isoformat()
                })
                
                if success:
                    logger.info(f"✅ Webhook sent successfully to {config.name} ({config.url})")
                else:
                    logger.warning(f"❌ Failed to send webhook to {config.name}")
                    
            except Exception as e:
                logger.error(f"💥 Error sending webhook to {config.name}: {e}")
                results.append({
                    "config_id": config.id,
                    "config_name": config.name,
                    "url": config.url,
                    "success": False,
                    "error": str(e),
                    "timestamp": datetime.utcnow().isoformat()
                })
        
        return results
    
    async def _send_webhook_with_config(self, config: Any, ocr_data: Dict[str, Any], filename: Optional[str] = None) -> bool:
        """Send webhook using specific configuration"""
        if not config.enabled or not config.url:
            return False
        
        # Prepare webhook payload
        payload = self._prepare_payload(config, ocr_data, filename)
        
        # Send webhook with retry logic
        for attempt in range(config.retry_attempts):
            try:
                success = await self._send_webhook_request(config, payload)
                if success:
                    return True
                else:
                    logger.warning(f"Webhook attempt {attempt + 1} failed for {config.name}")
            except Exception as e:
                logger.error(f"Webhook attempt {attempt + 1} error for {config.name}: {e}")
            
            # Wait before retry (exponential backoff)
            if attempt < config.retry_attempts - 1:
                wait_time = config.retry_delay * (2 ** attempt)
                logger.info(f"Waiting {wait_time} seconds before retry for {config.name}...")
                await asyncio.sleep(wait_time)
        
        logger.error(f"Failed to send webhook to {config.name} after {config.retry_attempts} attempts")
        return False
    
    def _prepare_payload(self, config: Any, ocr_data: Dict[str, Any], filename: Optional[str] = None) -> Dict[str, Any]:
        """Prepare webhook payload based on configuration template"""
        
        # Create full text content field by combining all extracted text
        full_text_content = ""
        if ocr_data.get("success") and ocr_data.get("results"):
            # Extract all text from results and combine them
            extracted_texts = []
            for result in ocr_data["results"]:
                text = result.get("text", "").strip()
                if text:  # Only add non-empty text
                    extracted_texts.append(text)
            
            # Combine all extracted text into one continuous string
            full_text_content = ' '.join(extracted_texts)
            
            # If no content from results, try alternative fields
            if not full_text_content:
                full_text_content = ocr_data.get('full_text_content', '')
            
            if not full_text_content:
                full_text_content = ocr_data.get('extracted_text', '')
            
            if not full_text_content:
                full_text_content = ocr_data.get('text', '')
        
        # Start with default payload
        default_payload = {
            "timestamp": datetime.utcnow().isoformat(),
            "source": "paddleocr-microservice",
            "filename": filename,
            "ocr_result": ocr_data,
            "full_text_content": full_text_content.strip(),  # Add the combined text field
            "metadata": {
                "text_count": ocr_data.get("text_count", 0),
                "config_name": config.name
            }
        }
        
        # Apply custom payload template if configured
        if config.payload_template:
            # Merge custom template with default payload
            # Custom template can override or add fields
            payload = default_payload.copy()
            payload.update(config.payload_template)
            
            # Replace placeholders in custom template
            payload = self._replace_placeholders(payload, ocr_data, filename, config)
        else:
            payload = default_payload
        
        return payload
    
    def _replace_placeholders(self, payload: Dict[str, Any], ocr_data: Dict[str, Any], filename: Optional[str], config: Any) -> Dict[str, Any]:
        """Replace placeholders in payload template with actual values"""
        import json
        
        # Convert to string for replacement
        payload_str = json.dumps(payload)
        
        # Replace common placeholders
        replacements = {
            "{{filename}}": filename or "unknown",
            "{{text_count}}": str(ocr_data.get("text_count", 0)),
            "{{config_name}}": config.name,
            "{{timestamp}}": datetime.utcnow().isoformat(),
            "{{ocr_data}}": json.dumps(ocr_data),
            "{{full_text_content}}": self._get_full_text_content(ocr_data)
        }
        
        for placeholder, value in replacements.items():
            payload_str = payload_str.replace(placeholder, value)
        
        # Convert back to dict
        try:
            return json.loads(payload_str)
        except:
            return payload
    
    def _get_full_text_content(self, ocr_data: Dict[str, Any]) -> str:
        """Get full text content as a single string"""
        full_text_content = ""
        if ocr_data.get("success") and ocr_data.get("results"):
            # Extract all text from results and combine them
            extracted_texts = []
            for result in ocr_data["results"]:
                text = result.get("text", "").strip()
                if text:  # Only add non-empty text
                    extracted_texts.append(text)
            
            # Combine all extracted text into one continuous string
            full_text_content = ' '.join(extracted_texts)
        
        # If no content from results, try alternative fields
        if not full_text_content:
            full_text_content = ocr_data.get('full_text_content', '')
        
        if not full_text_content:
            full_text_content = ocr_data.get('extracted_text', '')
        
        if not full_text_content:
            full_text_content = ocr_data.get('text', '')
        
        return full_text_content.strip()
    
    async def _send_webhook_request(self, config: Any, payload: Dict[str, Any]) -> bool:
        """Send webhook request with configuration settings"""
        try:
            timeout = aiohttp.ClientTimeout(total=config.timeout)
            async with aiohttp.ClientSession(timeout=timeout) as session:
                # Prepare headers
                headers = config.headers.copy()
                if "Content-Type" not in headers:
                    headers["Content-Type"] = "application/json"
                
                # Send request
                async with session.request(
                    method=config.method,
                    url=config.url,
                    json=payload,
                    headers=headers
                ) as response:
                    if response.status in [200, 201, 202]:
                        logger.info(f"Webhook sent successfully to {config.name}. Status: {response.status}")
                        return True
                    else:
                        logger.error(f"Webhook failed for {config.name} with status: {response.status}")
                        return False
                        
        except asyncio.TimeoutError:
            logger.error(f"Webhook timeout for {config.name} after {config.timeout} seconds")
            return False
        except Exception as e:
            logger.error(f"Webhook error for {config.name}: {e}")
            return False
    
    def get_webhook_status(self) -> Dict[str, Any]:
        """Get webhook service status"""
        summary = self.config_service.get_config_summary()
        active_configs = self.config_service.get_active_configs()
        
        return {
            "enabled": summary["active_configurations"] > 0,
            "total_configurations": summary["total_configurations"],
            "active_configurations": summary["active_configurations"],
            "disabled_configurations": summary["disabled_configurations"],
            "last_updated": summary["last_updated"],
            "active_urls": [config.url for config in active_configs if config.url]
        }
    
    def is_configured(self) -> bool:
        """Check if any webhook is properly configured"""
        active_configs = self.config_service.get_active_configs()
        return any(config.enabled and config.url for config in active_configs)
