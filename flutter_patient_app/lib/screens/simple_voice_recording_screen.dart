import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import '../services/api_service.dart';
import '../utils/constants.dart';

class SimpleVoiceRecordingScreen extends StatefulWidget {
  final String conversationId;
  final String conversationTitle;

  const SimpleVoiceRecordingScreen({
    Key? key,
    required this.conversationId,
    required this.conversationTitle,
  }) : super(key: key);

  @override
  State<SimpleVoiceRecordingScreen> createState() => _SimpleVoiceRecordingScreenState();
}

class _SimpleVoiceRecordingScreenState extends State<SimpleVoiceRecordingScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ApiService _apiService = ApiService();
  
  bool _isRecording = false;
  bool _isLoading = false;
  String? _error;
  Duration _recordingDuration = Duration.zero;
  List<Map<String, dynamic>> _transcriptions = [];
  Timer? _durationTimer;
  String? _recordingPath;
  
  // Conversation summary
  String? _conversationSummary;
  bool _isLoadingSummary = false;

  @override
  void initState() {
    super.initState();
    _loadTranscriptions();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
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

  Future<void> _loadConversationSummary() async {
    setState(() {
      _isLoadingSummary = true;
    });

    try {
      print('📝 Loading conversation summary...');
      final response = await _apiService.getConversationSummary(widget.conversationId);
      
      if (response.containsKey('error')) {
        print('❌ Summary error: ${response['error']}');
        setState(() {
          _conversationSummary = 'Error loading summary: ${response['error']}';
        });
      } else {
        final summary = response['text_summary'] ?? 'No summary available';
        print('✅ Summary loaded: $summary');
        setState(() {
          _conversationSummary = summary;
        });
      }
    } catch (e) {
      print('❌ Summary loading error: $e');
      setState(() {
        _conversationSummary = 'Error loading summary: $e';
      });
    } finally {
      setState(() {
        _isLoadingSummary = false;
      });
    }
  }

  Future<bool> _checkPermissions() async {
    print('🔍 Checking microphone permissions...');
    
    // Check microphone permission
    final microphoneStatus = await Permission.microphone.status;
    print('🔍 Microphone permission status: $microphoneStatus');
    
    if (microphoneStatus != PermissionStatus.granted) {
      print('🔍 Requesting microphone permission...');
      final requestResult = await Permission.microphone.request();
      print('🔍 Permission request result: $requestResult');
      
      if (requestResult != PermissionStatus.granted) {
        _showErrorSnackBar('Microphone permission is required for recording');
        return false;
      }
    }

    // Check if recorder is available
    final hasPermission = await _audioRecorder.hasPermission();
    print('🔍 AudioRecorder has permission: $hasPermission');
    
    if (!hasPermission) {
      _showErrorSnackBar('Audio recorder permission not granted');
      return false;
    }

    return true;
  }

  Future<void> _startRecording() async {
    print('🎤 Starting recording...');
    
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Check permissions
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Generate recording path
      _recordingPath = 'voice_recording_${DateTime.now().millisecondsSinceEpoch}.aac';
      print('🔍 Recording path: $_recordingPath');

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );

      print('✅ Recording started successfully');

      setState(() {
        _isRecording = true;
        _isLoading = false;
        _recordingDuration = Duration.zero;
      });

      // Start duration timer
      _startDurationTimer();

      _showSuccessSnackBar('🎤 Recording started successfully');
      
    } catch (e) {
      print('❌ Error starting recording: $e');
      setState(() {
        _isLoading = false;
        _error = 'Error starting recording: $e';
      });
      _showErrorSnackBar('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    print('🛑 Stopping recording...');
    
    try {
      setState(() {
        _isLoading = true;
      });

      final recording = await _audioRecorder.stop();
      print('🔍 Recording stopped, path: $recording');
      
      if (recording != null) {
        setState(() {
          _isRecording = false;
          _isLoading = false;
        });

        // Process the recorded audio
        await _processRecordedAudio(recording);
        
        _showSuccessSnackBar('✅ Recording stopped and processed');
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('No recording data received');
      }
    } catch (e) {
      print('❌ Error stopping recording: $e');
      setState(() {
        _isLoading = false;
        _error = 'Error stopping recording: $e';
      });
      _showErrorSnackBar('Error stopping recording: $e');
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
        });
      }
    });
  }

  Future<void> _processRecordedAudio(String audioPath) async {
    print('🔄 Processing recorded audio: $audioPath');
    
    try {
      // Read audio file and convert to base64
      final audioBytes = await _readAudioFile(audioPath);
      final base64Audio = base64Encode(audioBytes);
      print('🔍 Audio file size: ${audioBytes.length} bytes');

      // Send audio to backend for processing
      final response = await _apiService.processAudioChunk(
        conversationId: widget.conversationId,
        chunkIndex: _transcriptions.length,
        audioData: base64Audio,
      );

      print('🔍 Processing response: $response');

      if (response.containsKey('error')) {
        _showErrorSnackBar('Error processing audio: ${response['error']}');
      } else {
        // Reload transcriptions to show the new one
        await _loadTranscriptions();
        // Load conversation summary after processing
        await _loadConversationSummary();
        _showSuccessSnackBar('🎯 Audio processed successfully');
      }
    } catch (e) {
      print('❌ Error processing audio: $e');
      _showErrorSnackBar('Error processing audio: $e');
    }
  }

  Future<Uint8List> _readAudioFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        print('🔍 Read audio file: ${bytes.length} bytes');
        return bytes;
      } else {
        print('⚠️ Audio file not found, creating dummy data');
        // Create dummy audio data for testing
        return Uint8List.fromList(List.generate(1000, (index) => index % 256));
      }
    } catch (e) {
      print('❌ Error reading audio file: $e');
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
          backgroundColor: Colors.green,
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
          backgroundColor: Colors.red,
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
                        _isRecording ? 'Recording...' : 'Ready to Record',
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

                // Control Button
                GestureDetector(
                  onTap: _isLoading ? null : (_isRecording ? _stopRecording : _startRecording),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isLoading 
                        ? Colors.grey 
                        : (_isRecording ? Colors.red : Colors.green),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : Colors.green).withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            size: 40,
                            color: Colors.white,
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Instructions
                Text(
                  _isLoading
                    ? 'Please wait...'
                    : (_isRecording 
                        ? 'Tap the red button to stop recording'
                        : 'Tap the green button to start recording'),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Debug Info
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Conversation Summary
          if (_conversationSummary != null || _isLoadingSummary)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.summarize, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Conversation Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Spacer(),
                      if (_isLoadingSummary)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_conversationSummary != null)
                    Text(
                      _conversationSummary!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    )
                  else if (_isLoadingSummary)
                    const Text(
                      'Generating summary...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
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
                    children: [
                      const Text(
                        'Transcriptions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _loadConversationSummary,
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Refresh Summary',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
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

import 'package:record/record.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import '../services/api_service.dart';
import '../utils/constants.dart';

class SimpleVoiceRecordingScreen extends StatefulWidget {
  final String conversationId;
  final String conversationTitle;

  const SimpleVoiceRecordingScreen({
    Key? key,
    required this.conversationId,
    required this.conversationTitle,
  }) : super(key: key);

  @override
  State<SimpleVoiceRecordingScreen> createState() => _SimpleVoiceRecordingScreenState();
}

class _SimpleVoiceRecordingScreenState extends State<SimpleVoiceRecordingScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ApiService _apiService = ApiService();
  
  bool _isRecording = false;
  bool _isLoading = false;
  String? _error;
  Duration _recordingDuration = Duration.zero;
  List<Map<String, dynamic>> _transcriptions = [];
  Timer? _durationTimer;
  String? _recordingPath;
  
  // Conversation summary
  String? _conversationSummary;
  bool _isLoadingSummary = false;

  @override
  void initState() {
    super.initState();
    _loadTranscriptions();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
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

  Future<void> _loadConversationSummary() async {
    setState(() {
      _isLoadingSummary = true;
    });

    try {
      print('📝 Loading conversation summary...');
      final response = await _apiService.getConversationSummary(widget.conversationId);
      
      if (response.containsKey('error')) {
        print('❌ Summary error: ${response['error']}');
        setState(() {
          _conversationSummary = 'Error loading summary: ${response['error']}';
        });
      } else {
        final summary = response['text_summary'] ?? 'No summary available';
        print('✅ Summary loaded: $summary');
        setState(() {
          _conversationSummary = summary;
        });
      }
    } catch (e) {
      print('❌ Summary loading error: $e');
      setState(() {
        _conversationSummary = 'Error loading summary: $e';
      });
    } finally {
      setState(() {
        _isLoadingSummary = false;
      });
    }
  }

  Future<bool> _checkPermissions() async {
    print('🔍 Checking microphone permissions...');
    
    // Check microphone permission
    final microphoneStatus = await Permission.microphone.status;
    print('🔍 Microphone permission status: $microphoneStatus');
    
    if (microphoneStatus != PermissionStatus.granted) {
      print('🔍 Requesting microphone permission...');
      final requestResult = await Permission.microphone.request();
      print('🔍 Permission request result: $requestResult');
      
      if (requestResult != PermissionStatus.granted) {
        _showErrorSnackBar('Microphone permission is required for recording');
        return false;
      }
    }

    // Check if recorder is available
    final hasPermission = await _audioRecorder.hasPermission();
    print('🔍 AudioRecorder has permission: $hasPermission');
    
    if (!hasPermission) {
      _showErrorSnackBar('Audio recorder permission not granted');
      return false;
    }

    return true;
  }

  Future<void> _startRecording() async {
    print('🎤 Starting recording...');
    
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Check permissions
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Generate recording path
      _recordingPath = 'voice_recording_${DateTime.now().millisecondsSinceEpoch}.aac';
      print('🔍 Recording path: $_recordingPath');

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );

      print('✅ Recording started successfully');

      setState(() {
        _isRecording = true;
        _isLoading = false;
        _recordingDuration = Duration.zero;
      });

      // Start duration timer
      _startDurationTimer();

      _showSuccessSnackBar('🎤 Recording started successfully');
      
    } catch (e) {
      print('❌ Error starting recording: $e');
      setState(() {
        _isLoading = false;
        _error = 'Error starting recording: $e';
      });
      _showErrorSnackBar('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    print('🛑 Stopping recording...');
    
    try {
      setState(() {
        _isLoading = true;
      });

      final recording = await _audioRecorder.stop();
      print('🔍 Recording stopped, path: $recording');
      
      if (recording != null) {
        setState(() {
          _isRecording = false;
          _isLoading = false;
        });

        // Process the recorded audio
        await _processRecordedAudio(recording);
        
        _showSuccessSnackBar('✅ Recording stopped and processed');
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('No recording data received');
      }
    } catch (e) {
      print('❌ Error stopping recording: $e');
      setState(() {
        _isLoading = false;
        _error = 'Error stopping recording: $e';
      });
      _showErrorSnackBar('Error stopping recording: $e');
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
        });
      }
    });
  }

  Future<void> _processRecordedAudio(String audioPath) async {
    print('🔄 Processing recorded audio: $audioPath');
    
    try {
      // Read audio file and convert to base64
      final audioBytes = await _readAudioFile(audioPath);
      final base64Audio = base64Encode(audioBytes);
      print('🔍 Audio file size: ${audioBytes.length} bytes');

      // Send audio to backend for processing
      final response = await _apiService.processAudioChunk(
        conversationId: widget.conversationId,
        chunkIndex: _transcriptions.length,
        audioData: base64Audio,
      );

      print('🔍 Processing response: $response');

      if (response.containsKey('error')) {
        _showErrorSnackBar('Error processing audio: ${response['error']}');
      } else {
        // Reload transcriptions to show the new one
        await _loadTranscriptions();
        // Load conversation summary after processing
        await _loadConversationSummary();
        _showSuccessSnackBar('🎯 Audio processed successfully');
      }
    } catch (e) {
      print('❌ Error processing audio: $e');
      _showErrorSnackBar('Error processing audio: $e');
    }
  }

  Future<Uint8List> _readAudioFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        print('🔍 Read audio file: ${bytes.length} bytes');
        return bytes;
      } else {
        print('⚠️ Audio file not found, creating dummy data');
        // Create dummy audio data for testing
        return Uint8List.fromList(List.generate(1000, (index) => index % 256));
      }
    } catch (e) {
      print('❌ Error reading audio file: $e');
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
          backgroundColor: Colors.green,
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
          backgroundColor: Colors.red,
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
                        _isRecording ? 'Recording...' : 'Ready to Record',
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

                // Control Button
                GestureDetector(
                  onTap: _isLoading ? null : (_isRecording ? _stopRecording : _startRecording),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isLoading 
                        ? Colors.grey 
                        : (_isRecording ? Colors.red : Colors.green),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : Colors.green).withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            size: 40,
                            color: Colors.white,
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Instructions
                Text(
                  _isLoading
                    ? 'Please wait...'
                    : (_isRecording 
                        ? 'Tap the red button to stop recording'
                        : 'Tap the green button to start recording'),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Debug Info
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Conversation Summary
          if (_conversationSummary != null || _isLoadingSummary)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.summarize, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Conversation Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Spacer(),
                      if (_isLoadingSummary)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_conversationSummary != null)
                    Text(
                      _conversationSummary!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    )
                  else if (_isLoadingSummary)
                    const Text(
                      'Generating summary...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
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
                    children: [
                      const Text(
                        'Transcriptions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _loadConversationSummary,
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Refresh Summary',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
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

import 'package:record/record.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import '../services/api_service.dart';
import '../utils/constants.dart';

class SimpleVoiceRecordingScreen extends StatefulWidget {
  final String conversationId;
  final String conversationTitle;

  const SimpleVoiceRecordingScreen({
    Key? key,
    required this.conversationId,
    required this.conversationTitle,
  }) : super(key: key);

  @override
  State<SimpleVoiceRecordingScreen> createState() => _SimpleVoiceRecordingScreenState();
}

class _SimpleVoiceRecordingScreenState extends State<SimpleVoiceRecordingScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ApiService _apiService = ApiService();
  
  bool _isRecording = false;
  bool _isLoading = false;
  String? _error;
  Duration _recordingDuration = Duration.zero;
  List<Map<String, dynamic>> _transcriptions = [];
  Timer? _durationTimer;
  String? _recordingPath;
  
  // Conversation summary
  String? _conversationSummary;
  bool _isLoadingSummary = false;

  @override
  void initState() {
    super.initState();
    _loadTranscriptions();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
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

  Future<void> _loadConversationSummary() async {
    setState(() {
      _isLoadingSummary = true;
    });

    try {
      print('📝 Loading conversation summary...');
      final response = await _apiService.getConversationSummary(widget.conversationId);
      
      if (response.containsKey('error')) {
        print('❌ Summary error: ${response['error']}');
        setState(() {
          _conversationSummary = 'Error loading summary: ${response['error']}';
        });
      } else {
        final summary = response['text_summary'] ?? 'No summary available';
        print('✅ Summary loaded: $summary');
        setState(() {
          _conversationSummary = summary;
        });
      }
    } catch (e) {
      print('❌ Summary loading error: $e');
      setState(() {
        _conversationSummary = 'Error loading summary: $e';
      });
    } finally {
      setState(() {
        _isLoadingSummary = false;
      });
    }
  }

  Future<bool> _checkPermissions() async {
    print('🔍 Checking microphone permissions...');
    
    // Check microphone permission
    final microphoneStatus = await Permission.microphone.status;
    print('🔍 Microphone permission status: $microphoneStatus');
    
    if (microphoneStatus != PermissionStatus.granted) {
      print('🔍 Requesting microphone permission...');
      final requestResult = await Permission.microphone.request();
      print('🔍 Permission request result: $requestResult');
      
      if (requestResult != PermissionStatus.granted) {
        _showErrorSnackBar('Microphone permission is required for recording');
        return false;
      }
    }

    // Check if recorder is available
    final hasPermission = await _audioRecorder.hasPermission();
    print('🔍 AudioRecorder has permission: $hasPermission');
    
    if (!hasPermission) {
      _showErrorSnackBar('Audio recorder permission not granted');
      return false;
    }

    return true;
  }

  Future<void> _startRecording() async {
    print('🎤 Starting recording...');
    
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Check permissions
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Generate recording path
      _recordingPath = 'voice_recording_${DateTime.now().millisecondsSinceEpoch}.aac';
      print('🔍 Recording path: $_recordingPath');

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );

      print('✅ Recording started successfully');

      setState(() {
        _isRecording = true;
        _isLoading = false;
        _recordingDuration = Duration.zero;
      });

      // Start duration timer
      _startDurationTimer();

      _showSuccessSnackBar('🎤 Recording started successfully');
      
    } catch (e) {
      print('❌ Error starting recording: $e');
      setState(() {
        _isLoading = false;
        _error = 'Error starting recording: $e';
      });
      _showErrorSnackBar('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    print('🛑 Stopping recording...');
    
    try {
      setState(() {
        _isLoading = true;
      });

      final recording = await _audioRecorder.stop();
      print('🔍 Recording stopped, path: $recording');
      
      if (recording != null) {
        setState(() {
          _isRecording = false;
          _isLoading = false;
        });

        // Process the recorded audio
        await _processRecordedAudio(recording);
        
        _showSuccessSnackBar('✅ Recording stopped and processed');
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('No recording data received');
      }
    } catch (e) {
      print('❌ Error stopping recording: $e');
      setState(() {
        _isLoading = false;
        _error = 'Error stopping recording: $e';
      });
      _showErrorSnackBar('Error stopping recording: $e');
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
        });
      }
    });
  }

  Future<void> _processRecordedAudio(String audioPath) async {
    print('🔄 Processing recorded audio: $audioPath');
    
    try {
      // Read audio file and convert to base64
      final audioBytes = await _readAudioFile(audioPath);
      final base64Audio = base64Encode(audioBytes);
      print('🔍 Audio file size: ${audioBytes.length} bytes');

      // Send audio to backend for processing
      final response = await _apiService.processAudioChunk(
        conversationId: widget.conversationId,
        chunkIndex: _transcriptions.length,
        audioData: base64Audio,
      );

      print('🔍 Processing response: $response');

      if (response.containsKey('error')) {
        _showErrorSnackBar('Error processing audio: ${response['error']}');
      } else {
        // Reload transcriptions to show the new one
        await _loadTranscriptions();
        // Load conversation summary after processing
        await _loadConversationSummary();
        _showSuccessSnackBar('🎯 Audio processed successfully');
      }
    } catch (e) {
      print('❌ Error processing audio: $e');
      _showErrorSnackBar('Error processing audio: $e');
    }
  }

  Future<Uint8List> _readAudioFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        print('🔍 Read audio file: ${bytes.length} bytes');
        return bytes;
      } else {
        print('⚠️ Audio file not found, creating dummy data');
        // Create dummy audio data for testing
        return Uint8List.fromList(List.generate(1000, (index) => index % 256));
      }
    } catch (e) {
      print('❌ Error reading audio file: $e');
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
          backgroundColor: Colors.green,
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
          backgroundColor: Colors.red,
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
                        _isRecording ? 'Recording...' : 'Ready to Record',
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

                // Control Button
                GestureDetector(
                  onTap: _isLoading ? null : (_isRecording ? _stopRecording : _startRecording),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isLoading 
                        ? Colors.grey 
                        : (_isRecording ? Colors.red : Colors.green),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : Colors.green).withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            size: 40,
                            color: Colors.white,
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Instructions
                Text(
                  _isLoading
                    ? 'Please wait...'
                    : (_isRecording 
                        ? 'Tap the red button to stop recording'
                        : 'Tap the green button to start recording'),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Debug Info
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Conversation Summary
          if (_conversationSummary != null || _isLoadingSummary)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.summarize, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Conversation Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Spacer(),
                      if (_isLoadingSummary)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_conversationSummary != null)
                    Text(
                      _conversationSummary!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    )
                  else if (_isLoadingSummary)
                    const Text(
                      'Generating summary...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
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
                    children: [
                      const Text(
                        'Transcriptions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _loadConversationSummary,
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Refresh Summary',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
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
