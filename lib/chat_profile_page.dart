import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pdf_storage.dart';
import 'main.dart';

/// Demo showcase item with prompt and PDF info
class DemoShowcase {
  final String title;
  final String description;
  final String prompt;
  final String? assetPath;

  const DemoShowcase({
    required this.title,
    required this.description,
    required this.prompt,
    this.assetPath,
  });
}

/// Chat Profile Page - Telegram-style profile with PDF management
class ChatProfilePage extends StatefulWidget {
  const ChatProfilePage({super.key});

  @override
  State<ChatProfilePage> createState() => _ChatProfilePageState();
}

class _ChatProfilePageState extends State<ChatProfilePage> {
  List<PDFFileInfo> _pdfFiles = [];
  bool _isLoading = true;

  // Demo showcase items
  final List<DemoShowcase> _demoItems = const [
    DemoShowcase(
      title: 'Introduction to Machine Learning',
      description: 'Comprehensive notes covering ML fundamentals, algorithms, and applications',
      prompt: '#genpdf Introduction to Machine Learning with examples of supervised and unsupervised learning',
      assetPath: null, // Will use generated PDF in future
    ),
    DemoShowcase(
      title: 'Flutter State Management',
      description: 'Guide to state management patterns in Flutter apps',
      prompt: '#genpdf Flutter State Management - Provider, Riverpod, and BLoC patterns explained',
      assetPath: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadPDFs();
  }

  Future<void> _loadPDFs() async {
    setState(() => _isLoading = true);
    final pdfs = await PDFStorageService.getSavedPDFs();
    setState(() {
      _pdfFiles = pdfs;
      _isLoading = false;
    });
  }

  Future<void> _deletePDF(PDFFileInfo pdf) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete PDF'),
        content: Text('Are you sure you want to delete "${pdf.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await PDFStorageService.deletePDF(pdf.path);
      if (success) {
        _loadPDFs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF deleted')),
          );
        }
      }
    }
  }

  void _openPDF(PDFFileInfo pdf) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(
          pdfInfo: PdfInfo(
            title: pdf.name,
            description: '${pdf.formattedSize} • ${pdf.formattedDate}',
            pages: 0,
            url: pdf.path,
          ),
        ),
      ),
    );
  }

  void _showDemoDetails(DemoShowcase demo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 20),
            
            // Title
            Text(
              demo.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Description
            Text(
              demo.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            
            // Prompt section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.code, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Prompt Used',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    demo.prompt,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Copy prompt button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: demo.prompt));
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Prompt copied! Paste in chat to generate.')),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Prompt'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPDFs,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Section
              _buildAvatarSection(),

              // Demo Showcase Section
              _buildSectionHeader(
                icon: Icons.lightbulb_outline,
                iconColor: Colors.amber.shade600,
                title: 'Demo Showcase',
                subtitle: 'Learn with examples',
              ),
              const Divider(height: 1),
              _buildDemoShowcaseList(),

              const SizedBox(height: 16),

              // Generated PDFs Section
              _buildSectionHeader(
                icon: Icons.picture_as_pdf,
                iconColor: Colors.red.shade400,
                title: 'Generated PDFs',
                subtitle: '${_pdfFiles.length} files',
              ),
              const Divider(height: 1),
              _buildGeneratedPDFsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'AI Assistant',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'PDF Generator Bot',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDemoShowcaseList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _demoItems.length,
      itemBuilder: (context, index) {
        final demo = _demoItems[index];
        return _buildDemoTile(demo);
      },
    );
  }

  Widget _buildDemoTile(DemoShowcase demo) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.auto_awesome,
          color: Colors.amber.shade600,
          size: 28,
        ),
      ),
      title: Text(
        demo.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        demo.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: () => _showDemoDetails(demo),
    );
  }

  Widget _buildGeneratedPDFsList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_pdfFiles.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _pdfFiles.length,
      itemBuilder: (context, index) {
        final pdf = _pdfFiles[index];
        return _buildPDFTile(pdf);
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 60,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'No PDFs yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Use #genpdf [topic] to generate PDFs',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPDFTile(PDFFileInfo pdf) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.picture_as_pdf,
          color: Colors.red.shade400,
          size: 28,
        ),
      ),
      title: Text(
        pdf.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${pdf.formattedSize} • ${pdf.formattedDate}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline, color: Colors.grey.shade400),
        onPressed: () => _deletePDF(pdf),
      ),
      onTap: () => _openPDF(pdf),
    );
  }
}
