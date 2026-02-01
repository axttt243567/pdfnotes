import 'package:flutter/material.dart';
import '../app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.availableModels.isNotEmpty) {
      _selectedModel = widget.availableModels.first;
    } else {
      _selectedModel = 'gemini-2.0-flash-exp'; // Fallback
    }
  }

  void _handleGenerate() {
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
    );
  }
}
