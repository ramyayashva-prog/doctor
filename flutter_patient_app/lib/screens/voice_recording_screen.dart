import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class VoiceRecordingScreen extends StatefulWidget {
  final String conversationId;
  final String conversationTitle;

  const VoiceRecordingScreen({
    Key? key,
    required this.conversationId,
    required this.conversationTitle,
  }) : super(key: key);

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ApiService _apiService = ApiService();
  
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isLoading = false;
  String? _error;
  Duration _recordingDuration = Duration.zero;
  List<Map<String, dynamic>> _transcriptions = [];
  
  // Timer for recording duration
  late Stream<Duration> _durationStream;

  @override
  void initState() {
    super.initState();
    _loadTranscriptions();
    _durationStream = Stream.periodic(const Duration(seconds: 1), (_) => _recordingDuration);
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _loadTranscriptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

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
      setState(() {
        _error = 'Error loading transcriptions: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _requestPermissions() async {
    final microphoneStatus = await Permission.microphone.request();
    return microphoneStatus == PermissionStatus.granted;
  }

  Future<void> _startRecording() async {
    try {
      // Request microphone permission
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        _showErrorSnackBar('Microphone permission is required for recording');
        return;
      }

      // Check if recorder is available
      if (!await _audioRecorder.hasPermission()) {
        _showErrorSnackBar('Microphone permission not granted');
        return;
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
        _error = null;
      });

      // Start duration timer
      _startDurationTimer();

      _showSuccessSnackBar('Recording started');
    } catch (e) {
      setState(() {
        _error = 'Error starting recording: $e';
      });
      _showErrorSnackBar('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final recording = await _audioRecorder.stop();
      
      if (recording != null) {
        setState(() {
          _isRecording = false;
          _isPaused = false;
        });

        // Process the recorded audio
        await _processRecordedAudio(recording);
        
        _showSuccessSnackBar('Recording stopped and processed');
      }
    } catch (e) {
      setState(() {
        _error = 'Error stopping recording: $e';
      });
      _showErrorSnackBar('Error stopping recording: $e');
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _audioRecorder.pause();
      setState(() {
        _isPaused = true;
      });
      _showSuccessSnackBar('Recording paused');
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
      _showSuccessSnackBar('Recording resumed');
    } catch (e) {
      _showErrorSnackBar('Error resuming recording: $e');
    }
  }

  void _startDurationTimer() {
    _durationStream.listen((duration) {
      if (_isRecording && !_isPaused) {
        setState(() {
          _recordingDuration = duration;
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
        _showSuccessSnackBar('Audio processed successfully');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Recording'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTranscriptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Conversation Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
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
                  'Conversation ID: ${widget.conversationId}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
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
                        StreamBuilder<Duration>(
                          stream: _durationStream,
                          builder: (context, snapshot) {
                            return Text(
                              _formatDuration(_recordingDuration),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            );
                          },
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
                        child: Icon(
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
                  const Text(
                    'Transcriptions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_error != null)
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
}

import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class VoiceRecordingScreen extends StatefulWidget {
  final String conversationId;
  final String conversationTitle;

  const VoiceRecordingScreen({
    Key? key,
    required this.conversationId,
    required this.conversationTitle,
  }) : super(key: key);

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ApiService _apiService = ApiService();
  
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isLoading = false;
  String? _error;
  Duration _recordingDuration = Duration.zero;
  List<Map<String, dynamic>> _transcriptions = [];
  
  // Timer for recording duration
  late Stream<Duration> _durationStream;

  @override
  void initState() {
    super.initState();
    _loadTranscriptions();
    _durationStream = Stream.periodic(const Duration(seconds: 1), (_) => _recordingDuration);
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _loadTranscriptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

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
      setState(() {
        _error = 'Error loading transcriptions: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _requestPermissions() async {
    final microphoneStatus = await Permission.microphone.request();
    return microphoneStatus == PermissionStatus.granted;
  }

  Future<void> _startRecording() async {
    try {
      // Request microphone permission
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        _showErrorSnackBar('Microphone permission is required for recording');
        return;
      }

      // Check if recorder is available
      if (!await _audioRecorder.hasPermission()) {
        _showErrorSnackBar('Microphone permission not granted');
        return;
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
        _error = null;
      });

      // Start duration timer
      _startDurationTimer();

      _showSuccessSnackBar('Recording started');
    } catch (e) {
      setState(() {
        _error = 'Error starting recording: $e';
      });
      _showErrorSnackBar('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final recording = await _audioRecorder.stop();
      
      if (recording != null) {
        setState(() {
          _isRecording = false;
          _isPaused = false;
        });

        // Process the recorded audio
        await _processRecordedAudio(recording);
        
        _showSuccessSnackBar('Recording stopped and processed');
      }
    } catch (e) {
      setState(() {
        _error = 'Error stopping recording: $e';
      });
      _showErrorSnackBar('Error stopping recording: $e');
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _audioRecorder.pause();
      setState(() {
        _isPaused = true;
      });
      _showSuccessSnackBar('Recording paused');
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
      _showSuccessSnackBar('Recording resumed');
    } catch (e) {
      _showErrorSnackBar('Error resuming recording: $e');
    }
  }

  void _startDurationTimer() {
    _durationStream.listen((duration) {
      if (_isRecording && !_isPaused) {
        setState(() {
          _recordingDuration = duration;
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
        _showSuccessSnackBar('Audio processed successfully');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Recording'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTranscriptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Conversation Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
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
                  'Conversation ID: ${widget.conversationId}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
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
                        StreamBuilder<Duration>(
                          stream: _durationStream,
                          builder: (context, snapshot) {
                            return Text(
                              _formatDuration(_recordingDuration),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            );
                          },
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
                        child: Icon(
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
                  const Text(
                    'Transcriptions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_error != null)
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
}

import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class VoiceRecordingScreen extends StatefulWidget {
  final String conversationId;
  final String conversationTitle;

  const VoiceRecordingScreen({
    Key? key,
    required this.conversationId,
    required this.conversationTitle,
  }) : super(key: key);

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ApiService _apiService = ApiService();
  
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isLoading = false;
  String? _error;
  Duration _recordingDuration = Duration.zero;
  List<Map<String, dynamic>> _transcriptions = [];
  
  // Timer for recording duration
  late Stream<Duration> _durationStream;

  @override
  void initState() {
    super.initState();
    _loadTranscriptions();
    _durationStream = Stream.periodic(const Duration(seconds: 1), (_) => _recordingDuration);
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _loadTranscriptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

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
      setState(() {
        _error = 'Error loading transcriptions: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _requestPermissions() async {
    final microphoneStatus = await Permission.microphone.request();
    return microphoneStatus == PermissionStatus.granted;
  }

  Future<void> _startRecording() async {
    try {
      // Request microphone permission
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        _showErrorSnackBar('Microphone permission is required for recording');
        return;
      }

      // Check if recorder is available
      if (!await _audioRecorder.hasPermission()) {
        _showErrorSnackBar('Microphone permission not granted');
        return;
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
        _error = null;
      });

      // Start duration timer
      _startDurationTimer();

      _showSuccessSnackBar('Recording started');
    } catch (e) {
      setState(() {
        _error = 'Error starting recording: $e';
      });
      _showErrorSnackBar('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final recording = await _audioRecorder.stop();
      
      if (recording != null) {
        setState(() {
          _isRecording = false;
          _isPaused = false;
        });

        // Process the recorded audio
        await _processRecordedAudio(recording);
        
        _showSuccessSnackBar('Recording stopped and processed');
      }
    } catch (e) {
      setState(() {
        _error = 'Error stopping recording: $e';
      });
      _showErrorSnackBar('Error stopping recording: $e');
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _audioRecorder.pause();
      setState(() {
        _isPaused = true;
      });
      _showSuccessSnackBar('Recording paused');
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
      _showSuccessSnackBar('Recording resumed');
    } catch (e) {
      _showErrorSnackBar('Error resuming recording: $e');
    }
  }

  void _startDurationTimer() {
    _durationStream.listen((duration) {
      if (_isRecording && !_isPaused) {
        setState(() {
          _recordingDuration = duration;
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
        _showSuccessSnackBar('Audio processed successfully');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Recording'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTranscriptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Conversation Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
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
                  'Conversation ID: ${widget.conversationId}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
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
                        StreamBuilder<Duration>(
                          stream: _durationStream,
                          builder: (context, snapshot) {
                            return Text(
                              _formatDuration(_recordingDuration),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            );
                          },
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
                        child: Icon(
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
                  const Text(
                    'Transcriptions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_error != null)
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
}
