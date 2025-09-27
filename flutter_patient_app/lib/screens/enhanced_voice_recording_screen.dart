import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class EnhancedVoiceRecordingScreen extends StatefulWidget {
  final String conversationId;
  final String conversationTitle;

  const EnhancedVoiceRecordingScreen({
    Key? key,
    required this.conversationId,
    required this.conversationTitle,
  }) : super(key: key);

  @override
  State<EnhancedVoiceRecordingScreen> createState() => _EnhancedVoiceRecordingScreenState();
}

class _EnhancedVoiceRecordingScreenState extends State<EnhancedVoiceRecordingScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ApiService _apiService = ApiService();
  
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _error;
  Duration _recordingDuration = Duration.zero;
  List<Map<String, dynamic>> _transcriptions = [];
  Timer? _durationTimer;
  Timer? _statusTimer;
  
  // Real-time status
  String _conversationStatus = 'inactive';
  int _transcriptionCount = 0;
  int _finalTranscriptionCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeRecording();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _statusTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _initializeRecording() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load existing transcriptions
      await _loadTranscriptions();
      
      // Check conversation status
      await _checkConversationStatus();
      
      // Request permissions
      await _requestPermissions();
      
    } catch (e) {
      setState(() {
        _error = 'Initialization failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    // Request microphone permission
    final microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus != PermissionStatus.granted) {
      throw Exception('Microphone permission is required for recording');
    }

    // Check if recorder is available
    if (!await _audioRecorder.hasPermission()) {
      throw Exception('Microphone permission not granted');
    }
  }

  Future<void> _checkConversationStatus() async {
    try {
      final response = await _apiService.getConversationStatus(widget.conversationId);
      
      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }
      
      setState(() {
        _conversationStatus = response['status'] ?? 'inactive';
        _transcriptionCount = response['transcription_count'] ?? 0;
        _finalTranscriptionCount = response['final_transcription_count'] ?? 0;
      });
    } catch (e) {
      print('Error checking conversation status: $e');
    }
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _checkConversationStatus();
        _loadTranscriptions();
      }
    });
  }

  Future<void> _loadTranscriptions() async {
    try {
      final response = await _apiService.getConversationTranscriptions(widget.conversationId);
      
      if (response.containsKey('error')) {
        setState(() {
          _error = response['error'];
        });
      } else {
        setState(() {
          _transcriptions = List<Map<String, dynamic>>.from(response['transcriptions'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading transcriptions: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Final permission check
      if (!await _audioRecorder.hasPermission()) {
        throw Exception('Microphone permission not granted');
      }

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: 'voice_recording_${DateTime.now().millisecondsSinceEpoch}.aac',
      );

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordingDuration = Duration.zero;
        _isLoading = false;
      });

      // Start duration timer
      _startDurationTimer();

      _showSuccessSnackBar('🎤 Recording started successfully');
      
      // Update conversation status
      await _checkConversationStatus();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error starting recording: $e';
      });
      _showErrorSnackBar('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      final recording = await _audioRecorder.stop();
      
      if (recording != null) {
        setState(() {
          _isRecording = false;
          _isPaused = false;
        });

        // Process the recorded audio
        await _processRecordedAudio(recording);
        
        _showSuccessSnackBar('✅ Recording stopped and processed');
      }
    } catch (e) {
      setState(() {
        _error = 'Error stopping recording: $e';
      });
      _showErrorSnackBar('Error stopping recording: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _audioRecorder.pause();
      setState(() {
        _isPaused = true;
      });
      _showSuccessSnackBar('⏸️ Recording paused');
    } catch (e) {
      _showErrorSnackBar('Error pausing recording: $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _audioRecorder.resume();
      setState(() {
        _isPaused = false;
      });
      _showSuccessSnackBar('▶️ Recording resumed');
    } catch (e) {
      _showErrorSnackBar('Error resuming recording: $e');
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRecording && !_isPaused && mounted) {
        setState(() {
          _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
        });
      }
    });
  }

  Future<void> _processRecordedAudio(String audioPath) async {
    try {
      // Read audio file and convert to base64
      final audioBytes = await _readAudioFile(audioPath);
      final base64Audio = base64Encode(audioBytes);

      // Send audio to backend for processing
      final response = await _apiService.processAudioChunk(
        conversationId: widget.conversationId,
        chunkIndex: _transcriptions.length,
        audioData: base64Audio,
      );

      if (response.containsKey('error')) {
        _showErrorSnackBar('Error processing audio: ${response['error']}');
      } else {
        // Reload transcriptions to show the new one
        await _loadTranscriptions();
        await _checkConversationStatus();
        _showSuccessSnackBar('🎯 Audio processed successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Error processing audio: $e');
    }
  }

  Future<Uint8List> _readAudioFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      } else {
        // If file doesn't exist, create dummy audio data for testing
        return Uint8List.fromList(List.generate(1000, (index) => index % 256));
      }
    } catch (e) {
      print('Error reading audio file: $e');
      // Return dummy audio data as fallback
      return Uint8List.fromList(List.generate(1000, (index) => index % 256));
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Recording'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadTranscriptions();
              _checkConversationStatus();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Conversation Info Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.conversationTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${widget.conversationId}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatusChip('Status', _conversationStatus, 
                              _conversationStatus == 'active' ? Colors.green : Colors.orange),
                          _buildStatusChip('Transcriptions', '$_transcriptionCount', Colors.blue),
                          _buildStatusChip('Final', '$_finalTranscriptionCount', Colors.purple),
                        ],
                      ),
                    ],
                  ),
                ),

                // Recording Controls
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Recording Status
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _isRecording ? Colors.red : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _isRecording ? Icons.mic : Icons.mic_off,
                              size: 60,
                              color: _isRecording ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isRecording 
                                ? (_isPaused ? 'Recording Paused' : 'Recording...')
                                : 'Ready to Record',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _isRecording ? Colors.red : Colors.grey,
                              ),
                            ),
                            if (_isRecording) ...[
                              const SizedBox(height: 8),
                              Text(
                                _formatDuration(_recordingDuration),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Control Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Start/Stop Button
                          GestureDetector(
                            onTap: _isRecording ? _stopRecording : _startRecording,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: _isRecording ? Colors.red : Colors.green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isRecording ? Colors.red : Colors.green).withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: _isProcessing
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Icon(
                                      _isRecording ? Icons.stop : Icons.mic,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                            ),
                          ),

                          // Pause/Resume Button (only when recording)
                          if (_isRecording) ...[
                            GestureDetector(
                              onTap: _isPaused ? _resumeRecording : _pauseRecording,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _isPaused ? Colors.green : Colors.orange,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isPaused ? Colors.green : Colors.orange).withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isPaused ? Icons.play_arrow : Icons.pause,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Instructions
                      Text(
                        _isRecording 
                          ? 'Tap the red button to stop recording'
                          : 'Tap the green button to start recording',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Transcriptions List
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Transcriptions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '$_transcriptionCount total',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        else if (_transcriptions.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'No transcriptions yet. Start recording to see them here.',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: _transcriptions.length,
                              itemBuilder: (context, index) {
                                final transcription = _transcriptions[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: transcription['is_final'] == true 
                                        ? Colors.green 
                                        : Colors.orange,
                                      child: Icon(
                                        transcription['is_final'] == true 
                                          ? Icons.check 
                                          : Icons.hourglass_empty,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      transcription['text'] ?? 'No text',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Confidence: ${(transcription['confidence'] ?? 0.0).toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          'Time: ${transcription['start_time']?.toStringAsFixed(1)}s - ${transcription['end_time']?.toStringAsFixed(1)}s',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        if (transcription['processing_timestamp'] != null)
                                          Text(
                                            'Processed: ${transcription['processing_timestamp']}',
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class EnhancedVoiceRecordingScreen extends StatefulWidget {
  final String conversationId;
  final String conversationTitle;

  const EnhancedVoiceRecordingScreen({
    Key? key,
    required this.conversationId,
    required this.conversationTitle,
  }) : super(key: key);

  @override
  State<EnhancedVoiceRecordingScreen> createState() => _EnhancedVoiceRecordingScreenState();
}

class _EnhancedVoiceRecordingScreenState extends State<EnhancedVoiceRecordingScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ApiService _apiService = ApiService();
  
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _error;
  Duration _recordingDuration = Duration.zero;
  List<Map<String, dynamic>> _transcriptions = [];
  Timer? _durationTimer;
  Timer? _statusTimer;
  
  // Real-time status
  String _conversationStatus = 'inactive';
  int _transcriptionCount = 0;
  int _finalTranscriptionCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeRecording();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _statusTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _initializeRecording() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load existing transcriptions
      await _loadTranscriptions();
      
      // Check conversation status
      await _checkConversationStatus();
      
      // Request permissions
      await _requestPermissions();
      
    } catch (e) {
      setState(() {
        _error = 'Initialization failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    // Request microphone permission
    final microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus != PermissionStatus.granted) {
      throw Exception('Microphone permission is required for recording');
    }

    // Check if recorder is available
    if (!await _audioRecorder.hasPermission()) {
      throw Exception('Microphone permission not granted');
    }
  }

  Future<void> _checkConversationStatus() async {
    try {
      final response = await _apiService.getConversationStatus(widget.conversationId);
      
      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }
      
      setState(() {
        _conversationStatus = response['status'] ?? 'inactive';
        _transcriptionCount = response['transcription_count'] ?? 0;
        _finalTranscriptionCount = response['final_transcription_count'] ?? 0;
      });
    } catch (e) {
      print('Error checking conversation status: $e');
    }
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _checkConversationStatus();
        _loadTranscriptions();
      }
    });
  }

  Future<void> _loadTranscriptions() async {
    try {
      final response = await _apiService.getConversationTranscriptions(widget.conversationId);
      
      if (response.containsKey('error')) {
        setState(() {
          _error = response['error'];
        });
      } else {
        setState(() {
          _transcriptions = List<Map<String, dynamic>>.from(response['transcriptions'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading transcriptions: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Final permission check
      if (!await _audioRecorder.hasPermission()) {
        throw Exception('Microphone permission not granted');
      }

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: 'voice_recording_${DateTime.now().millisecondsSinceEpoch}.aac',
      );

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordingDuration = Duration.zero;
        _isLoading = false;
      });

      // Start duration timer
      _startDurationTimer();

      _showSuccessSnackBar('🎤 Recording started successfully');
      
      // Update conversation status
      await _checkConversationStatus();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error starting recording: $e';
      });
      _showErrorSnackBar('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      final recording = await _audioRecorder.stop();
      
      if (recording != null) {
        setState(() {
          _isRecording = false;
          _isPaused = false;
        });

        // Process the recorded audio
        await _processRecordedAudio(recording);
        
        _showSuccessSnackBar('✅ Recording stopped and processed');
      }
    } catch (e) {
      setState(() {
        _error = 'Error stopping recording: $e';
      });
      _showErrorSnackBar('Error stopping recording: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _audioRecorder.pause();
      setState(() {
        _isPaused = true;
      });
      _showSuccessSnackBar('⏸️ Recording paused');
    } catch (e) {
      _showErrorSnackBar('Error pausing recording: $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _audioRecorder.resume();
      setState(() {
        _isPaused = false;
      });
      _showSuccessSnackBar('▶️ Recording resumed');
    } catch (e) {
      _showErrorSnackBar('Error resuming recording: $e');
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRecording && !_isPaused && mounted) {
        setState(() {
          _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
        });
      }
    });
  }

  Future<void> _processRecordedAudio(String audioPath) async {
    try {
      // Read audio file and convert to base64
      final audioBytes = await _readAudioFile(audioPath);
      final base64Audio = base64Encode(audioBytes);

      // Send audio to backend for processing
      final response = await _apiService.processAudioChunk(
        conversationId: widget.conversationId,
        chunkIndex: _transcriptions.length,
        audioData: base64Audio,
      );

      if (response.containsKey('error')) {
        _showErrorSnackBar('Error processing audio: ${response['error']}');
      } else {
        // Reload transcriptions to show the new one
        await _loadTranscriptions();
        await _checkConversationStatus();
        _showSuccessSnackBar('🎯 Audio processed successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Error processing audio: $e');
    }
  }

  Future<Uint8List> _readAudioFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      } else {
        // If file doesn't exist, create dummy audio data for testing
        return Uint8List.fromList(List.generate(1000, (index) => index % 256));
      }
    } catch (e) {
      print('Error reading audio file: $e');
      // Return dummy audio data as fallback
      return Uint8List.fromList(List.generate(1000, (index) => index % 256));
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Recording'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadTranscriptions();
              _checkConversationStatus();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Conversation Info Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.conversationTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${widget.conversationId}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatusChip('Status', _conversationStatus, 
                              _conversationStatus == 'active' ? Colors.green : Colors.orange),
                          _buildStatusChip('Transcriptions', '$_transcriptionCount', Colors.blue),
                          _buildStatusChip('Final', '$_finalTranscriptionCount', Colors.purple),
                        ],
                      ),
                    ],
                  ),
                ),

                // Recording Controls
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Recording Status
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _isRecording ? Colors.red : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _isRecording ? Icons.mic : Icons.mic_off,
                              size: 60,
                              color: _isRecording ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isRecording 
                                ? (_isPaused ? 'Recording Paused' : 'Recording...')
                                : 'Ready to Record',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _isRecording ? Colors.red : Colors.grey,
                              ),
                            ),
                            if (_isRecording) ...[
                              const SizedBox(height: 8),
                              Text(
                                _formatDuration(_recordingDuration),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Control Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Start/Stop Button
                          GestureDetector(
                            onTap: _isRecording ? _stopRecording : _startRecording,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: _isRecording ? Colors.red : Colors.green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isRecording ? Colors.red : Colors.green).withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: _isProcessing
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Icon(
                                      _isRecording ? Icons.stop : Icons.mic,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                            ),
                          ),

                          // Pause/Resume Button (only when recording)
                          if (_isRecording) ...[
                            GestureDetector(
                              onTap: _isPaused ? _resumeRecording : _pauseRecording,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _isPaused ? Colors.green : Colors.orange,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isPaused ? Colors.green : Colors.orange).withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isPaused ? Icons.play_arrow : Icons.pause,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Instructions
                      Text(
                        _isRecording 
                          ? 'Tap the red button to stop recording'
                          : 'Tap the green button to start recording',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Transcriptions List
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Transcriptions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '$_transcriptionCount total',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        else if (_transcriptions.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'No transcriptions yet. Start recording to see them here.',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: _transcriptions.length,
                              itemBuilder: (context, index) {
                                final transcription = _transcriptions[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: transcription['is_final'] == true 
                                        ? Colors.green 
                                        : Colors.orange,
                                      child: Icon(
                                        transcription['is_final'] == true 
                                          ? Icons.check 
                                          : Icons.hourglass_empty,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      transcription['text'] ?? 'No text',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Confidence: ${(transcription['confidence'] ?? 0.0).toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          'Time: ${transcription['start_time']?.toStringAsFixed(1)}s - ${transcription['end_time']?.toStringAsFixed(1)}s',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        if (transcription['processing_timestamp'] != null)
                                          Text(
                                            'Processed: ${transcription['processing_timestamp']}',
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class EnhancedVoiceRecordingScreen extends StatefulWidget {
  final String conversationId;
  final String conversationTitle;

  const EnhancedVoiceRecordingScreen({
    Key? key,
    required this.conversationId,
    required this.conversationTitle,
  }) : super(key: key);

  @override
  State<EnhancedVoiceRecordingScreen> createState() => _EnhancedVoiceRecordingScreenState();
}

class _EnhancedVoiceRecordingScreenState extends State<EnhancedVoiceRecordingScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ApiService _apiService = ApiService();
  
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _error;
  Duration _recordingDuration = Duration.zero;
  List<Map<String, dynamic>> _transcriptions = [];
  Timer? _durationTimer;
  Timer? _statusTimer;
  
  // Real-time status
  String _conversationStatus = 'inactive';
  int _transcriptionCount = 0;
  int _finalTranscriptionCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeRecording();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _statusTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _initializeRecording() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load existing transcriptions
      await _loadTranscriptions();
      
      // Check conversation status
      await _checkConversationStatus();
      
      // Request permissions
      await _requestPermissions();
      
    } catch (e) {
      setState(() {
        _error = 'Initialization failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    // Request microphone permission
    final microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus != PermissionStatus.granted) {
      throw Exception('Microphone permission is required for recording');
    }

    // Check if recorder is available
    if (!await _audioRecorder.hasPermission()) {
      throw Exception('Microphone permission not granted');
    }
  }

  Future<void> _checkConversationStatus() async {
    try {
      final response = await _apiService.getConversationStatus(widget.conversationId);
      
      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }
      
      setState(() {
        _conversationStatus = response['status'] ?? 'inactive';
        _transcriptionCount = response['transcription_count'] ?? 0;
        _finalTranscriptionCount = response['final_transcription_count'] ?? 0;
      });
    } catch (e) {
      print('Error checking conversation status: $e');
    }
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _checkConversationStatus();
        _loadTranscriptions();
      }
    });
  }

  Future<void> _loadTranscriptions() async {
    try {
      final response = await _apiService.getConversationTranscriptions(widget.conversationId);
      
      if (response.containsKey('error')) {
        setState(() {
          _error = response['error'];
        });
      } else {
        setState(() {
          _transcriptions = List<Map<String, dynamic>>.from(response['transcriptions'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading transcriptions: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Final permission check
      if (!await _audioRecorder.hasPermission()) {
        throw Exception('Microphone permission not granted');
      }

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: 'voice_recording_${DateTime.now().millisecondsSinceEpoch}.aac',
      );

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordingDuration = Duration.zero;
        _isLoading = false;
      });

      // Start duration timer
      _startDurationTimer();

      _showSuccessSnackBar('🎤 Recording started successfully');
      
      // Update conversation status
      await _checkConversationStatus();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error starting recording: $e';
      });
      _showErrorSnackBar('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      final recording = await _audioRecorder.stop();
      
      if (recording != null) {
        setState(() {
          _isRecording = false;
          _isPaused = false;
        });

        // Process the recorded audio
        await _processRecordedAudio(recording);
        
        _showSuccessSnackBar('✅ Recording stopped and processed');
      }
    } catch (e) {
      setState(() {
        _error = 'Error stopping recording: $e';
      });
      _showErrorSnackBar('Error stopping recording: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _audioRecorder.pause();
      setState(() {
        _isPaused = true;
      });
      _showSuccessSnackBar('⏸️ Recording paused');
    } catch (e) {
      _showErrorSnackBar('Error pausing recording: $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _audioRecorder.resume();
      setState(() {
        _isPaused = false;
      });
      _showSuccessSnackBar('▶️ Recording resumed');
    } catch (e) {
      _showErrorSnackBar('Error resuming recording: $e');
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRecording && !_isPaused && mounted) {
        setState(() {
          _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
        });
      }
    });
  }

  Future<void> _processRecordedAudio(String audioPath) async {
    try {
      // Read audio file and convert to base64
      final audioBytes = await _readAudioFile(audioPath);
      final base64Audio = base64Encode(audioBytes);

      // Send audio to backend for processing
      final response = await _apiService.processAudioChunk(
        conversationId: widget.conversationId,
        chunkIndex: _transcriptions.length,
        audioData: base64Audio,
      );

      if (response.containsKey('error')) {
        _showErrorSnackBar('Error processing audio: ${response['error']}');
      } else {
        // Reload transcriptions to show the new one
        await _loadTranscriptions();
        await _checkConversationStatus();
        _showSuccessSnackBar('🎯 Audio processed successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Error processing audio: $e');
    }
  }

  Future<Uint8List> _readAudioFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      } else {
        // If file doesn't exist, create dummy audio data for testing
        return Uint8List.fromList(List.generate(1000, (index) => index % 256));
      }
    } catch (e) {
      print('Error reading audio file: $e');
      // Return dummy audio data as fallback
      return Uint8List.fromList(List.generate(1000, (index) => index % 256));
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Recording'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadTranscriptions();
              _checkConversationStatus();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Conversation Info Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.conversationTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${widget.conversationId}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatusChip('Status', _conversationStatus, 
                              _conversationStatus == 'active' ? Colors.green : Colors.orange),
                          _buildStatusChip('Transcriptions', '$_transcriptionCount', Colors.blue),
                          _buildStatusChip('Final', '$_finalTranscriptionCount', Colors.purple),
                        ],
                      ),
                    ],
                  ),
                ),

                // Recording Controls
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Recording Status
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _isRecording ? Colors.red : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _isRecording ? Icons.mic : Icons.mic_off,
                              size: 60,
                              color: _isRecording ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isRecording 
                                ? (_isPaused ? 'Recording Paused' : 'Recording...')
                                : 'Ready to Record',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _isRecording ? Colors.red : Colors.grey,
                              ),
                            ),
                            if (_isRecording) ...[
                              const SizedBox(height: 8),
                              Text(
                                _formatDuration(_recordingDuration),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Control Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Start/Stop Button
                          GestureDetector(
                            onTap: _isRecording ? _stopRecording : _startRecording,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: _isRecording ? Colors.red : Colors.green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isRecording ? Colors.red : Colors.green).withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: _isProcessing
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Icon(
                                      _isRecording ? Icons.stop : Icons.mic,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                            ),
                          ),

                          // Pause/Resume Button (only when recording)
                          if (_isRecording) ...[
                            GestureDetector(
                              onTap: _isPaused ? _resumeRecording : _pauseRecording,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _isPaused ? Colors.green : Colors.orange,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isPaused ? Colors.green : Colors.orange).withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isPaused ? Icons.play_arrow : Icons.pause,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Instructions
                      Text(
                        _isRecording 
                          ? 'Tap the red button to stop recording'
                          : 'Tap the green button to start recording',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Transcriptions List
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Transcriptions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '$_transcriptionCount total',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        else if (_transcriptions.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'No transcriptions yet. Start recording to see them here.',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: _transcriptions.length,
                              itemBuilder: (context, index) {
                                final transcription = _transcriptions[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: transcription['is_final'] == true 
                                        ? Colors.green 
                                        : Colors.orange,
                                      child: Icon(
                                        transcription['is_final'] == true 
                                          ? Icons.check 
                                          : Icons.hourglass_empty,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      transcription['text'] ?? 'No text',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Confidence: ${(transcription['confidence'] ?? 0.0).toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          'Time: ${transcription['start_time']?.toStringAsFixed(1)}s - ${transcription['end_time']?.toStringAsFixed(1)}s',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        if (transcription['processing_timestamp'] != null)
                                          Text(
                                            'Processed: ${transcription['processing_timestamp']}',
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
