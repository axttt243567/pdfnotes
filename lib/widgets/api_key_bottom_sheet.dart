import 'package:flutter/material.dart';
import '../app_theme.dart';

class ApiKeyBottomSheet extends StatefulWidget {
  final Function(String key, String alias) onSave;

  const ApiKeyBottomSheet({super.key, required this.onSave});

  @override
  State<ApiKeyBottomSheet> createState() => _ApiKeyBottomSheetState();
}

class _ApiKeyBottomSheetState extends State<ApiKeyBottomSheet> {
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _aliasController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _keyController.dispose();
    _aliasController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_keyController.text.isNotEmpty && _aliasController.text.isNotEmpty) {
      setState(() => _isLoading = true);
      
      // Simulate a brief validation/save delay if needed, 
      // or just call the callback immediately.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
            widget.onSave(_keyController.text, _aliasController.text);
            Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handling keyboard visibility
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Gemini API Key',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _aliasController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Key Alias (e.g., Personal Pro)',
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
          const SizedBox(height: 16),
          TextField(
            controller: _keyController,
            style: const TextStyle(color: AppColors.textPrimary),
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'API Key',
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
            onPressed: _isLoading ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save Key',
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
