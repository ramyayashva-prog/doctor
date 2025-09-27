"""
Voice dictation models for conversation and transcription management
"""

from sqlalchemy import Column, String, Float, Boolean, JSON, Text, Integer, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime


class VoiceConversation:
    """Database model for storing voice conversations."""
    
    def __init__(self, db):
        self.db = db
        # Initialize collection after database connection is established
        self.collection = None
    
    def _ensure_collection(self):
        """Ensure collection is initialized"""
        if self.collection is None and self.db is not None:
            self.collection = self.db.voice_conversations
    
    def create_conversation(self, conversation_data):
        """Create a new conversation."""
        self._ensure_collection()
        if self.collection is None:
            raise Exception("Database not connected")
        conversation_data['created_at'] = datetime.utcnow()
        conversation_data['updated_at'] = datetime.utcnow()
        result = self.collection.insert_one(conversation_data)
        return str(result.inserted_id)
    
    def get_conversation(self, conversation_id):
        """Get conversation by ID."""
        self._ensure_collection()
        if self.collection is None:
            return None
        return self.collection.find_one({"_id": conversation_id})
    
    def get_conversations_by_patient(self, patient_id):
        """Get all conversations for a patient."""
        self._ensure_collection()
        if self.collection is None:
            return []
        return list(self.collection.find({"patient_id": patient_id}))
    
    def update_conversation(self, conversation_id, update_data):
        """Update conversation."""
        self._ensure_collection()
        if self.collection is None:
            return False
        update_data['updated_at'] = datetime.utcnow()
        result = self.collection.update_one(
            {"_id": conversation_id},
            {"$set": update_data}
        )
        return result.modified_count > 0
    
    def delete_conversation(self, conversation_id):
        """Delete conversation."""
        self._ensure_collection()
        if self.collection is None:
            return False
        result = self.collection.delete_one({"_id": conversation_id})
        return result.deleted_count > 0


class VoiceTranscription:
    """Database model for storing voice transcriptions."""
    
    def __init__(self, db):
        self.db = db
        # Initialize collection after database connection is established
        self.collection = None
    
    def _ensure_collection(self):
        """Ensure collection is initialized"""
        if self.collection is None and self.db is not None:
            self.collection = self.db.voice_transcriptions
    
    def create_transcription(self, transcription_data):
        """Create a new transcription."""
        self._ensure_collection()
        if self.collection is None:
            raise Exception("Database not connected")
        transcription_data['created_at'] = datetime.utcnow()
        transcription_data['updated_at'] = datetime.utcnow()
        result = self.collection.insert_one(transcription_data)
        return str(result.inserted_id)
    
    def get_transcription(self, transcription_id):
        """Get transcription by ID."""
        self._ensure_collection()
        if self.collection is None:
            return None
        return self.collection.find_one({"_id": transcription_id})
    
    def get_transcriptions_by_conversation(self, conversation_id):
        """Get all transcriptions for a conversation."""
        self._ensure_collection()
        if self.collection is None:
            return []
        return list(self.collection.find({"conversation_id": conversation_id}))
    
    def get_final_transcriptions(self, conversation_id):
        """Get only final transcriptions for a conversation."""
        self._ensure_collection()
        if self.collection is None:
            return []
        return list(self.collection.find({
            "conversation_id": conversation_id,
            "is_final": True
        }))
    
    def update_transcription(self, transcription_id, update_data):
        """Update transcription."""
        self._ensure_collection()
        if self.collection is None:
            return False
        update_data['updated_at'] = datetime.utcnow()
        result = self.collection.update_one(
            {"_id": transcription_id},
            {"$set": update_data}
        )
        return result.modified_count > 0
    
    def delete_transcription(self, transcription_id):
        """Delete transcription."""
        self._ensure_collection()
        if self.collection is None:
            return False
        result = self.collection.delete_one({"_id": transcription_id})
        return result.deleted_count > 0
    
    def delete_transcriptions_by_conversation(self, conversation_id):
        """Delete all transcriptions for a conversation."""
        self._ensure_collection()
        if self.collection is None:
            return 0
        result = self.collection.delete_many({"conversation_id": conversation_id})
        return result.deleted_count
