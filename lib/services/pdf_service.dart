import 'dart:convert';
import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class PdfService {
  Future<void> generatePdf(String jsonContent) async {
    try {
      final data = json.decode(jsonContent);
      final pdf = pw.Document();

      // Load a custom font if available, otherwise use standard
      // For now, we'll use standard fonts to ensure compatibility
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader(data['title'] ?? 'Generated Notes'),
              pw.SizedBox(height: 20),
              ..._buildSections(data['sections'] ?? []),
            ];
          },
        ),
      );

      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/notes_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      await OpenFile.open(file.path);
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }

  pw.Widget _buildHeader(String title) {
    return pw.Header(
      level: 0,
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue, // Using a standard blue close to AppColors.primary
        ),
      ),
    );
  }

  List<pw.Widget> _buildSections(List<dynamic> sections) {
    List<pw.Widget> widgets = [];

    for (var section in sections) {
      if (section['heading'] != null) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
            child: pw.Text(
              section['heading'],
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ),
        );
      }

      if (section['content'] != null) {
        widgets.add(
          pw.Paragraph(
            text: section['content'],
            style: const pw.TextStyle(
              fontSize: 12,
              lineSpacing: 1.5,
              color: PdfColors.grey800,
            ),
          ),
        );
      }

      if (section['points'] != null) {
        final points = section['points'] as List;
        for (var point in points) {
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   pw.Container(
                    width: 4,
                    height: 4,
                    margin: const pw.EdgeInsets.only(top: 6, right: 8),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      point.toString(),
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    return widgets;
  }
}
