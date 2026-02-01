import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../widgets/api_key_bottom_sheet.dart';
import '../services/gemini_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Data
  List<Map<String, String>> _apiKeys = [];
  String? _selectedKeyId;
  List<String> _preferredModels = [];

  String _maskKey(String key) {
    if (key.length <= 8) return '****';
    return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
  }

  // Model Configuration
  final Map<String, String> _availableModels = {
    'Gemini 1.5 Flash': 'gemini-1.5-flash',
    'Gemini 1.5 Pro': 'gemini-1.5-pro',
    'Gemini 2.0 Flash Exp': 'gemini-2.0-flash-exp',
  };

  // App Settings
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = GeminiService();
    // Ensure service is initialized if not already (it usually is by main)
    await service.init();
    
    if (mounted) {
      setState(() {
        _apiKeys = service.getApiKeys();
        _selectedKeyId = service.activeKeyId;
        _preferredModels = service.getPreferredModels();
      });
    }
  }

  void _addNewKey(String key, String alias) async {
      await GeminiService().addApiKey(key, alias);
      _loadData();
  }

  void _deleteKey(String id) async {
    await GeminiService().removeApiKey(id);
    _loadData();
  }

  void _selectKey(String id) async {
    await GeminiService().selectApiKey(id);
    _loadData();
  }

  void _toggleModel(String model) async {
    await GeminiService().togglePreferredModel(model);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... (existing scaffold props)
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Gemini API Keys'),
            const SizedBox(height: 16),
            if (_apiKeys.isEmpty)
                const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text("No API keys added yet.", style: TextStyle(color: AppColors.textSecondary)),
                ),
            ..._apiKeys.map(_buildApiKeyItem),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                    showModalBottomSheet(
                        context: context, 
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => ApiKeyBottomSheet(
                            onSave: (key, alias) => _addNewKey(key, alias),
                        ),
                    );
                },
                icon: const Icon(Icons.add, color: AppColors.primary),
                label: const Text('Add New Key', style: TextStyle(color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.surfaceHighlight),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            // Section 2: Choose Preferred Models
            _buildSectionHeader('Preferred Models'),
            const Text(
                'Select models to be available in the chat menu.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _availableModels.entries.map((entry) {
                final isSelected = _preferredModels.contains(entry.value);
                return FilterChip(
                  label: Text(entry.key),
                  selected: isSelected,
                  onSelected: (bool selected) => _toggleModel(entry.value),
                  backgroundColor: AppColors.surface,
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
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            // Section 3: App Settings
            _buildSectionHeader('App Settings'),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Notifications',
              'Receive updates and generation alerts',
              _notifications,
              (val) => setState(() => _notifications = val),
            ),

            const SizedBox(height: 32),
            // Section 4: About
            _buildSectionHeader('About'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceHighlight),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.auto_stories, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gen AI Notes',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Version 1.0.0',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.surfaceHighlight),
                  _buildLinkItem('Privacy Policy'),
                  _buildLinkItem('Terms of Service'),
                  _buildLinkItem('Open Source Licenses'),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildApiKeyItem(Map<String, String> keyData) {
    bool isActive = keyData['id'] == _selectedKeyId;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: AppColors.primary, width: 1.5)
            : Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        children: [
            Row(
                children: [
                Icon(
                    Icons.vpn_key,
                    color: isActive ? AppColors.primary : AppColors.textTertiary,
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                                keyData['alias'] ?? 'Unknown',
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                ),
                            ),
                            Text(
                                _maskKey(keyData['key'] ?? ''),
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                ),
                            ),
                        ],
                    ),
                ),
                if (isActive)
                    const Icon(Icons.check_circle, color: AppColors.success)
                else
                    Radio<String>(
                        value: keyData['id']!,
                        groupValue: _selectedKeyId,
                        onChanged: (val) => _selectKey(val!),
                        activeColor: AppColors.primary,
                    ),
                ],
            ),
            if (!isActive) ...[
                const Divider(color: AppColors.surfaceHighlight),
                Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                        onPressed: () => _deleteKey(keyData['id']!),
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                        label: const Text('Remove', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                ),
            ]
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.textTertiary,
            inactiveTrackColor: AppColors.surfaceHighlight,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Icon(Icons.open_in_new, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}
