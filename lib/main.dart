import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'pdf_schema.dart';
import 'pdf_generator.dart';
import 'pdf_system_prompt.dart';
import 'genpdfprompt_system.dart';
import 'chat_profile_page.dart';

void main() {
  runApp(const MyApp());
}

// Simple device storage
class ApiKeyStorage {
  static const String _key = 'gemini_api_key';
  static String? _apiKey;

  static String? get apiKey => _apiKey;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_key);
  }

  static Future<void> save(String value) async {
    _apiKey = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
  }
}

// Available Gemini models
class GeminiModels {
  static const List<String> available = [
    'gemini-3-flash-preview',
    'gemini-2.5-pro',
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
  ];

  static const String defaultPrimary = 'gemini-2.5-flash';
  static const String defaultSecondary = 'gemini-2.5-flash-lite';
}

// Model preferences storage
class ModelPreferences {
  static const String _primaryKey = 'primary_model';
  static const String _secondaryKey = 'secondary_model';
  
  static String _primaryModel = GeminiModels.defaultPrimary;
  static String _secondaryModel = GeminiModels.defaultSecondary;

  static String get primaryModel => _primaryModel;
  static String get secondaryModel => _secondaryModel;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPrimary = prefs.getString(_primaryKey);
    final savedSecondary = prefs.getString(_secondaryKey);
    
    // Validate saved models exist in available list, otherwise use defaults
    _primaryModel = (savedPrimary != null && GeminiModels.available.contains(savedPrimary))
        ? savedPrimary
        : GeminiModels.defaultPrimary;
    _secondaryModel = (savedSecondary != null && GeminiModels.available.contains(savedSecondary))
        ? savedSecondary
        : GeminiModels.defaultSecondary;
  }

  static Future<void> savePrimary(String model) async {
    _primaryModel = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_primaryKey, model);
  }

  static Future<void> saveSecondary(String model) async {
    _secondaryModel = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_secondaryKey, model);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}

// Message types enum
enum MessageType { text, pdf }

// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final MessageType type;
  final PdfInfo? pdfInfo;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.type = MessageType.text,
    this.pdfInfo,
  });
}

// PDF info model for PDF cards
class PdfInfo {
  final String title;
  final String description;
  final int pages;
  final String? assetPath;
  final String? url;

  PdfInfo({
    required this.title,
    required this.description,
    required this.pages,
    this.assetPath,
    this.url,
  });
}

// Gemini AI Service
class GeminiService {
  GenerativeModel? _model;
  ChatSession? _chatSession;
  String? _apiKey;
  String? _currentModel;
  
  // Dedicated session for prompt crafting
  ChatSession? _promptCraftingSession;

  void initialize(String apiKey) {
    _apiKey = apiKey;
    _reinitializeModel();
  }

  /// Reinitialize with the current primary model
  void _reinitializeModel() {
    if (_apiKey == null) return;
    
    final modelName = ModelPreferences.primaryModel;
    _currentModel = modelName;
    _model = GenerativeModel(model: modelName, apiKey: _apiKey!);
    _chatSession = _model!.startChat();
  }

  /// Refresh model if preferences changed
  void refreshModel() {
    if (_currentModel != ModelPreferences.primaryModel) {
      _reinitializeModel();
    }
  }

  bool get isInitialized => _model != null && _chatSession != null;

  Future<String> sendMessage(String message) async {
    if (!isInitialized) {
      throw Exception('Gemini service not initialized. Please set API key.');
    }

    // Refresh model if user changed preference
    refreshModel();

    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text ?? 'No response received.';
    } catch (e) {
      throw Exception('Failed to get AI response: $e');
    }
  }

  /// Send a PDF generation request with system prompt
  Future<String> sendPDFRequest(String topic) async {
    if (!isInitialized || _apiKey == null) {
      throw Exception('Gemini service not initialized. Please set API key.');
    }

    try {
      // Use the primary model for PDF generation
      final pdfModel = GenerativeModel(
        model: ModelPreferences.primaryModel,
        apiKey: _apiKey!,
        systemInstruction: Content.text(pdfSystemPrompt),
      );

      final response = await pdfModel.generateContent([
        Content.text('Create comprehensive educational notes about: $topic'),
      ]);

      return response.text ?? 'No response received.';
    } catch (e) {
      throw Exception('Failed to generate PDF content: $e');
    }
  }

  void reset() {
    if (_apiKey != null) {
      _reinitializeModel();
    }
  }

  /// Start a new prompt crafting session with the #genpdfprompt system prompt
  void startPromptCraftingSession() {
    if (_apiKey == null) return;
    
    final promptCraftingModel = GenerativeModel(
      model: ModelPreferences.primaryModel,
      apiKey: _apiKey!,
      systemInstruction: Content.text(genpdfpromptSystemPrompt),
    );
    _promptCraftingSession = promptCraftingModel.startChat();
  }

  /// Send a message to the prompt crafting session
  Future<String> sendPromptCraftingMessage(String message) async {
    if (_promptCraftingSession == null) {
      throw Exception('Prompt crafting session not started.');
    }

    try {
      final response = await _promptCraftingSession!.sendMessage(Content.text(message));
      return response.text ?? 'No response received.';
    } catch (e) {
      throw Exception('Failed to get prompt crafting response: $e');
    }
  }

  /// Check if prompt crafting session is active
  bool get hasPromptCraftingSession => _promptCraftingSession != null;

  /// End the prompt crafting session
  void endPromptCraftingSession() {
    _promptCraftingSession = null;
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final GeminiService _geminiService = GeminiService();
  bool _isLoading = false;
  bool _isInPromptCraftingMode = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await ApiKeyStorage.load();
    await ModelPreferences.load();
    if (ApiKeyStorage.apiKey != null && mounted) {
      _apiKeyController.text = ApiKeyStorage.apiKey!;
      _geminiService.initialize(ApiKeyStorage.apiKey!);
      setState(() {});
    }
  }

  Future<void> _saveApiKey(String apiKey) async {
    await ApiKeyStorage.save(apiKey);
    _geminiService.initialize(apiKey);
    if (mounted) {
      setState(() {});
    }
  }

  void _showSettingsBottomSheet() {
    _apiKeyController.text = ApiKeyStorage.apiKey ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Settings',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    
                    // API Key Section
                    const SizedBox(height: 20),
                    const Text(
                      'API Key',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Enter your Gemini API key',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: ApiKeyStorage.apiKey != null &&
                                ApiKeyStorage.apiKey!.isNotEmpty
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final apiKey = _apiKeyController.text.trim();
                          if (apiKey.isNotEmpty) {
                            _saveApiKey(apiKey);
                            setModalState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('API key saved')),
                            );
                          }
                        },
                        child: const Text('Save API Key'),
                      ),
                    ),
                    
                    // Model Selection Section
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Model Selection',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose models for AI chat and PDF generation',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    
                    // Primary Model
                    const SizedBox(height: 16),
                    const Text(
                      'Primary Model',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: ModelPreferences.primaryModel,
                          isExpanded: true,
                          items: GeminiModels.available.map((model) {
                            return DropdownMenuItem(
                              value: model,
                              child: Text(
                                model,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) async {
                            if (value != null) {
                              await ModelPreferences.savePrimary(value);
                              setModalState(() {});
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ),
                    
                    // Secondary Model
                    const SizedBox(height: 16),
                    const Text(
                      'Secondary Model (fallback)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: ModelPreferences.secondaryModel,
                          isExpanded: true,
                          items: GeminiModels.available.map((model) {
                            return DropdownMenuItem(
                              value: model,
                              child: Text(
                                model,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) async {
                            if (value != null) {
                              await ModelPreferences.saveSecondary(value);
                              setModalState(() {});
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Check for #genpdfprompt command - start prompt crafting mode
    if (text.toLowerCase().contains('#genpdfprompt')) {
      await _handleGenPdfPromptCommand(text);
      return;
    }

    // If in prompt crafting mode, continue the conversation
    if (_isInPromptCraftingMode) {
      await _continuePromptCrafting(text);
      return;
    }

    // Check for #genpdf command - generate PDF from AI
    if (text.toLowerCase().contains('#genpdf')) {
      final topic = text.replaceAll(RegExp(r'#genpdf', caseSensitive: false), '').trim();
      await _handleGenPdfCommand(topic.isEmpty ? 'Introduction to Programming' : topic);
      return;
    }

    // Check for #pdf dev test keyword
    if (text.toLowerCase().contains('#pdf')) {
      await _handlePdfCommand();
      return;
    }

    // Check if API key is set
    if (!_geminiService.isInitialized) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'Please set your API key first. Tap the ⚡ icon to add your key.',
            isUser: false,
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    // Send to Gemini AI
    try {
      final response = await _geminiService.sendMessage(text);
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(text: 'Error: ${e.toString()}', isUser: false),
        );
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> _handlePdfCommand() async {
    // Simulate a small delay for demo purposes
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _messages.add(
        ChatMessage(
          text: "Here's your demo PDF document:",
          isUser: false,
          type: MessageType.pdf,
          pdfInfo: PdfInfo(
            title: 'Attention Is All You Need',
            description: 'The original Transformer paper (NIPS 2017)',
            pages: 15,
            assetPath: 'assets/NIPS-2017-attention-is-all-you-need-Paper.pdf',
          ),
        ),
      );
      _isLoading = false;
    });
    _scrollToBottom();
  }

  /// Handle #genpdfprompt command - start the prompt crafting conversation
  Future<void> _handleGenPdfPromptCommand(String initialMessage) async {
    // Check if API key is set
    if (!_geminiService.isInitialized) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Please set your API key first. Tap the ⚡ icon to add your key.',
            isUser: false,
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    // Start prompt crafting session
    _geminiService.startPromptCraftingSession();
    setState(() {
      _isInPromptCraftingMode = true;
    });

    try {
      // Send initial message to start the conversation
      final response = await _geminiService.sendPromptCraftingMessage(
        "The user wants to create a personalized PDF prompt. Start the conversation by greeting them and asking about their PDF needs."
      );
      
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(text: '❌ Error starting prompt crafting: ${e.toString()}', isUser: false),
        );
        _isLoading = false;
        _isInPromptCraftingMode = false;
      });
      _geminiService.endPromptCraftingSession();
    }
    _scrollToBottom();
  }

  /// Continue the prompt crafting conversation
  Future<void> _continuePromptCrafting(String userMessage) async {
    // Check if user wants to exit prompt crafting mode
    if (userMessage.toLowerCase().contains('#exit') || 
        userMessage.toLowerCase().contains('#done') ||
        userMessage.toLowerCase().contains('#cancel')) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: '✅ Exited prompt crafting mode. You can start again with #genpdfprompt',
            isUser: false,
          ),
        );
        _isLoading = false;
        _isInPromptCraftingMode = false;
      });
      _geminiService.endPromptCraftingSession();
      _scrollToBottom();
      return;
    }

    try {
      final response = await _geminiService.sendPromptCraftingMessage(userMessage);
      
      // Check if the response contains a final #genpdf command (conversation complete)
      if (response.contains('#genpdf') && response.contains('```')) {
        // The AI has provided a final prompt, offer to exit crafting mode
        setState(() {
          _messages.add(ChatMessage(text: response, isUser: false));
          _messages.add(
            ChatMessage(
              text: '💡 *Tip: Copy the #genpdf command above and paste it to generate your PDF. Type #done to exit prompt crafting mode, or continue chatting to refine further.*',
              isUser: false,
            ),
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(text: response, isUser: false));
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(text: '❌ Error: ${e.toString()}', isUser: false),
        );
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }


  /// Handle #genpdf command - generate PDF from AI
  /// Extract JSON from AI response that may contain markdown or extra text
  String _extractJsonFromResponse(String response) {
    String text = response.trim();
    
    // Remove markdown code fences
    if (text.contains('```json')) {
      final start = text.indexOf('```json') + 7;
      final end = text.indexOf('```', start);
      if (end > start) {
        text = text.substring(start, end).trim();
      }
    } else if (text.contains('```')) {
      // Try to extract content between any code fences
      final start = text.indexOf('```') + 3;
      // Skip language identifier on same line
      final lineEnd = text.indexOf('\n', start);
      final contentStart = lineEnd > 0 ? lineEnd + 1 : start;
      final end = text.indexOf('```', contentStart);
      if (end > contentStart) {
        text = text.substring(contentStart, end).trim();
      }
    }
    
    // Try to find JSON object by looking for { and }
    final firstBrace = text.indexOf('{');
    final lastBrace = text.lastIndexOf('}');
    
    if (firstBrace != -1 && lastBrace > firstBrace) {
      text = text.substring(firstBrace, lastBrace + 1);
    }
    
    // Validate it looks like JSON
    if (!text.startsWith('{') || !text.endsWith('}')) {
      throw FormatException(
        'Response does not contain valid JSON. Response starts with: ${text.substring(0, text.length > 50 ? 50 : text.length)}...'
      );
    }
    
    return text;
  }

  Future<void> _handleGenPdfCommand(String topic) async {
    // Check if API key is set
    if (!_geminiService.isInitialized) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Please set your API key first. Tap the ⚡ icon to add your key.',
            isUser: false,
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    try {
      // Step 1: Get JSON content from AI
      setState(() {
        _messages.add(
          ChatMessage(text: '📝 Generating PDF notes about "$topic"...', isUser: false),
        );
      });
      _scrollToBottom();

      final jsonResponse = await _geminiService.sendPDFRequest(topic);

      // Step 2: Extract and clean the JSON from response
      final cleanJson = _extractJsonFromResponse(jsonResponse);

      // Step 3: Parse JSON to PDFDocument
      final pdfDocument = PDFDocument.parse(cleanJson);

      // Step 4: Generate PDF bytes
      final pdfGenerator = PDFGeneratorService();
      final pdfBytes = await pdfGenerator.generatePDF(pdfDocument);

      // Step 5: Save PDF to documents directory (with fallback)
      Directory? directory;
      try {
        directory = await getApplicationDocumentsDirectory();
      } catch (_) {
        // Fallback to temporary directory if documents not available
        directory = await getTemporaryDirectory();
      }
      final fileName = '${topic.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // Step 6: Show PDF card in chat
      setState(() {
        _messages.add(
          ChatMessage(
            text: '✅ PDF generated successfully!',
            isUser: false,
            type: MessageType.pdf,
            pdfInfo: PdfInfo(
              title: pdfDocument.title,
              description: '${pdfDocument.metadata.subject} • ${pdfDocument.pages.length} pages',
              pages: pdfDocument.pages.length,
              url: filePath, // Use file path for local file
            ),
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: '❌ Failed to generate PDF: ${e.toString()}',
            isUser: false,
          ),
        );
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _openPdfViewer(PdfInfo pdfInfo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PdfViewerPage(pdfInfo: pdfInfo)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _apiKeyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatProfilePage()),
            );
          },
          child: const Text('Chat'),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showSettingsBottomSheet,
            icon: const Icon(Icons.flash_on),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Start a conversation',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return const _LoadingIndicator();
                      }
                      final message = _messages[index];
                      if (message.type == MessageType.pdf) {
                        return _PdfCard(
                          message: message,
                          onTap: () => _openPdfViewer(message.pdfInfo!),
                        );
                      }
                      return _MessageBubble(message: message);
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
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

// Loading indicator widget
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Thinking...'),
          ],
        ),
      ),
    );
  }
}

// Text message bubble widget
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

// PDF card widget for AI PDF responses
class _PdfCard extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onTap;

  const _PdfCard({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pdfInfo = message.pdfInfo!;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red.shade700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pdfInfo.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pdfInfo.description,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${pdfInfo.pages} pages',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.open_in_new,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// PDF Viewer Page
class PdfViewerPage extends StatefulWidget {
  final PdfInfo pdfInfo;

  const PdfViewerPage({super.key, required this.pdfInfo});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late PdfControllerPinch _pdfController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      Uint8List pdfBytes;

      if (widget.pdfInfo.url != null) {
        final path = widget.pdfInfo.url!;
        
        // Check if it's a local file path or a URL
        if (path.startsWith('http://') || path.startsWith('https://')) {
          // Download from URL
          pdfBytes = await _downloadPdf(path);
        } else {
          // Load from local file path
          final file = File(path);
          if (await file.exists()) {
            pdfBytes = await file.readAsBytes();
          } else {
            throw Exception('File not found: $path');
          }
        }
      } else if (widget.pdfInfo.assetPath != null) {
        // Load from asset
        final byteData = await rootBundle.load(widget.pdfInfo.assetPath!);
        pdfBytes = byteData.buffer.asUint8List();
      } else {
        throw Exception('No PDF source provided');
      }

      _pdfController = PdfControllerPinch(
        document: PdfDocument.openData(pdfBytes),
      );
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load PDF: $e';
        _isLoading = false;
      });
    }
  }

  Future<Uint8List> _downloadPdf(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download PDF: ${response.statusCode}');
    }
  }

  @override
  void dispose() {
    if (!_isLoading && _error == null) {
      _pdfController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pdfInfo.title), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Note: Please add a demo.pdf file to the assets folder.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : PdfViewPinch(
              controller: _pdfController,
              builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(),
                documentLoaderBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                pageLoaderBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, error) =>
                    Center(child: Text('Error: $error')),
              ),
            ),
    );
  }
}
