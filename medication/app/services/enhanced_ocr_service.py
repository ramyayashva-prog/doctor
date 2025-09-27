import logging
import os
import fitz  # PyMuPDF
import PyPDF2
from PIL import Image
import io
import base64
from typing import Dict, Any, List, Optional, Tuple
from app.config import settings

logger = logging.getLogger(__name__)

class EnhancedOCRService:
    """Enhanced OCR service that can process PDFs, TXTs, and images"""
    
    def __init__(self):
        self.supported_formats = settings.ENHANCED_FILE_EXTENSIONS
        self.allowed_types = settings.ALLOWED_ENHANCED_TYPES
    
    def get_file_type(self, filename: str) -> str:
        """Determine file type based on extension"""
        ext = os.path.splitext(filename.lower())[1]
        
        for file_type, extensions in self.supported_formats.items():
            if ext in extensions:
                return file_type
        
        return 'unknown'
    
    def validate_file_type(self, content_type: str, filename: str) -> bool:
        """Validate if file type is supported for enhanced processing"""
        # Handle missing or generic content types
        if not content_type or content_type == "":
            # Fallback to filename extension check
            file_type = self.get_file_type(filename)
            return file_type != 'unknown'
        
        # Check content type first
        if content_type in self.allowed_types:
            return True
        
        # Handle content types with parameters (e.g., "text/plain; charset=utf-8")
        base_content_type = content_type.split(';')[0].strip()
        if base_content_type in self.allowed_types:
            return True
        
        # Handle generic binary types that might be PDFs
        if content_type in ["application/octet-stream", "binary/octet-stream", "application/binary"]:
            # Check if filename suggests it's a supported type
            file_type = self.get_file_type(filename)
            return file_type != 'unknown'
        
        # Handle unknown content types by checking filename
        if content_type in ["content/unknown", "application/unknown", "unknown"]:
            file_type = self.get_file_type(filename)
            return file_type != 'unknown'
        
        # Final fallback to filename extension check
        file_type = self.get_file_type(filename)
        return file_type != 'unknown'
    
    async def process_file(self, file_content: bytes, filename: str) -> Dict[str, Any]:
        """Process any supported file type and return unified results"""
        try:
            file_type = self.get_file_type(filename)
            
            if file_type == 'pdf':
                return await self._process_pdf(file_content, filename)
            elif file_type == 'text':
                return await self._process_text_file(file_content, filename)
            elif file_type == 'image':
                return await self._process_image(file_content, filename)
            else:
                return {
                    "success": False,
                    "error": f"Unsupported file type: {filename}",
                    "supported_types": list(self.supported_formats.keys())
                }
                
        except Exception as e:
            logger.error(f"Error processing file {filename}: {e}")
            return {
                "success": False,
                "error": f"Processing error: {str(e)}",
                "filename": filename
            }
    
    async def _process_pdf(self, file_content: bytes, filename: str) -> Dict[str, Any]:
        """Process PDF file (both native text and scanned pages)"""
        try:
            # Open PDF with PyMuPDF
            pdf_document = fitz.open(stream=file_content, filetype="pdf")
            
            results = []
            total_pages = len(pdf_document)
            native_text_pages = 0
            ocr_pages = 0
            
            for page_num in range(total_pages):
                page = pdf_document[page_num]
                
                # Try to extract native text first
                page_text = page.get_text()
                
                if page_text.strip():  # Native text available
                    results.append({
                        "page": page_num + 1,
                        "text": page_text.strip(),
                        "method": "native",
                        "confidence": 1.0,
                        "bbox": [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]]  # Default bbox for native text
                    })
                    native_text_pages += 1
                else:  # No native text, need OCR
                    # Convert page to image
                    pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))  # 2x zoom for better quality
                    img_data = pix.tobytes("png")
                    
                    # Process image with OCR
                    ocr_result = await self._process_image_bytes(img_data, f"{filename}_page_{page_num + 1}")
                    
                    if ocr_result.get("success") and ocr_result.get("results"):
                        for item in ocr_result["results"]:
                                                    results.append({
                            "page": page_num + 1,
                            "text": item["text"],
                            "method": "ocr",
                            "confidence": item["confidence"],
                            "bbox": item.get("bbox", [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]])  # Use OCR bbox or default
                        })
                        ocr_pages += 1
                    else:
                        results.append({
                            "page": page_num + 1,
                            "text": "",
                            "method": "ocr_failed",
                            "confidence": 0.0,
                            "bbox": [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]]  # Default bbox for failed OCR
                        })
            
            pdf_document.close()
            
            # Combine all text
            all_text = "\n".join([item["text"] for item in results if item["text"]])
            
            return {
                "success": True,
                "filename": filename,
                "file_type": "PDF",
                "total_pages": total_pages,
                "native_text_pages": native_text_pages,
                "ocr_pages": ocr_pages,
                "text_count": len(results),
                "results": results,
                "full_content": all_text,
                "processing_summary": {
                    "total_pages": total_pages,
                    "native_text_pages": native_text_pages,
                    "ocr_pages": ocr_pages,
                    "mixed_processing": native_text_pages > 0 and ocr_pages > 0
                }
            }
            
        except Exception as e:
            logger.error(f"Error processing PDF {filename}: {e}")
            return {
                "success": False,
                "error": f"PDF processing error: {str(e)}",
                "filename": filename
            }
    
    async def _process_text_file(self, file_content: bytes, filename: str) -> Dict[str, Any]:
        """Process text files (TXT, DOC, DOCX)"""
        try:
            ext = os.path.splitext(filename.lower())[1]
            
            if ext == '.txt':
                # Simple text file
                text_content = file_content.decode('utf-8', errors='ignore')
                lines = text_content.split('\n')
                
                results = []
                for i, line in enumerate(lines):
                    if line.strip():
                        results.append({
                            "line": i + 1,
                            "text": line.strip(),
                            "method": "native",
                            "confidence": 1.0,
                            "bbox": [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]]  # Default bbox for text files
                        })
                
                return {
                    "success": True,
                    "filename": filename,
                    "file_type": "TXT",
                    "total_pages": 1,
                    "text_count": len(results),
                    "results": results,
                    "full_content": text_content,
                    "processing_summary": {
                        "total_pages": 1,
                        "native_text_pages": 1,
                        "ocr_pages": 0,
                        "mixed_processing": False
                    }
                }
            
            elif ext in ['.doc', '.docx']:
                # Word document - convert to text
                try:
                    from docx import Document
                    doc = Document(io.BytesIO(file_content))
                    
                    results = []
                    full_text = ""
                    
                    for para in doc.paragraphs:
                        if para.text.strip():
                            results.append({
                                "paragraph": len(results) + 1,
                                "text": para.text.strip(),
                                "method": "native",
                                "confidence": 1.0,
                                "bbox": [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]]  # Default bbox for Word documents
                            })
                            full_text += para.text.strip() + "\n"
                    
                    return {
                        "success": True,
                        "filename": filename,
                        "file_type": "DOCX",
                        "total_pages": 1,
                        "text_count": len(results),
                        "results": results,
                        "full_content": full_text.strip(),
                        "processing_summary": {
                            "total_pages": 1,
                            "native_text_pages": 1,
                            "ocr_pages": 0,
                            "mixed_processing": False
                        }
                    }
                    
                except Exception as e:
                    logger.error(f"Error processing Word document {filename}: {e}")
                    return {
                        "success": False,
                        "error": f"Word document processing error: {str(e)}",
                        "filename": filename
                    }
            
        except Exception as e:
            logger.error(f"Error processing text file {filename}: {e}")
            return {
                "success": False,
                "error": f"Text file processing error: {str(e)}",
                "filename": filename
            }
    
    async def _process_image(self, file_content: bytes, filename: str) -> Dict[str, Any]:
        """Process image files using direct OCR processing"""
        try:
            # Convert bytes to PIL Image
            image = Image.open(io.BytesIO(file_content))
            
            # Convert PIL image to OpenCV format for PaddleOCR
            import cv2
            import numpy as np
            
            # Convert PIL to OpenCV format
            opencv_image = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
            
            # Use PaddleOCR directly
            from paddleocr import PaddleOCR
            ocr = PaddleOCR(lang='en')
            result = ocr.ocr(opencv_image, cls=True)
            
            # Extract text from result
            extracted_text = []
            if result and result[0]:
                for line in result[0]:
                    if line and len(line) >= 2:
                        text = line[1][0]  # Extract text
                        confidence = line[1][1]  # Extract confidence score
                        bbox = line[0]  # Extract bounding box coordinates
                        
                        extracted_text.append({
                            "text": text,
                            "confidence": float(confidence),
                            "bbox": [[float(coord) for coord in bbox[0]], [float(coord) for coord in bbox[1]], 
                                    [float(coord) for coord in bbox[2]], [float(coord) for coord in bbox[3]]]
                        })
            
            # Create full content by combining all extracted text
            full_content = ""
            if extracted_text:
                text_parts = [item["text"] for item in extracted_text if item.get("text")]
                full_content = " ".join(text_parts)
            
            # Prepare response
            response_data = {
                "success": True,
                "filename": filename,
                "file_type": "IMAGE",
                "total_pages": 1,
                "text_count": len(extracted_text),
                "results": extracted_text,
                "full_content": full_content,  # Add the full text content
                "processing_summary": {
                    "total_pages": 1,
                    "native_text_pages": 0,
                    "ocr_pages": 1,
                    "mixed_processing": False
                }
            }
            
            return response_data
            
        except Exception as e:
            logger.error(f"Error processing image {filename}: {e}")
            return {
                "success": False,
                "error": f"Image processing error: {str(e)}",
                "filename": filename
            }
    
    async def _process_image_bytes(self, image_data: bytes, filename: str) -> Dict[str, Any]:
        """Process image data from PDF pages using direct OCR processing"""
        try:
            # Convert bytes to PIL Image
            image = Image.open(io.BytesIO(image_data))
            
            # Convert PIL image to OpenCV format for PaddleOCR
            import cv2
            import numpy as np
            
            # Convert PIL to OpenCV format
            opencv_image = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
            
            # Use PaddleOCR directly
            from paddleocr import PaddleOCR
            ocr = PaddleOCR(lang='en')
            result = ocr.ocr(opencv_image, cls=True)
            
            # Extract text from result
            extracted_text = []
            if result and result[0]:
                for line in result[0]:
                    if line and len(line) >= 2:
                        text = line[1][0]  # Extract text
                        confidence = line[1][1]  # Extract confidence score
                        bbox = line[0]  # Extract bounding box coordinates
                        
                        extracted_text.append({
                            "text": text,
                            "confidence": float(confidence),
                            "bbox": [[float(coord) for coord in bbox[0]], [float(coord) for coord in bbox[1]], 
                                    [float(coord) for coord in bbox[2]], [float(coord) for coord in bbox[3]]]
                        })
            
            # Create full content by combining all extracted text
            full_content = ""
            if extracted_text:
                text_parts = [item["text"] for item in extracted_text if item.get("text")]
                full_content = " ".join(text_parts)
            
            # Prepare response
            response_data = {
                "success": True,
                "filename": filename,
                "text_count": len(extracted_text),
                "results": extracted_text,
                "full_content": full_content  # Add the full text content
            }
            
            return response_data
            
        except Exception as e:
            logger.error(f"Error processing image bytes {filename}: {e}")
            return {
                "success": False,
                "error": f"Image bytes processing error: {str(e)}",
                "filename": filename
            }
    
    def get_supported_formats(self) -> Dict[str, List[str]]:
        """Get list of supported file formats"""
        return self.supported_formats
