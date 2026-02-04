// PDF Generator Service
//
// Converts PDFDocument models into actual PDF files using the `pdf` package.

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_schema.dart';

/// Service to generate PDF documents from parsed JSON content
class PDFGeneratorService {
  // Theme colors
  static const PdfColor _primaryColor = PdfColor.fromInt(0xFF1565C0);
  static const PdfColor _accentColor = PdfColor.fromInt(0xFF42A5F5);
  static const PdfColor _textColor = PdfColor.fromInt(0xFF212121);
  static const PdfColor _mutedColor = PdfColor.fromInt(0xFF757575);
  static const PdfColor _bgLight = PdfColor.fromInt(0xFFF5F5F5);

  /// Generate PDF bytes from a PDFDocument
  Future<Uint8List> generatePDF(PDFDocument document) async {
    final pdf = pw.Document(
      title: document.title,
      author: document.metadata.author ?? 'AI PDF Generator',
      subject: document.metadata.subject,
    );

    // Process each page
    for (final page in document.pages) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _buildHeader(document, context),
          footer: (context) => _buildFooter(context),
          build: (context) => _buildPageContent(page),
        ),
      );
    }

    return pdf.save();
  }

  /// Build header for each page
  pw.Widget _buildHeader(PDFDocument document, pw.Context context) {
    if (context.pageNumber == 1) {
      // Title page header
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            document.title,
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            document.metadata.subject,
            style: pw.TextStyle(
              fontSize: 14,
              color: _mutedColor,
            ),
          ),
          pw.Divider(color: _accentColor, thickness: 2),
          pw.SizedBox(height: 20),
        ],
      );
    }
    // Subsequent pages - simple header
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            document.title,
            style: pw.TextStyle(
              fontSize: 10,
              color: _mutedColor,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          pw.Text(
            document.metadata.subject,
            style: pw.TextStyle(
              fontSize: 10,
              color: _mutedColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Build footer with page numbers
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(
          fontSize: 10,
          color: _mutedColor,
        ),
      ),
    );
  }

  /// Build content for a single page
  List<pw.Widget> _buildPageContent(PDFPage page) {
    final widgets = <pw.Widget>[];

    for (final section in page.sections) {
      widgets.add(_renderSection(section));
      widgets.add(pw.SizedBox(height: 12)); // Spacing between sections
    }

    return widgets;
  }

  /// Render a section based on its type
  pw.Widget _renderSection(PDFSection section) {
    if (section is PDFHeading) {
      return _renderHeading(section);
    } else if (section is PDFParagraph) {
      return _renderParagraph(section);
    } else if (section is PDFBulletList) {
      return _renderBulletList(section);
    } else if (section is PDFNumberedList) {
      return _renderNumberedList(section);
    } else if (section is PDFTable) {
      return _renderTable(section);
    } else if (section is PDFCodeBlock) {
      return _renderCodeBlock(section);
    } else if (section is PDFQuote) {
      return _renderQuote(section);
    } else if (section is PDFDivider) {
      return _renderDivider();
    } else {
      // Fallback for unknown types
      return pw.Container();
    }
  }

  /// Render heading (H1, H2, H3)
  pw.Widget _renderHeading(PDFHeading section) {
    double fontSize;
    pw.FontWeight fontWeight;
    PdfColor color;

    switch (section.level) {
      case 1:
        fontSize = 22;
        fontWeight = pw.FontWeight.bold;
        color = _primaryColor;
        break;
      case 2:
        fontSize = 18;
        fontWeight = pw.FontWeight.bold;
        color = _textColor;
        break;
      case 3:
      default:
        fontSize = 14;
        fontWeight = pw.FontWeight.bold;
        color = _textColor;
        break;
    }

    return pw.Container(
      margin: pw.EdgeInsets.only(top: section.level == 1 ? 8 : 4),
      child: pw.Text(
        section.content,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ),
    );
  }

  /// Render paragraph text
  pw.Widget _renderParagraph(PDFParagraph section) {
    return pw.Text(
      section.content,
      style: pw.TextStyle(
        fontSize: 11,
        color: _textColor,
        lineSpacing: 4,
      ),
      textAlign: pw.TextAlign.justify,
    );
  }

  /// Render bullet list
  pw.Widget _renderBulletList(PDFBulletList section) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: section.items.map((item) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 4,
                height: 4,
                margin: const pw.EdgeInsets.only(top: 5, right: 8),
                decoration: const pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: _primaryColor,
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  item,
                  style: pw.TextStyle(fontSize: 11, color: _textColor),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Render numbered list
  pw.Widget _renderNumberedList(PDFNumberedList section) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: section.items.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final item = entry.value;
        return pw.Padding(
          padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 20,
                margin: const pw.EdgeInsets.only(right: 8),
                child: pw.Text(
                  '$index.',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  item,
                  style: pw.TextStyle(fontSize: 11, color: _textColor),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Render table
  pw.Widget _renderTable(PDFTable section) {
    // Create header row
    final headerCells = section.headers.map((header) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        color: _primaryColor,
        child: pw.Text(
          header,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      );
    }).toList();

    // Create data rows
    final dataRows = section.rows.asMap().entries.map((entry) {
      final rowIndex = entry.key;
      final row = entry.value;
      final isEvenRow = rowIndex % 2 == 0;
      
      return pw.TableRow(
        children: row.map((cell) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(8),
            color: isEvenRow ? _bgLight : PdfColors.white,
            child: pw.Text(
              cell,
              style: pw.TextStyle(fontSize: 10, color: _textColor),
            ),
          );
        }).toList(),
      );
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(children: headerCells),
        ...dataRows,
      ],
    );
  }

  /// Render code block
  pw.Widget _renderCodeBlock(PDFCodeBlock section) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFF263238),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (section.language != null)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                section.language!.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 8,
                  color: const PdfColor.fromInt(0xFF80CBC4),
                ),
              ),
            ),
          pw.Text(
            section.code,
            style: pw.TextStyle(
              fontSize: 9,
              color: const PdfColor.fromInt(0xFFECEFF1),
              fontWeight: pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// Render blockquote
  pw.Widget _renderQuote(PDFQuote section) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: _accentColor, width: 4),
        ),
        color: _bgLight,
      ),
      child: pw.Text(
        section.content,
        style: pw.TextStyle(
          fontSize: 11,
          color: _mutedColor,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }

  /// Render horizontal divider
  pw.Widget _renderDivider() {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Divider(
        color: PdfColors.grey300,
        thickness: 1,
      ),
    );
  }
}
