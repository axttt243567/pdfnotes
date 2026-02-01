import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static const String _apiKeysPrefsKey = 'gemini_api_keys_list';
  static const String _activeKeyIdPrefsKey = 'gemini_active_key_id';
  static const String _preferredModelsPrefsKey = 'gemini_preferred_models';
  static const String _defaultModel = 'gemini-1.5-flash';

  GenerativeModel? _model;
  ChatSession? _chatSession;
  
  // List of { "id": "uuid", "alias": "My Key", "key": "AIza..." }
  List<Map<String, String>> _apiKeys = [];
  String? _activeKeyId;
  
  List<String> _preferredModels = [_defaultModel];
  String _currentModelName = _defaultModel;

  // Singleton pattern
  static final GeminiService _instance = GeminiService._internal();

  factory GeminiService() {
    return _instance;
  }

  GeminiService._internal();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load API Keys
    final keysString = prefs.getString(_apiKeysPrefsKey);
    if (keysString != null) {
      final List<dynamic> decoded = jsonDecode(keysString);
      _apiKeys = decoded.map((e) => Map<String, String>.from(e)).toList();
    }

    // Load Active Key ID
    _activeKeyId = prefs.getString(_activeKeyIdPrefsKey);
    
    // Migrate legacy key if exists and no new keys found
    if (_apiKeys.isEmpty) {
        final legacyKey = prefs.getString('gemini_api_key');
        if (legacyKey != null && legacyKey.isNotEmpty) {
            await addApiKey(legacyKey, 'Default Key');
        }
    }

    // Load Preferred Models
    final modelsString = prefs.getString(_preferredModelsPrefsKey);
    if (modelsString != null) {
      final List<dynamic> decoded = jsonDecode(modelsString);
      _preferredModels = decoded.map((e) => e.toString()).toList();
    }
    
    // Initialize model if we have an active key
    _initModel();
  }

  void _initModel([String? modelName]) {
    final key = _getActiveKey();
    if (key != null) {
      _currentModelName = modelName ?? _currentModelName;
      _model = GenerativeModel(
        model: _currentModelName,
        apiKey: key,
      );
    }
  }

  String? _getActiveKey() {
    if (_activeKeyId == null && _apiKeys.isNotEmpty) {
        _activeKeyId = _apiKeys.first['id'];
    }
    
    if (_activeKeyId != null) {
        final keyMap = _apiKeys.firstWhere((element) => element['id'] == _activeKeyId, orElse: () => {});
        return keyMap['key'];
    }
    return null;
  }

  // --- API Key Management ---

  Future<void> addApiKey(String key, String alias) async {
    final prefs = await SharedPreferences.getInstance();
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    
    _apiKeys.add({
      'id': newId,
      'alias': alias,
      'key': key,
    });
    
    await prefs.setString(_apiKeysPrefsKey, jsonEncode(_apiKeys));
    
    // If it's the first key, make it active
    if (_apiKeys.length == 1) {
       await selectApiKey(newId);
    }
  }

  Future<void> removeApiKey(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _apiKeys.removeWhere((element) => element['id'] == id);
    await prefs.setString(_apiKeysPrefsKey, jsonEncode(_apiKeys));
    
    if (_activeKeyId == id) {
        _activeKeyId = _apiKeys.isNotEmpty ? _apiKeys.first['id'] : null;
        await prefs.setString(_activeKeyIdPrefsKey, _activeKeyId ?? '');
        _chatSession = null;
        _initModel();
    }
  }

  Future<void> selectApiKey(String id) async {
      final prefs = await SharedPreferences.getInstance();
      _activeKeyId = id;
      await prefs.setString(_activeKeyIdPrefsKey, id);
      _chatSession = null;
      _initModel();
  }

  List<Map<String, String>> getApiKeys() {
      return _apiKeys;
  }
  
  String? get activeKeyId => _activeKeyId;

  // --- Model Management ---

  Future<void> togglePreferredModel(String model) async {
     final prefs = await SharedPreferences.getInstance();
     if (_preferredModels.contains(model)) {
         if (_preferredModels.length > 1) { // Prevent removing the last model
            _preferredModels.remove(model);
         }
     } else {
         _preferredModels.add(model);
     }
     await prefs.setString(_preferredModelsPrefsKey, jsonEncode(_preferredModels));
  }

  List<String> getPreferredModels() => _preferredModels;
  
  bool isModelPreferred(String model) => _preferredModels.contains(model);

  // --- Chat & Generation ---

  bool get hasKey => _getActiveKey() != null;

  void startChat({String? model}) {
    if (model != null) {
        _initModel(model);
    }
    
    if (_model == null) {
      throw Exception('Gemini model not initialized. Please set API Key.');
    }
    _chatSession = _model!.startChat();
  }

  Future<String> sendMessage(String message) async {
    if (!hasKey) {
       throw Exception('API Key not found. Please add your Gemini API Key in Settings.');
    }

    if (_chatSession == null) {
      startChat();
    }

    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text ?? 'No response from AI.';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> generatePdfNotes(String topic, {String? modelName}) async {
    if (!hasKey) {
      throw Exception('API Key not found. Please add your Gemini API Key in Settings.');
    }

    // Use specific model if requested, otherwise active model
    GenerativeModel generationModel = _model!;
    if (modelName != null) {
        generationModel = GenerativeModel(model: modelName, apiKey: _getActiveKey()!);
    }

    const jsonSchema = '''
You are a helpful assistant that generates comprehensive notes for students.
Please generate notes on the topic provided below.
Return ONLY valid JSON content. Do not include markdown formatting (like ```json ... ```) around the JSON.
The JSON structure must be exactly as follows:
{
  "title": "Topic Title",
  "sections": [
    {
      "heading": "Section Heading",
      "content": "Paragraph text content...",
      "points": ["Key point 1", "Key point 2"]
    }
  ]
}
Note: "points" is optional. "content" is optional if there are points.
''';

    final prompt = '$jsonSchema\n\nTopic: $topic';

    try {
      final response = await generationModel.generateContent([Content.text(prompt)]);
      return response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '{}';
    } catch (e) {
      throw Exception('Failed to generate notes: $e');
    }
  }
}
