"""
Voice dictation service for audio processing and transcription
"""

import base64
import json
import logging
from typing import Dict, Any, List, Optional
from models.voice_models import VoiceConversation, VoiceTranscription
from models.database import Database

logger = logging.getLogger(__name__)


class VoiceService:
    """Service for voice dictation operations."""
    
    def __init__(self):
        self.db = Database()
        self.conversation_model = VoiceConversation(self.db.db)
        self.transcription_model = VoiceTranscription(self.db.db)
    
    def create_conversation(self, conversation_data: Dict[str, Any]) -> str:
        """Create a new conversation."""
        try:
            conversation_id = self.conversation_model.create_conversation(conversation_data)
            logger.info(f"Created conversation: {conversation_id}")
            return conversation_id
        except Exception as e:
            logger.error(f"Error creating conversation: {str(e)}")
            raise
    
    def get_conversation(self, conversation_id: str) -> Optional[Dict[str, Any]]:
        """Get conversation by ID."""
        try:
            conversation = self.conversation_model.get_conversation(conversation_id)
            if conversation:
                conversation['_id'] = str(conversation['_id'])
            return conversation
        except Exception as e:
            logger.error(f"Error getting conversation {conversation_id}: {str(e)}")
            return None
    
    def get_patient_conversations(self, patient_id: str) -> List[Dict[str, Any]]:
        """Get all conversations for a patient."""
        try:
            conversations = self.conversation_model.get_conversations_by_patient(patient_id)
            for conv in conversations:
                conv['_id'] = str(conv['_id'])
            return conversations
        except Exception as e:
            logger.error(f"Error getting patient conversations: {str(e)}")
            return []
    
    def update_conversation(self, conversation_id: str, update_data: Dict[str, Any]) -> bool:
        """Update conversation."""
        try:
            success = self.conversation_model.update_conversation(conversation_id, update_data)
            if success:
                logger.info(f"Updated conversation: {conversation_id}")
            return success
        except Exception as e:
            logger.error(f"Error updating conversation {conversation_id}: {str(e)}")
            return False
    
    def delete_conversation(self, conversation_id: str) -> bool:
        """Delete conversation and all its transcriptions."""
        try:
            # Delete all transcriptions first
            self.transcription_model.delete_transcriptions_by_conversation(conversation_id)
            
            # Delete conversation
            success = self.conversation_model.delete_conversation(conversation_id)
            if success:
                logger.info(f"Deleted conversation: {conversation_id}")
            return success
        except Exception as e:
            logger.error(f"Error deleting conversation {conversation_id}: {str(e)}")
            return False
    
    def create_transcription(self, transcription_data: Dict[str, Any]) -> str:
        """Create a new transcription."""
        try:
            transcription_id = self.transcription_model.create_transcription(transcription_data)
            logger.info(f"Created transcription: {transcription_id}")
            return transcription_id
        except Exception as e:
            logger.error(f"Error creating transcription: {str(e)}")
            raise
    
    def get_transcription(self, transcription_id: str) -> Optional[Dict[str, Any]]:
        """Get transcription by ID."""
        try:
            transcription = self.transcription_model.get_transcription(transcription_id)
            if transcription:
                transcription['_id'] = str(transcription['_id'])
            return transcription
        except Exception as e:
            logger.error(f"Error getting transcription {transcription_id}: {str(e)}")
            return None
    
    def get_conversation_transcriptions(self, conversation_id: str) -> List[Dict[str, Any]]:
        """Get all transcriptions for a conversation."""
        try:
            transcriptions = self.transcription_model.get_transcriptions_by_conversation(conversation_id)
            for trans in transcriptions:
                trans['_id'] = str(trans['_id'])
            return transcriptions
        except Exception as e:
            logger.error(f"Error getting conversation transcriptions: {str(e)}")
            return []
    
    def get_final_transcriptions(self, conversation_id: str) -> List[Dict[str, Any]]:
        """Get only final transcriptions for a conversation."""
        try:
            transcriptions = self.transcription_model.get_final_transcriptions(conversation_id)
            for trans in transcriptions:
                trans['_id'] = str(trans['_id'])
            return transcriptions
        except Exception as e:
            logger.error(f"Error getting final transcriptions: {str(e)}")
            return []
    
    def update_transcription(self, transcription_id: str, update_data: Dict[str, Any]) -> bool:
        """Update transcription."""
        try:
            success = self.transcription_model.update_transcription(transcription_id, update_data)
            if success:
                logger.info(f"Updated transcription: {transcription_id}")
            return success
        except Exception as e:
            logger.error(f"Error updating transcription {transcription_id}: {str(e)}")
            return False
    
    def delete_transcription(self, transcription_id: str) -> bool:
        """Delete transcription."""
        try:
            success = self.transcription_model.delete_transcription(transcription_id)
            if success:
                logger.info(f"Deleted transcription: {transcription_id}")
            return success
        except Exception as e:
            logger.error(f"Error deleting transcription {transcription_id}: {str(e)}")
            return False
    
    def process_audio_chunk(self, audio_data: str, conversation_id: str, chunk_index: int) -> Optional[Dict[str, Any]]:
        """Process audio chunk and return transcription."""
        try:
            # Decode base64 audio data
            try:
                audio_bytes = base64.b64decode(audio_data)
            except Exception as e:
                logger.error(f"Error decoding audio data: {str(e)}")
                return None
            
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
            
            transcription_id = self.create_transcription(transcription_data)
            transcription_data['_id'] = transcription_id
            
            logger.info(f"Processed audio chunk {chunk_index} for conversation {conversation_id}")
            return transcription_data
            
        except Exception as e:
            logger.error(f"Error processing audio chunk: {str(e)}")
            return None
    
    def get_conversation_summary(self, conversation_id: str) -> Dict[str, Any]:
        """Get conversation summary with statistics and text summary."""
        try:
            conversation = self.get_conversation(conversation_id)
            if not conversation:
                return {"error": "Conversation not found"}
            
            transcriptions = self.get_conversation_transcriptions(conversation_id)
            final_transcriptions = self.get_final_transcriptions(conversation_id)
            
            # Calculate statistics
            total_duration = max([t.get('end_time', 0) for t in transcriptions], default=0)
            total_words = sum([len(t.get('text', '').split()) for t in final_transcriptions])
            avg_confidence = sum([t.get('confidence', 0) for t in final_transcriptions]) / len(final_transcriptions) if final_transcriptions else 0
            
            # Generate text summary
            text_summary = self._generate_text_summary(final_transcriptions)
            
            return {
                "conversation": conversation,
                "statistics": {
                    "total_transcriptions": len(transcriptions),
                    "final_transcriptions": len(final_transcriptions),
                    "total_duration_seconds": total_duration,
                    "total_words": total_words,
                    "average_confidence": round(avg_confidence, 2)
                },
                "text_summary": text_summary,
                "transcriptions": final_transcriptions
            }
            
        except Exception as e:
            logger.error(f"Error getting conversation summary: {str(e)}")
            return {"error": "Failed to get conversation summary"}
    
    def _generate_text_summary(self, transcriptions: List[Dict[str, Any]]) -> str:
        """Generate a text summary from transcriptions."""
        try:
            if not transcriptions:
                return "No transcriptions available for summary."
            
            # Combine all transcription texts
            all_texts = [t.get('text', '') for t in transcriptions if t.get('text', '').strip()]
            
            if not all_texts:
                return "No text content found in transcriptions."
            
            # Join all texts
            full_text = ' '.join(all_texts)
            
            # Generate a simple summary
            word_count = len(full_text.split())
            
            if word_count < 10:
                return f"Brief conversation with {word_count} words: \"{full_text}\""
            elif word_count < 50:
                return f"Short conversation ({word_count} words): \"{full_text}\""
            else:
                # For longer conversations, create a more structured summary
                sentences = [s.strip() for s in full_text.split('.') if s.strip()]
                if len(sentences) > 3:
                    summary = f"Conversation summary ({word_count} words):\n"
                    summary += f"• Key points: {'. '.join(sentences[:3])}...\n"
                    summary += f"• Total duration: {max([t.get('end_time', 0) for t in transcriptions], default=0):.1f} seconds\n"
                    summary += f"• Confidence: {sum([t.get('confidence', 0) for t in transcriptions]) / len(transcriptions):.2f}"
                else:
                    summary = f"Conversation ({word_count} words): \"{full_text}\""
                
                return summary
                
        except Exception as e:
            logger.error(f"Error generating text summary: {str(e)}")
            return "Error generating summary."

        except Exception as e:
            logger.error(f"Error getting conversation summary: {str(e)}")
            return {"error": "Failed to get conversation summary"}
    
    def _generate_text_summary(self, transcriptions: List[Dict[str, Any]]) -> str:
        """Generate a text summary from transcriptions."""
        try:
            if not transcriptions:
                return "No transcriptions available for summary."
            
            # Combine all transcription texts
            all_texts = [t.get('text', '') for t in transcriptions if t.get('text', '').strip()]
            
            if not all_texts:
                return "No text content found in transcriptions."
            
            # Join all texts
            full_text = ' '.join(all_texts)
            
            # Generate a simple summary
            word_count = len(full_text.split())
            
            if word_count < 10:
                return f"Brief conversation with {word_count} words: \"{full_text}\""
            elif word_count < 50:
                return f"Short conversation ({word_count} words): \"{full_text}\""
            else:
                # For longer conversations, create a more structured summary
                sentences = [s.strip() for s in full_text.split('.') if s.strip()]
                if len(sentences) > 3:
                    summary = f"Conversation summary ({word_count} words):\n"
                    summary += f"• Key points: {'. '.join(sentences[:3])}...\n"
                    summary += f"• Total duration: {max([t.get('end_time', 0) for t in transcriptions], default=0):.1f} seconds\n"
                    summary += f"• Confidence: {sum([t.get('confidence', 0) for t in transcriptions]) / len(transcriptions):.2f}"
                else:
                    summary = f"Conversation ({word_count} words): \"{full_text}\""
                
                return summary
                
        except Exception as e:
            logger.error(f"Error generating text summary: {str(e)}")
            return "Error generating summary."

        except Exception as e:
            logger.error(f"Error getting conversation summary: {str(e)}")
            return {"error": "Failed to get conversation summary"}
    
    def _generate_text_summary(self, transcriptions: List[Dict[str, Any]]) -> str:
        """Generate a text summary from transcriptions."""
        try:
            if not transcriptions:
                return "No transcriptions available for summary."
            
            # Combine all transcription texts
            all_texts = [t.get('text', '') for t in transcriptions if t.get('text', '').strip()]
            
            if not all_texts:
                return "No text content found in transcriptions."
            
            # Join all texts
            full_text = ' '.join(all_texts)
            
            # Generate a simple summary
            word_count = len(full_text.split())
            
            if word_count < 10:
                return f"Brief conversation with {word_count} words: \"{full_text}\""
            elif word_count < 50:
                return f"Short conversation ({word_count} words): \"{full_text}\""
            else:
                # For longer conversations, create a more structured summary
                sentences = [s.strip() for s in full_text.split('.') if s.strip()]
                if len(sentences) > 3:
                    summary = f"Conversation summary ({word_count} words):\n"
                    summary += f"• Key points: {'. '.join(sentences[:3])}...\n"
                    summary += f"• Total duration: {max([t.get('end_time', 0) for t in transcriptions], default=0):.1f} seconds\n"
                    summary += f"• Confidence: {sum([t.get('confidence', 0) for t in transcriptions]) / len(transcriptions):.2f}"
                else:
                    summary = f"Conversation ({word_count} words): \"{full_text}\""
                
                return summary
                
        except Exception as e:
            logger.error(f"Error generating text summary: {str(e)}")
            return "Error generating summary."
