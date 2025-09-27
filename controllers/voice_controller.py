"""
Voice dictation controller for conversation and transcription management
"""

from typing import Any, Dict, List, Optional, Tuple
from models.voice_models import VoiceConversation, VoiceTranscription
from models.database import Database
from bson import ObjectId
import base64
import json
import logging

logger = logging.getLogger(__name__)


class VoiceController:
    """Controller for voice dictation operations."""
    
    def __init__(self):
        self.db = Database()
        # Connect to database first
        if not self.db.connect():
            raise Exception("Failed to connect to database")
        self.conversation_model = VoiceConversation(self.db.db)
        self.transcription_model = VoiceTranscription(self.db.db)
    
    # Conversation Methods
    def create_conversation(self, request, conversation_data: Dict[str, Any]) -> Tuple[Dict[str, Any], int]:
        """Create a new voice conversation."""
        try:
            # Add patient_id if not provided
            if 'patient_id' not in conversation_data:
                conversation_data['patient_id'] = request.get('patient_id', 'unknown')
            
            # Set default values
            conversation_data.setdefault('title', 'Voice Conversation')
            conversation_data.setdefault('language', 'en')
            conversation_data.setdefault('is_active', True)
            conversation_data.setdefault('duration_seconds', 0.0)
            
            conversation_id = self.conversation_model.create_conversation(conversation_data)
            
            # Create a clean response without ObjectId values
            response_data = {
                "message": "Conversation created successfully",
                "conversation_id": str(conversation_id),
                "conversation": {
                    "patient_id": conversation_data.get("patient_id"),
                    "title": conversation_data.get("title"),
                    "language": conversation_data.get("language"),
                    "is_active": conversation_data.get("is_active"),
                    "duration_seconds": conversation_data.get("duration_seconds")
                }
            }
            
            return response_data, 200
            
        except Exception as e:
            logger.error(f"Error creating conversation: {str(e)}")
            return {"error": "Failed to create conversation"}, 500
    
    def get_conversation(self, request, conversation_id: str) -> Tuple[Dict[str, Any], int]:
        """Get conversation by ID."""
        try:
            # Convert string to ObjectId
            try:
                conversation_id = ObjectId(conversation_id)
            except:
                return {"error": "Invalid conversation ID format"}, 400
            
            conversation = self.conversation_model.get_conversation(conversation_id)
            if not conversation:
                return {"error": "Conversation not found"}, 404
            
            # Convert ObjectId to string
            conversation['_id'] = str(conversation['_id'])
            
            return {
                "message": "Conversation retrieved successfully",
                "conversation": conversation
            }, 200
            
        except Exception as e:
            logger.error(f"Error getting conversation: {str(e)}")
            return {"error": "Failed to get conversation"}, 500
    
    def get_patient_conversations(self, request, patient_id: str) -> Tuple[Dict[str, Any], int]:
        """Get all conversations for a patient."""
        try:
            conversations = self.conversation_model.get_conversations_by_patient(patient_id)
            
            # Convert ObjectIds to strings
            for conv in conversations:
                conv['_id'] = str(conv['_id'])
            
            return {
                "message": "Patient conversations retrieved successfully",
                "conversations": conversations,
                "count": len(conversations)
            }, 200
            
        except Exception as e:
            logger.error(f"Error getting patient conversations: {str(e)}")
            return {"error": "Failed to get patient conversations"}, 500
    
    def update_conversation(self, request, conversation_id: str, update_data: Dict[str, Any]) -> Tuple[Dict[str, Any], int]:
        """Update conversation."""
        try:
            success = self.conversation_model.update_conversation(conversation_id, update_data)
            if not success:
                return {"error": "Conversation not found"}, 404
            
            return {
                "message": "Conversation updated successfully",
                "conversation_id": conversation_id
            }, 200
            
        except Exception as e:
            logger.error(f"Error updating conversation: {str(e)}")
            return {"error": "Failed to update conversation"}, 500
    
    def delete_conversation(self, request, conversation_id: str) -> Tuple[Dict[str, Any], int]:
        """Delete conversation and all its transcriptions."""
        try:
            # Delete all transcriptions first
            deleted_transcriptions = self.transcription_model.delete_transcriptions_by_conversation(conversation_id)
            
            # Delete conversation
            success = self.conversation_model.delete_conversation(conversation_id)
            if not success:
                return {"error": "Conversation not found"}, 404
            
            return {
                "message": "Conversation deleted successfully",
                "deleted_transcriptions": deleted_transcriptions
            }, 200
            
        except Exception as e:
            logger.error(f"Error deleting conversation: {str(e)}")
            return {"error": "Failed to delete conversation"}, 500
    
    # Transcription Methods
    def create_transcription(self, request, transcription_data: Dict[str, Any]) -> Tuple[Dict[str, Any], int]:
        """Create a new transcription."""
        try:
            # Validate required fields
            required_fields = ['conversation_id', 'text', 'start_time', 'end_time']
            for field in required_fields:
                if field not in transcription_data:
                    return {"error": f"Missing required field: {field}"}, 400
            
            # Set default values
            transcription_data.setdefault('language', 'en')
            transcription_data.setdefault('is_final', False)
            transcription_data.setdefault('confidence', 0.0)
            
            transcription_id = self.transcription_model.create_transcription(transcription_data)
            
            # Create a clean response without ObjectId values
            response_data = {
                "message": "Transcription created successfully",
                "transcription_id": str(transcription_id),
                "transcription": {
                    "conversation_id": transcription_data.get("conversation_id"),
                    "text": transcription_data.get("text"),
                    "start_time": transcription_data.get("start_time"),
                    "end_time": transcription_data.get("end_time"),
                    "confidence": transcription_data.get("confidence"),
                    "is_final": transcription_data.get("is_final"),
                    "language": transcription_data.get("language")
                }
            }
            
            return response_data, 200
            
        except Exception as e:
            logger.error(f"Error creating transcription: {str(e)}")
            return {"error": "Failed to create transcription"}, 500
    
    def get_transcription(self, request, transcription_id: str) -> Tuple[Dict[str, Any], int]:
        """Get transcription by ID."""
        try:
            transcription = self.transcription_model.get_transcription(transcription_id)
            if not transcription:
                return {"error": "Transcription not found"}, 404
            
            # Convert ObjectId to string
            transcription['_id'] = str(transcription['_id'])
            
            return {
                "message": "Transcription retrieved successfully",
                "transcription": transcription
            }, 200
            
        except Exception as e:
            logger.error(f"Error getting transcription: {str(e)}")
            return {"error": "Failed to get transcription"}, 500
    
    def get_conversation_transcriptions(self, request, conversation_id: str) -> Tuple[Dict[str, Any], int]:
        """Get all transcriptions for a conversation."""
        try:
            transcriptions = self.transcription_model.get_transcriptions_by_conversation(conversation_id)
            
            # Convert ObjectIds to strings
            for trans in transcriptions:
                trans['_id'] = str(trans['_id'])
            
            return {
                "message": "Conversation transcriptions retrieved successfully",
                "transcriptions": transcriptions,
                "count": len(transcriptions)
            }, 200
            
        except Exception as e:
            logger.error(f"Error getting conversation transcriptions: {str(e)}")
            return {"error": "Failed to get conversation transcriptions"}, 500
    
    def get_final_transcriptions(self, request, conversation_id: str) -> Tuple[Dict[str, Any], int]:
        """Get only final transcriptions for a conversation."""
        try:
            transcriptions = self.transcription_model.get_final_transcriptions(conversation_id)
            
            # Convert ObjectIds to strings
            for trans in transcriptions:
                trans['_id'] = str(trans['_id'])
            
            return {
                "message": "Final transcriptions retrieved successfully",
                "transcriptions": transcriptions,
                "count": len(transcriptions)
            }, 200
            
        except Exception as e:
            logger.error(f"Error getting final transcriptions: {str(e)}")
            return {"error": "Failed to get final transcriptions"}, 500
    
    def update_transcription(self, request, transcription_id: str, update_data: Dict[str, Any]) -> Tuple[Dict[str, Any], int]:
        """Update transcription."""
        try:
            success = self.transcription_model.update_transcription(transcription_id, update_data)
            if not success:
                return {"error": "Transcription not found"}, 404
            
            return {
                "message": "Transcription updated successfully",
                "transcription_id": transcription_id
            }, 200
            
        except Exception as e:
            logger.error(f"Error updating transcription: {str(e)}")
            return {"error": "Failed to update transcription"}, 500
    
    def delete_transcription(self, request, transcription_id: str) -> Tuple[Dict[str, Any], int]:
        """Delete transcription."""
        try:
            success = self.transcription_model.delete_transcription(transcription_id)
            if not success:
                return {"error": "Transcription not found"}, 404
            
            return {
                "message": "Transcription deleted successfully",
                "transcription_id": transcription_id
            }, 200
            
        except Exception as e:
            logger.error(f"Error deleting transcription: {str(e)}")
            return {"error": "Failed to delete transcription"}, 500
    
    def process_audio_chunk(self, request, audio_data: str, conversation_id: str, chunk_index: int) -> Tuple[Dict[str, Any], int]:
        """Process audio chunk and return transcription."""
        try:
            # Decode base64 audio data
            try:
                audio_bytes = base64.b64decode(audio_data)
            except Exception as e:
                return {"error": "Invalid base64 audio data"}, 400
            
            # For now, return a mock transcription
            # In a real implementation, you would process the audio here
            transcription_data = {
                "conversation_id": conversation_id,
                "text": f"Audio chunk {chunk_index} processed",
                "start_time": chunk_index * 5.0,  # 5 seconds per chunk
                "end_time": (chunk_index + 1) * 5.0,
                "confidence": 0.85,
                "is_final": True,
                "language": "en",
                "extra_data": {
                    "chunk_index": chunk_index,
                    "audio_size": len(audio_bytes)
                }
            }
            
            transcription_id = self.transcription_model.create_transcription(transcription_data)
            
            # Create a clean response without ObjectId values
            response_data = {
                "message": "Audio chunk processed successfully",
                "transcription_id": str(transcription_id),
                "transcription": {
                    "conversation_id": transcription_data.get("conversation_id"),
                    "text": transcription_data.get("text"),
                    "start_time": transcription_data.get("start_time"),
                    "end_time": transcription_data.get("end_time"),
                    "confidence": transcription_data.get("confidence"),
                    "is_final": transcription_data.get("is_final"),
                    "language": transcription_data.get("language"),
                    "extra_data": transcription_data.get("extra_data")
                }
            }
            
            return response_data, 200
            
        except Exception as e:
            logger.error(f"Error processing audio chunk: {str(e)}")
            return {"error": "Failed to process audio chunk"}, 500
