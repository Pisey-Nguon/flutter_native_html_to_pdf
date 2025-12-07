import 'dart:io';
import 'dart:typed_data';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_page_size.dart';

/// Pure Dart HTML to PDF converter with no native code dependencies
class HtmlToPdfConverter {
  /// Converts HTML content to a PDF file
  Future<File?> convertHtmlToPdf({
    required String html,
    required String targetDirectory,
    required String targetName,
    PdfPageSize? pageSize,
  }) async {
    final pdfBytes = await convertHtmlToPdfBytes(
      html: html,
      pageSize: pageSize,
    );
    
    if (pdfBytes == null) return null;
    
    final filePath = '$targetDirectory/$targetName.pdf';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  /// Converts HTML content to PDF bytes
  Future<Uint8List?> convertHtmlToPdfBytes({
    required String html,
    PdfPageSize? pageSize,
  }) async {
    try {
      // Parse HTML
      final document = html_parser.parse(html);
      
      // Create PDF document
      final pdf = pw.Document();
      
      // Get page format
      final format = _getPdfPageFormat(pageSize);
      
      // Convert HTML body to PDF widgets
      final widgets = _convertNodesToPdfWidgets(document.body?.nodes ?? []);
      
      // Add page with content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: format,
          build: (context) => widgets,
        ),
      );
      
      return await pdf.save();
    } catch (e) {
      print('Error converting HTML to PDF: $e');
      return null;
    }
  }

  /// Get PDF page format from PdfPageSize
  PdfPageFormat _getPdfPageFormat(PdfPageSize? pageSize) {
    if (pageSize == null) return PdfPageFormat.a4;
    
    return PdfPageFormat(
      pageSize.width,
      pageSize.height,
    );
  }

  /// Convert HTML nodes to PDF widgets
  List<pw.Widget> _convertNodesToPdfWidgets(List<dom.Node> nodes) {
    final widgets = <pw.Widget>[];
    
    for (final node in nodes) {
      if (node is dom.Element) {
        final widget = _convertElementToPdfWidget(node);
        if (widget != null) {
          widgets.add(widget);
        }
      } else if (node is dom.Text) {
        final text = node.text.trim();
        if (text.isNotEmpty) {
          widgets.add(pw.Text(text));
        }
      }
    }
    
    return widgets;
  }

  /// Convert HTML element to PDF widget
  pw.Widget? _convertElementToPdfWidget(dom.Element element) {
    final tagName = element.localName?.toLowerCase() ?? '';
    
    switch (tagName) {
      case 'h1':
        return _createHeading(element, 24, pw.FontWeight.bold);
      case 'h2':
        return _createHeading(element, 20, pw.FontWeight.bold);
      case 'h3':
        return _createHeading(element, 18, pw.FontWeight.bold);
      case 'h4':
        return _createHeading(element, 16, pw.FontWeight.bold);
      case 'h5':
        return _createHeading(element, 14, pw.FontWeight.bold);
      case 'h6':
        return _createHeading(element, 12, pw.FontWeight.bold);
      case 'p':
        return _createParagraph(element);
      case 'div':
        return _createDiv(element);
      case 'span':
        return _createSpan(element);
      case 'strong':
      case 'b':
        return _createBold(element);
      case 'em':
      case 'i':
        return _createItalic(element);
      case 'u':
        return _createUnderline(element);
      case 'br':
        return pw.SizedBox(height: 10);
      case 'hr':
        return pw.Divider();
      case 'ul':
      case 'ol':
        return _createList(element, tagName == 'ol');
      case 'li':
        return _createListItem(element);
      case 'a':
        return _createLink(element);
      case 'img':
        // Images are complex in pure Dart, skip for now
        return pw.Text('[Image: ${element.attributes['alt'] ?? 'image'}]');
      case 'table':
        return _createTable(element);
      default:
        // For unknown elements, process their children
        final children = _convertNodesToPdfWidgets(element.nodes);
        return children.isEmpty ? null : pw.Column(children: children);
    }
  }

  /// Create heading widget
  pw.Widget _createHeading(dom.Element element, double size, pw.FontWeight weight) {
    final text = _extractText(element);
    final color = _getColor(element);
    
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10, bottom: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: size,
          fontWeight: weight,
          color: color,
        ),
      ),
    );
  }

  /// Create paragraph widget
  pw.Widget _createParagraph(dom.Element element) {
    final children = _convertInlineNodesToPdfTextSpans(element.nodes);
    final color = _getColor(element);
    final fontSize = _getFontSize(element);
    
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.RichText(
        text: pw.TextSpan(
          children: children,
          style: pw.TextStyle(
            fontSize: fontSize,
            color: color,
          ),
        ),
      ),
    );
  }

  /// Create div widget
  pw.Widget _createDiv(dom.Element element) {
    final children = _convertNodesToPdfWidgets(element.nodes);
    if (children.isEmpty) return pw.SizedBox();
    
    final backgroundColor = _getBackgroundColor(element);
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      decoration: backgroundColor != null
          ? pw.BoxDecoration(color: backgroundColor)
          : null,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  /// Create span widget
  pw.Widget _createSpan(dom.Element element) {
    final text = _extractText(element);
    final color = _getColor(element);
    final backgroundColor = _getBackgroundColor(element);
    
    return pw.Container(
      padding: backgroundColor != null ? const pw.EdgeInsets.all(2) : null,
      decoration: backgroundColor != null
          ? pw.BoxDecoration(color: backgroundColor)
          : null,
      child: pw.Text(
        text,
        style: pw.TextStyle(color: color),
      ),
    );
  }

  /// Create bold text widget
  pw.Widget _createBold(dom.Element element) {
    final text = _extractText(element);
    final color = _getColor(element);
    
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: color,
      ),
    );
  }

  /// Create italic text widget
  pw.Widget _createItalic(dom.Element element) {
    final text = _extractText(element);
    final color = _getColor(element);
    
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontStyle: pw.FontStyle.italic,
        color: color,
      ),
    );
  }

  /// Create underline text widget
  pw.Widget _createUnderline(dom.Element element) {
    final text = _extractText(element);
    final color = _getColor(element);
    
    return pw.Text(
      text,
      style: pw.TextStyle(
        decoration: pw.TextDecoration.underline,
        color: color,
      ),
    );
  }

  /// Create list widget
  pw.Widget _createList(dom.Element element, bool ordered) {
    final items = <pw.Widget>[];
    var index = 1;
    
    for (final child in element.children) {
      if (child.localName?.toLowerCase() == 'li') {
        final text = _extractText(child);
        final bullet = ordered ? '$index. ' : '• ';
        items.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 20, bottom: 5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(bullet),
                pw.Expanded(child: pw.Text(text)),
              ],
            ),
          ),
        );
        index++;
      }
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items,
    );
  }

  /// Create list item widget
  pw.Widget _createListItem(dom.Element element) {
    final text = _extractText(element);
    return pw.Text(text);
  }

  /// Create link widget
  pw.Widget _createLink(dom.Element element) {
    final text = _extractText(element);
    final href = element.attributes['href'] ?? '';
    
    return pw.Text(
      text,
      style: pw.TextStyle(
        color: PdfColors.blue,
        decoration: pw.TextDecoration.underline,
      ),
    );
  }

  /// Create table widget
  pw.Widget _createTable(dom.Element element) {
    final rows = <pw.TableRow>[];
    
    for (final row in element.children) {
      if (row.localName?.toLowerCase() == 'tr') {
        final cells = <pw.Widget>[];
        for (final cell in row.children) {
          if (cell.localName?.toLowerCase() == 'td' ||
              cell.localName?.toLowerCase() == 'th') {
            final text = _extractText(cell);
            final isHeader = cell.localName?.toLowerCase() == 'th';
            cells.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  text,
                  style: pw.TextStyle(
                    fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
                  ),
                ),
              ),
            );
          }
        }
        if (cells.isNotEmpty) {
          rows.add(pw.TableRow(children: cells));
        }
      }
    }
    
    return pw.Table(
      border: pw.TableBorder.all(),
      children: rows,
    );
  }

  /// Convert inline nodes to text spans
  List<pw.TextSpan> _convertInlineNodesToPdfTextSpans(List<dom.Node> nodes) {
    final spans = <pw.TextSpan>[];
    
    for (final node in nodes) {
      if (node is dom.Text) {
        final text = node.text;
        if (text.isNotEmpty) {
          spans.add(pw.TextSpan(text: text));
        }
      } else if (node is dom.Element) {
        final tagName = node.localName?.toLowerCase() ?? '';
        final text = _extractText(node);
        final color = _getColor(node);
        
        pw.TextStyle? style;
        switch (tagName) {
          case 'strong':
          case 'b':
            style = pw.TextStyle(fontWeight: pw.FontWeight.bold, color: color);
            break;
          case 'em':
          case 'i':
            style = pw.TextStyle(fontStyle: pw.FontStyle.italic, color: color);
            break;
          case 'u':
            style = pw.TextStyle(decoration: pw.TextDecoration.underline, color: color);
            break;
          case 'a':
            style = pw.TextStyle(
              color: PdfColors.blue,
              decoration: pw.TextDecoration.underline,
            );
            break;
          default:
            style = pw.TextStyle(color: color);
        }
        
        spans.add(pw.TextSpan(text: text, style: style));
      }
    }
    
    return spans;
  }

  /// Extract text content from element
  String _extractText(dom.Element element) {
    return element.text;
  }

  /// Get color from element style
  PdfColor? _getColor(dom.Element element) {
    final style = element.attributes['style'];
    if (style == null) return null;
    
    // Parse color from style attribute
    final colorMatch = RegExp(r'color:\s*([^;]+)').firstMatch(style);
    if (colorMatch != null) {
      return _parseColor(colorMatch.group(1)?.trim() ?? '');
    }
    
    return null;
  }

  /// Get background color from element style
  PdfColor? _getBackgroundColor(dom.Element element) {
    final style = element.attributes['style'];
    if (style == null) return null;
    
    // Parse background-color from style attribute
    final colorMatch = RegExp(r'background-color:\s*([^;]+)').firstMatch(style);
    if (colorMatch != null) {
      return _parseColor(colorMatch.group(1)?.trim() ?? '');
    }
    
    return null;
  }

  /// Get font size from element style
  double _getFontSize(dom.Element element) {
    final style = element.attributes['style'];
    if (style == null) return 12;
    
    // Parse font-size from style attribute (supports px, pt, em, and unitless)
    final sizeMatch = RegExp(r'font-size:\s*([\d.]+)(?:px|pt|em)?').firstMatch(style);
    if (sizeMatch != null) {
      return double.tryParse(sizeMatch.group(1) ?? '12') ?? 12;
    }
    
    return 12;
  }

  /// Parse color string to PdfColor
  PdfColor? _parseColor(String colorString) {
    colorString = colorString.trim().toLowerCase();
    
    // Handle hex colors
    if (colorString.startsWith('#')) {
      final hex = colorString.substring(1);
      if (hex.length == 6) {
        final r = int.parse(hex.substring(0, 2), radix: 16) / 255;
        final g = int.parse(hex.substring(2, 4), radix: 16) / 255;
        final b = int.parse(hex.substring(4, 6), radix: 16) / 255;
        return PdfColor(r, g, b);
      } else if (hex.length == 3) {
        final r = int.parse(hex.substring(0, 1) * 2, radix: 16) / 255;
        final g = int.parse(hex.substring(1, 2) * 2, radix: 16) / 255;
        final b = int.parse(hex.substring(2, 3) * 2, radix: 16) / 255;
        return PdfColor(r, g, b);
      }
    }
    
    // Handle rgb/rgba colors
    if (colorString.startsWith('rgb')) {
      final match = RegExp(r'rgba?\((\d+),\s*(\d+),\s*(\d+)').firstMatch(colorString);
      if (match != null) {
        final r = int.parse(match.group(1)!) / 255;
        final g = int.parse(match.group(2)!) / 255;
        final b = int.parse(match.group(3)!) / 255;
        return PdfColor(r, g, b);
      }
    }
    
    // Handle named colors
    return _getNamedColor(colorString);
  }

  /// Get named color
  PdfColor? _getNamedColor(String name) {
    switch (name) {
      case 'red':
        return PdfColors.red;
      case 'green':
        return PdfColors.green;
      case 'blue':
        return PdfColors.blue;
      case 'yellow':
        return PdfColors.yellow;
      case 'orange':
        return PdfColors.orange;
      case 'purple':
        return PdfColors.purple;
      case 'pink':
        return PdfColors.pink;
      case 'black':
        return PdfColors.black;
      case 'white':
        return PdfColors.white;
      case 'grey':
      case 'gray':
        return PdfColors.grey;
      default:
        return null;
    }
  }
}
