// JSON Schema models for AI-generated PDF content
//
// These models define the structure of JSON responses from the AI
// that can be converted into PDF documents.

import 'dart:convert';

/// Root document containing metadata and pages
class PDFDocument {
  final String title;
  final PDFMetadata metadata;
  final List<PDFPage> pages;

  PDFDocument({
    required this.title,
    required this.metadata,
    required this.pages,
  });

  factory PDFDocument.fromJson(Map<String, dynamic> json) {
    return PDFDocument(
      title: json['title'] as String? ?? 'Untitled Document',
      metadata: PDFMetadata.fromJson(json['metadata'] as Map<String, dynamic>? ?? {}),
      pages: (json['pages'] as List<dynamic>?)
              ?.map((p) => PDFPage.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Parse JSON string to PDFDocument
  static PDFDocument parse(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return PDFDocument.fromJson(json);
  }
}

/// Document metadata
class PDFMetadata {
  final String subject;
  final int totalPages;
  final String? difficulty;
  final String? author;

  PDFMetadata({
    required this.subject,
    required this.totalPages,
    this.difficulty,
    this.author,
  });

  factory PDFMetadata.fromJson(Map<String, dynamic> json) {
    return PDFMetadata(
      subject: json['subject'] as String? ?? 'General',
      totalPages: json['pages'] as int? ?? json['totalPages'] as int? ?? 1,
      difficulty: json['difficulty'] as String?,
      author: json['author'] as String?,
    );
  }
}

/// Single page containing sections
class PDFPage {
  final int pageNumber;
  final List<PDFSection> sections;

  PDFPage({
    required this.pageNumber,
    required this.sections,
  });

  factory PDFPage.fromJson(Map<String, dynamic> json) {
    final sectionsJson = json['sections'] as List<dynamic>? ?? [];
    return PDFPage(
      pageNumber: json['pageNumber'] as int? ?? 1,
      sections: sectionsJson
          .map((s) => PDFSection.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Base class for all section types
abstract class PDFSection {
  final String type;

  PDFSection({required this.type});

  factory PDFSection.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'paragraph';

    switch (type) {
      case 'heading':
        return PDFHeading.fromJson(json);
      case 'paragraph':
        return PDFParagraph.fromJson(json);
      case 'bulletList':
        return PDFBulletList.fromJson(json);
      case 'numberedList':
        return PDFNumberedList.fromJson(json);
      case 'table':
        return PDFTable.fromJson(json);
      case 'codeBlock':
        return PDFCodeBlock.fromJson(json);
      case 'quote':
        return PDFQuote.fromJson(json);
      case 'divider':
        return PDFDivider();
      default:
        // Default to paragraph for unknown types
        return PDFParagraph(content: json['content']?.toString() ?? '');
    }
  }
}

/// Heading section (H1, H2, H3)
class PDFHeading extends PDFSection {
  final int level; // 1, 2, or 3
  final String content;

  PDFHeading({
    required this.level,
    required this.content,
  }) : super(type: 'heading');

  factory PDFHeading.fromJson(Map<String, dynamic> json) {
    return PDFHeading(
      level: json['level'] as int? ?? 1,
      content: json['content'] as String? ?? '',
    );
  }
}

/// Paragraph text section
class PDFParagraph extends PDFSection {
  final String content;

  PDFParagraph({required this.content}) : super(type: 'paragraph');

  factory PDFParagraph.fromJson(Map<String, dynamic> json) {
    return PDFParagraph(
      content: json['content'] as String? ?? '',
    );
  }
}

/// Bullet (unordered) list
class PDFBulletList extends PDFSection {
  final List<String> items;

  PDFBulletList({required this.items}) : super(type: 'bulletList');

  factory PDFBulletList.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return PDFBulletList(
      items: itemsList.map((i) => i.toString()).toList(),
    );
  }
}

/// Numbered (ordered) list
class PDFNumberedList extends PDFSection {
  final List<String> items;

  PDFNumberedList({required this.items}) : super(type: 'numberedList');

  factory PDFNumberedList.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return PDFNumberedList(
      items: itemsList.map((i) => i.toString()).toList(),
    );
  }
}

/// Table with headers and rows
class PDFTable extends PDFSection {
  final List<String> headers;
  final List<List<String>> rows;

  PDFTable({
    required this.headers,
    required this.rows,
  }) : super(type: 'table');

  factory PDFTable.fromJson(Map<String, dynamic> json) {
    final headersList = json['headers'] as List<dynamic>? ?? [];
    final rowsList = json['rows'] as List<dynamic>? ?? [];

    return PDFTable(
      headers: headersList.map((h) => h.toString()).toList(),
      rows: rowsList
          .map((row) =>
              (row as List<dynamic>).map((cell) => cell.toString()).toList())
          .toList(),
    );
  }
}

/// Code block with optional language
class PDFCodeBlock extends PDFSection {
  final String code;
  final String? language;

  PDFCodeBlock({
    required this.code,
    this.language,
  }) : super(type: 'codeBlock');

  factory PDFCodeBlock.fromJson(Map<String, dynamic> json) {
    return PDFCodeBlock(
      code: json['code'] as String? ?? '',
      language: json['language'] as String?,
    );
  }
}

/// Blockquote section
class PDFQuote extends PDFSection {
  final String content;

  PDFQuote({required this.content}) : super(type: 'quote');

  factory PDFQuote.fromJson(Map<String, dynamic> json) {
    return PDFQuote(
      content: json['content'] as String? ?? '',
    );
  }
}

/// Horizontal divider/section break
class PDFDivider extends PDFSection {
  PDFDivider() : super(type: 'divider');
}
