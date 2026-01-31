import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../widgets/api_key_bottom_sheet.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Mock Data
  final List<Map<String, dynamic>> _apiKeys = [
    {'key': 'sk-proj...A1b2', 'alias': 'Personal Key', 'active': true},
    {'key': 'sk-proj...9XzQ', 'alias': 'Work Project', 'active': false},
  ];

  // Model Configuration
  final List<String> _availableModels = [
    'Gemini 1.5 Pro',
    'Gemini 1.5 Flash',
    'Gemini 1.0 Pro',
    'Gemini Ultra'
  ];
  final List<String> _selectedModels = ['Gemini 1.5 Pro'];

  // App Settings
  bool _notifications = true;

  void _openAddKeySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ApiKeyBottomSheet(
        onSave: (key, alias) {
          setState(() {
            _apiKeys.add({'key': key, 'alias': alias, 'active': false});
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Gemini API Keys
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gemini API Keys',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        // TODO: Implement Learn More navigation
                      },
                      child: const Text('Learn More'),
                    ),
                    TextButton(
                      onPressed: _openAddKeySheet,
                      child: const Text('Add Key'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._apiKeys.map((key) => _buildApiKeyItem(key)),

            const SizedBox(height: 32),
            // Section 2: Choose Preferred Models
            _buildSectionHeader('Choose Preferred Models'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _availableModels.map((model) {
                final isSelected = _selectedModels.contains(model);
                return FilterChip(
                  label: Text(model),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedModels.add(model);
                      } else {
                        if (_selectedModels.length > 1) {
                            _selectedModels.remove(model);
                        }
                      }
                    });
                  },
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

  Widget _buildApiKeyItem(Map<String, dynamic> keyData) {
    bool isActive = keyData['active'];
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
      child: Row(
        children: [
          Icon(
            Icons.vpn_key,
            color: isActive ? AppColors.primary : AppColors.textTertiary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
                keyData['alias'],
                style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                ),
            ),
          ),
          if (isActive)
            const Icon(Icons.check_circle, color: AppColors.success)
          else
            TextButton(
              onPressed: () {
                 setState(() {
                     for (var key in _apiKeys) {
                         key['active'] = false;
                     }
                     keyData['active'] = true;
                 });
              },
              child: const Text('Select'),
            )
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
