import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/gemini_service.dart';

class ModelSelectionSheet extends StatefulWidget {
  final List<String> availableModels;
  final Function(String model, String topic) onGenerate;

  const ModelSelectionSheet({
    super.key,
    required this.availableModels,
    required this.onGenerate,
  });

  @override
  State<ModelSelectionSheet> createState() => _ModelSelectionSheetState();
}

class _ModelSelectionSheetState extends State<ModelSelectionSheet> {
  late String _selectedModel;
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  bool _hasApiKey = false;
  bool _isLoadingApiKey = true;
  bool _showApiKeyField = false;

  @override
  void initState() {
    super.initState();
    if (widget.availableModels.isNotEmpty) {
      _selectedModel = widget.availableModels.first;
    } else {
      _selectedModel = 'gemini-2.0-flash-exp'; // Fallback
    }
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    final service = GeminiService();
    await service.init();
    final keys = service.getApiKeys();
    if (mounted) {
      setState(() {
        _hasApiKey = keys.isNotEmpty && service.activeKeyId != null;
        _isLoadingApiKey = false;
        _showApiKeyField = !_hasApiKey;
      });
    }
  }

  Future<void> _saveApiKey() async {
    if (_apiKeyController.text.trim().isEmpty) return;
    
    await GeminiService().addApiKey(_apiKeyController.text.trim(), 'My API Key');
    await _checkApiKey();
    
    if (mounted) {
      setState(() {
        _showApiKeyField = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API Key saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _handleGenerate() {
    if (!_hasApiKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add your API key first'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_topicController.text.trim().isNotEmpty) {
      Navigator.pop(context);
      widget.onGenerate(_selectedModel, _topicController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.flash_on, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Generate PDF',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // API Key Section
            _buildApiKeySection(),
            
            const SizedBox(height: 24),
            
            const Text(
              'Select Model',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.availableModels.map((model) {
                  final isSelected = _selectedModel == model;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(model),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() => _selectedModel = model);
                        }
                      },
                      backgroundColor: AppColors.background,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.surfaceHighlight,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 24),
            TextField(
              controller: _topicController,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                labelText: 'Topic or Prompt',
                hintText: 'e.g. Explain Quantum Physics in simple terms',
                alignLabelWithHint: true,
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _handleGenerate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Generate & Send',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeySection() {
    if (_isLoadingApiKey) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasApiKey ? AppColors.success.withValues(alpha: 0.5) : AppColors.surfaceHighlight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _hasApiKey ? Icons.check_circle : Icons.vpn_key,
                color: _hasApiKey ? AppColors.success : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _hasApiKey ? 'API Key Connected' : 'Add Your API Key',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _hasApiKey ? AppColors.success : AppColors.textPrimary,
                  ),
                ),
              ),
              if (_hasApiKey)
                TextButton(
                  onPressed: () => setState(() => _showApiKeyField = !_showApiKeyField),
                  child: Text(
                    _showApiKeyField ? 'Hide' : 'Change',
                    style: const TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                ),
            ],
          ),
          if (!_hasApiKey)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Enter your Gemini API key to start generating PDFs',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          if (_showApiKeyField) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              style: const TextStyle(color: AppColors.textPrimary),
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Paste your Gemini API key here',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.surfaceHighlight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveApiKey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save API Key',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
