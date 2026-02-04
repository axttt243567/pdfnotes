import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-Speech service using local device TTS
class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  
  // Callbacks for UI updates
  Function()? onStart;
  Function()? onCompletion;
  Function(String, int, int)? onProgress;

  bool get isPlaying => _isPlaying;

  TTSService() {
    _init();
  }

  Future<void> _init() async {
    await _flutterTts.awaitSpeakCompletion(true);
    
    _flutterTts.setStartHandler(() {
      _isPlaying = true;
      if (onStart != null) onStart!();
    });

    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
      if (onCompletion != null) onCompletion!();
    });

    _flutterTts.setProgressHandler((text, start, end, word) {
      if (onProgress != null) onProgress!(text, start, end);
    });

    _flutterTts.setCancelHandler(() {
      _isPlaying = false;
      if (onCompletion != null) onCompletion!();
    });

    _flutterTts.setErrorHandler((msg) {
      _isPlaying = false;
      if (onCompletion != null) onCompletion!();
    });
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    // Stop if currently playing
    if (_isPlaying) {
      await stop();
    }
    
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isPlaying = false;
  }

  Future<void> pause() async {
    await _flutterTts.pause();
    _isPlaying = false;
  }

  void dispose() {
    _flutterTts.stop();
  }
}
