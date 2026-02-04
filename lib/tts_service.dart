import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-Speech service using local device TTS
class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isPlaying = false;
  bool _isInitialized = false;
  
  // Completion callback
  VoidCallback? onComplete;
  VoidCallback? onStart;
  VoidCallback? onError;

  TTSService() {
    _init();
  }
  
  bool get isPlaying => _isPlaying;

  Future<void> _init() async {
    if (_isInitialized) return;
    
    try {
      // Set default parameters
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5); // 0.0 to 1.0
      await _flutterTts.setVolume(1.0); // 0.0 to 1.0
      await _flutterTts.setPitch(1.0); // 0.5 to 2.0
      
      // Set up handlers
      _flutterTts.setStartHandler(() {
        _isPlaying = true;
        onStart?.call();
      });
      
      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
        onComplete?.call();
      });
      
      _flutterTts.setErrorHandler((msg) {
        _isPlaying = false;
        debugPrint('TTS Error: $msg');
        onError?.call();
      });
      
      _flutterTts.setCancelHandler(() {
        _isPlaying = false;
      });
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  /// Speak text directly using device TTS
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await _init();
    }
    
    // Stop any ongoing speech
    if (_isPlaying) {
      await stop();
    }
    
    try {
      _isPlaying = true;
      await _flutterTts.speak(text);
    } catch (e) {
      _isPlaying = false;
      debugPrint('TTS speak error: $e');
      rethrow;
    }
  }

  /// Pause speech (only works on some platforms)
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _isPlaying = false;
    } catch (e) {
      debugPrint('TTS pause error: $e');
    }
  }

  /// Stop speech
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isPlaying = false;
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  /// Set speech rate (0.0 to 1.0, default 0.5)
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
  }

  /// Set pitch (0.5 to 2.0, default 1.0)
  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
  }

  /// Set volume (0.0 to 1.0, default 1.0)
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Set language (e.g., 'en-US', 'en-GB', 'es-ES')
  Future<void> setLanguage(String language) async {
    await _flutterTts.setLanguage(language);
  }

  /// Get list of available languages
  Future<List<String>> getLanguages() async {
    final languages = await _flutterTts.getLanguages;
    return List<String>.from(languages ?? []);
  }

  /// Get list of available voices
  Future<List<dynamic>> getVoices() async {
    final voices = await _flutterTts.getVoices;
    return voices ?? [];
  }

  /// Check if a language is available
  Future<bool> isLanguageAvailable(String language) async {
    return await _flutterTts.isLanguageAvailable(language) == 1;
  }

  void dispose() {
    _flutterTts.stop();
  }
}
