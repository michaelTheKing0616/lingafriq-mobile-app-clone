import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Audio Recording Service for Voice Lessons
/// 
/// Handles:
/// - Microphone permission management
/// - Audio recording to file or stream
/// - Audio playback coordination
/// - Waveform visualization data
class AudioRecordingService {
  static final AudioRecordingService _instance = AudioRecordingService._internal();
  factory AudioRecordingService() => _instance;
  AudioRecordingService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  
  bool _isRecording = false;
  bool _hasPermission = false;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  
  // Stream controllers for state updates
  final StreamController<bool> _recordingStateController = StreamController<bool>.broadcast();
  final StreamController<double> _amplitudeController = StreamController<double>.broadcast();
  
  /// Stream of recording state changes
  Stream<bool> get recordingStateStream => _recordingStateController.stream;
  
  /// Stream of amplitude values for visualization
  Stream<double> get amplitudeStream => _amplitudeController.stream;
  
  /// Whether currently recording
  bool get isRecording => _isRecording;
  
  /// Whether microphone permission is granted
  bool get hasPermission => _hasPermission;
  
  /// Current recording duration
  Duration? get recordingDuration {
    if (_recordingStartTime == null) return null;
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    _hasPermission = status.isGranted;
    
    if (!_hasPermission) {
      debugPrint('Microphone permission denied: $status');
    }
    
    return _hasPermission;
  }

  /// Check if microphone permission is granted
  Future<bool> checkPermission() async {
    final status = await Permission.microphone.status;
    _hasPermission = status.isGranted;
    return _hasPermission;
  }

  /// Get temporary directory for recordings
  Future<String> _getRecordingPath() async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/voice_recording_$timestamp.wav';
  }

  /// Start recording audio
  /// 
  /// Returns the path where recording will be saved
  Future<String?> startRecording({
    int sampleRate = 16000,
    int numChannels = 1,
    int bitRate = 128000,
  }) async {
    if (_isRecording) {
      debugPrint('Already recording');
      return _currentRecordingPath;
    }

    // Check permission
    if (!_hasPermission) {
      final granted = await requestPermission();
      if (!granted) {
        debugPrint('Cannot start recording: permission denied');
        return null;
      }
    }

    // Check if recording is possible
    final hasRecorder = await _recorder.hasPermission();
    if (!hasRecorder) {
      debugPrint('Recorder not available');
      return null;
    }

    try {
      _currentRecordingPath = await _getRecordingPath();
      
      // Configure recording
      final config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: sampleRate,
        numChannels: numChannels,
        bitRate: bitRate,
      );

      await _recorder.start(config, path: _currentRecordingPath!);
      
      _isRecording = true;
      _recordingStartTime = DateTime.now();
      _recordingStateController.add(true);
      
      // Start amplitude monitoring
      _startAmplitudeMonitoring();
      
      debugPrint('Started recording to: $_currentRecordingPath');
      return _currentRecordingPath;
      
    } catch (e) {
      debugPrint('Failed to start recording: $e');
      _isRecording = false;
      _currentRecordingPath = null;
      return null;
    }
  }

  /// Start monitoring amplitude for visualization
  void _startAmplitudeMonitoring() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      
      try {
        final amplitude = await _recorder.getAmplitude();
        // Normalize amplitude to 0-1 range
        // dBFS typically ranges from -60 to 0
        final normalized = (amplitude.current + 60) / 60;
        _amplitudeController.add(normalized.clamp(0.0, 1.0));
      } catch (e) {
        // Ignore amplitude errors during recording
      }
    });
  }

  /// Stop recording and return the audio file path
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      debugPrint('Not currently recording');
      return null;
    }

    try {
      final path = await _recorder.stop();
      
      _isRecording = false;
      _recordingStateController.add(false);
      _recordingStartTime = null;
      
      debugPrint('Stopped recording: $path');
      return path ?? _currentRecordingPath;
      
    } catch (e) {
      debugPrint('Failed to stop recording: $e');
      _isRecording = false;
      _recordingStateController.add(false);
      return null;
    }
  }

  /// Cancel recording and delete the file
  Future<void> cancelRecording() async {
    await stopRecording();
    
    if (_currentRecordingPath != null) {
      try {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint('Deleted cancelled recording');
        }
      } catch (e) {
        debugPrint('Failed to delete recording: $e');
      }
    }
    
    _currentRecordingPath = null;
  }

  /// Read audio file as bytes
  Future<Uint8List?> getRecordingBytes(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('Failed to read recording: $e');
    }
    return null;
  }

  /// Delete a recording file
  Future<bool> deleteRecording(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint('Failed to delete recording: $e');
    }
    return false;
  }

  /// Clean up old recordings
  Future<void> cleanupOldRecordings({int maxAgeDays = 1}) async {
    try {
      final directory = await getTemporaryDirectory();
      final dir = Directory(directory.path);
      final cutoff = DateTime.now().subtract(Duration(days: maxAgeDays));
      
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.contains('voice_recording_')) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoff)) {
            await entity.delete();
            debugPrint('Cleaned up old recording: ${entity.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to cleanup recordings: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _recorder.dispose();
    _recordingStateController.close();
    _amplitudeController.close();
  }
}

