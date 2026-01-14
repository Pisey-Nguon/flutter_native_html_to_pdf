import 'dart:typed_data';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Result of parsing HTML, including widgets and page-level styles.
class HtmlParseResult {
  /// The list of PDF widgets representing the HTML content.
  final List<pw.Widget> widgets;

  /// The margin extracted from body styles (for page-level margin).
  final pw.EdgeInsets? bodyMargin;

  /// The padding extracted from body styles.
  final pw.EdgeInsets? bodyPadding;

  /// The background color extracted from body styles.
  final PdfColor? bodyBackgroundColor;

  HtmlParseResult({
    required this.widgets,
    this.bodyMargin,
    this.bodyPadding,
    this.bodyBackgroundColor,
  });
}

/// Parses HTML content and converts it to PDF widgets.
class HtmlParser {
  final Map<String, Uint8List> _imageCache = {};
  final Map<String, CssStyle> _cssRules = {};

  /// Parses HTML string and returns a list of PDF widgets.
  /// @deprecated Use [parseWithStyles] for better body style support.
  Future<List<pw.Widget>> parse(String html) async {
    final result = await parseWithStyles(html);
    return result.widgets;
  }

  /// Parses HTML string and returns parse result with widgets and body styles.
  Future<HtmlParseResult> parseWithStyles(String html) async {
    final document = html_parser.parse(html);

    // Extract CSS from <style> tags
    _extractCssRules(document);

    final body = document.body;
    if (body == null) {
      return HtmlParseResult(widgets: [pw.Text('Empty document')]);
    }

    // Get body styles
    final bodyStyle = _getComputedStyle(body, CssStyle());
    final bodyMargin = bodyStyle.getEffectiveMargin();
    final bodyPadding = bodyStyle.getEffectivePadding();
    final bodyBackgroundColor = bodyStyle.backgroundColor;

    // Parse body children
    final widgets = await _parseBodyContent(body, bodyStyle);

    return HtmlParseResult(
      widgets: widgets,
      bodyMargin: bodyMargin,
      bodyPadding: bodyPadding,
      bodyBackgroundColor: bodyBackgroundColor,
    );
  }

  /// Parses body content (children only, without body element wrapper).
  Future<List<pw.Widget>> _parseBodyContent(
      dom.Element body, CssStyle bodyStyle) async {
    final List<pw.Widget> widgets = [];

    for (final node in body.nodes) {
      if (node is dom.Element) {
        final widget = await _parseElement(node, bodyStyle);
        if (widget != null) {
          widgets.add(widget);
        }
      } else if (node is dom.Text) {
        final text = node.text.trim();
        if (text.isNotEmpty) {
          widgets.add(pw.Text(text, style: bodyStyle.toTextStyle()));
        }
      }
    }

    return widgets;
  }

  /// Extracts CSS rules from all <style> tags in the document.
  void _extractCssRules(dom.Document document) {
    _cssRules.clear();

    final styleTags = document.querySelectorAll('style');
    for (final styleTag in styleTags) {
      _parseCssText(styleTag.text);
    }
  }

  /// Parses CSS text and extracts rules.
  void _parseCssText(String cssText) {
    // Remove comments
    cssText = cssText.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');

    // Match CSS rules: selector { properties }
    final ruleRegex = RegExp(r'([^{}]+)\{([^{}]*)\}');
    final matches = ruleRegex.allMatches(cssText);

    for (final match in matches) {
      final selectors = match.group(1)?.trim() ?? '';
      final properties = match.group(2)?.trim() ?? '';

      // Handle multiple selectors separated by comma
      for (var selector in selectors.split(',')) {
        selector = selector.trim();
        if (selector.isNotEmpty) {
          final style = _parseProperties(properties);
          _cssRules[selector] = style;
        }
      }
    }
  }

  /// Parses CSS properties string into a CssStyle object.
  CssStyle _parseProperties(String propertiesText) {
    final style = CssStyle();
    final properties = propertiesText.split(';');

    for (final prop in properties) {
      final colonIndex = prop.indexOf(':');
      if (colonIndex == -1) continue;

      final name = prop.substring(0, colonIndex).trim().toLowerCase();
      final value = prop.substring(colonIndex + 1).trim();

      _applyProperty(style, name, value);
    }

    return style;
  }

  /// Applies a single CSS property to a style object.
  void _applyProperty(CssStyle style, String name, String value) {
    switch (name) {
      case 'color':
        style.color = _parseColor(value);
        break;
      case 'background-color':
      case 'background':
        final color = _parseColor(value);
        if (color != null) style.backgroundColor = color;
        break;
      case 'font-size':
        style.fontSize = _parseFontSize(value);
        break;
      case 'font-weight':
        style.fontWeight = _parseFontWeight(value);
        break;
      case 'font-style':
        style.fontStyle =
            value == 'italic' ? pw.FontStyle.italic : pw.FontStyle.normal;
        break;
      case 'font-family':
        style.fontFamily = value.replaceAll(RegExp(r'''['"]'''), '').split(',').first.trim();
        break;
      case 'text-decoration':
        if (value.contains('underline')) {
          style.textDecoration = pw.TextDecoration.underline;
        } else if (value.contains('line-through')) {
          style.textDecoration = pw.TextDecoration.lineThrough;
        }
        break;
      case 'padding':
        style.padding = _parsePadding(value);
        break;
      case 'padding-top':
        style.paddingTop = _parseDimension(value);
        break;
      case 'padding-right':
        style.paddingRight = _parseDimension(value);
        break;
      case 'padding-bottom':
        style.paddingBottom = _parseDimension(value);
        break;
      case 'padding-left':
        style.paddingLeft = _parseDimension(value);
        break;
      case 'margin':
        style.margin = _parsePadding(value);
        break;
      case 'margin-top':
        style.marginTop = _parseDimension(value);
        break;
      case 'margin-right':
        style.marginRight = _parseDimension(value);
        break;
      case 'margin-bottom':
        style.marginBottom = _parseDimension(value);
        break;
      case 'margin-left':
        style.marginLeft = _parseDimension(value);
        break;
      case 'border':
        _parseBorder(style, value);
        break;
      case 'border-color':
        style.borderColor = _parseColor(value);
        break;
      case 'border-width':
        style.borderWidth = _parseDimension(value);
        break;
      case 'border-left':
        _parseBorderSide(style, value, 'left');
        break;
      case 'text-align':
        style.textAlign = _parseTextAlign(value);
        break;
      case 'line-height':
        style.lineHeight = _parseDimension(value);
        break;
    }
  }

  /// Gets the computed style for an element by combining CSS rules and inline styles.
  CssStyle _getComputedStyle(dom.Element element, CssStyle parentStyle) {
    final style = CssStyle.from(parentStyle);

    // Apply tag-based CSS rules (e.g., "p", "h1")
    final tagName = element.localName?.toLowerCase() ?? '';
    if (_cssRules.containsKey(tagName)) {
      style.merge(_cssRules[tagName]!);
    }

    // Apply class-based CSS rules (e.g., ".highlight")
    final classAttr = element.attributes['class'];
    if (classAttr != null) {
      for (var className in classAttr.split(RegExp(r'\s+'))) {
        className = className.trim();
        if (className.isNotEmpty && _cssRules.containsKey('.$className')) {
          style.merge(_cssRules['.$className']!);
        }
      }
    }

    // Apply ID-based CSS rules (e.g., "#header")
    final idAttr = element.attributes['id'];
    if (idAttr != null && _cssRules.containsKey('#$idAttr')) {
      style.merge(_cssRules['#$idAttr']!);
    }

    // Apply inline styles (highest priority)
    final inlineStyle = element.attributes['style'];
    if (inlineStyle != null) {
      style.merge(_parseProperties(inlineStyle));
    }

    return style;
  }

  Future<List<pw.Widget>> _parseNodes(
      List<dom.Node> nodes, CssStyle parentStyle) async {
    final widgets = <pw.Widget>[];

    for (final node in nodes) {
      final widget = await _parseNode(node, parentStyle);
      if (widget != null) {
        widgets.add(widget);
      }
    }

    return widgets;
  }

  Future<pw.Widget?> _parseNode(dom.Node node, CssStyle parentStyle) async {
    if (node is dom.Text) {
      final text = node.text.trim();
      if (text.isEmpty) return null;
      return pw.Text(text, style: parentStyle.toTextStyle());
    }

    if (node is dom.Element) {
      return await _parseElement(node, parentStyle);
    }

    return null;
  }

  Future<pw.Widget?> _parseElement(
      dom.Element element, CssStyle parentStyle) async {
    final style = _getComputedStyle(element, parentStyle);
    final tagName = element.localName?.toLowerCase() ?? '';

    switch (tagName) {
      case 'h1':
        return _buildHeading(element, style, 24);
      case 'h2':
        return _buildHeading(element, style, 20);
      case 'h3':
        return _buildHeading(element, style, 18);
      case 'h4':
        return _buildHeading(element, style, 16);
      case 'h5':
        return _buildHeading(element, style, 14);
      case 'h6':
        return _buildHeading(element, style, 12);
      case 'p':
        return await _buildParagraph(element, style);
      case 'div':
        return await _buildDiv(element, style);
      case 'span':
        return await _buildSpan(element, style);
      case 'strong':
      case 'b':
        style.fontWeight = pw.FontWeight.bold;
        return await _buildInlineText(element, style);
      case 'em':
      case 'i':
        style.fontStyle = pw.FontStyle.italic;
        return await _buildInlineText(element, style);
      case 'u':
        style.textDecoration = pw.TextDecoration.underline;
        return await _buildInlineText(element, style);
      case 'br':
        return pw.SizedBox(height: 10);
      case 'hr':
        return pw.Divider();
      case 'ul':
        return await _buildUnorderedList(element, style);
      case 'ol':
        return await _buildOrderedList(element, style);
      case 'li':
        return await _buildListItem(element, style);
      case 'a':
        return await _buildLink(element, style);
      case 'img':
        return await _buildImage(element);
      case 'table':
        return await _buildTable(element, style);
      case 'blockquote':
        return await _buildBlockquote(element, style);
      case 'pre':
      case 'code':
        return await _buildCode(element, style);
      case 'head':
      case 'style':
      case 'script':
      case 'title':
      case 'meta':
      case 'link':
        return null;
      case 'body':
        final children = await _parseNodes(element.nodes, style);
        final bodyContent = pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: children,
        );
        // Apply body margin/padding as container padding
        final bodyMargin = style.getEffectiveMargin() ?? style.margin;
        final bodyPadding = style.getEffectivePadding();
        if (bodyMargin != null || bodyPadding != null || style.backgroundColor != null) {
          return pw.Container(
            padding: bodyMargin ?? bodyPadding,
            decoration: style.backgroundColor != null
                ? pw.BoxDecoration(color: style.backgroundColor)
                : null,
            child: bodyContent,
          );
        }
        return bodyContent;
      case 'html':
        final children = await _parseNodes(element.nodes, style);
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: children,
        );
      default:
        if (element.nodes.isNotEmpty) {
          final children = await _parseNodes(element.nodes, style);
          if (children.length == 1) return children.first;
          if (children.isNotEmpty) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: children,
            );
          }
        }
        return null;
    }
  }

  pw.Widget _buildHeading(dom.Element element, CssStyle style, double defaultSize) {
    style.fontSize ??= defaultSize;
    style.fontWeight ??= pw.FontWeight.bold;

    return _wrapWithMarginPadding(
      pw.Text(element.text.trim(), style: style.toTextStyle()),
      style,
      defaultMargin: const pw.EdgeInsets.only(top: 12, bottom: 6),
    );
  }

  Future<pw.Widget> _buildParagraph(dom.Element element, CssStyle style) async {
    final children = await _buildInlineChildren(element, style);

    pw.Widget content;
    if (children.isEmpty) {
      content = pw.SizedBox();
    } else if (children.length == 1) {
      content = children.first;
    } else {
      content = pw.Wrap(children: children);
    }

    return _wrapWithMarginPadding(
      _wrapWithDecoration(content, style),
      style,
      defaultMargin: const pw.EdgeInsets.only(bottom: 8),
    );
  }

  Future<pw.Widget> _buildDiv(dom.Element element, CssStyle style) async {
    final children = await _parseNodes(element.nodes, style);

    pw.Widget content;
    if (children.isEmpty) {
      content = pw.SizedBox();
    } else if (children.length == 1) {
      content = children.first;
    } else {
      content = pw.Column(
        crossAxisAlignment: _getCrossAxisAlignment(style.textAlign),
        children: children,
      );
    }

    return _wrapWithMarginPadding(
      _wrapWithDecoration(content, style),
      style,
    );
  }

  Future<pw.Widget> _buildSpan(dom.Element element, CssStyle style) async {
    final children = await _buildInlineChildren(element, style);
    if (children.length == 1) return children.first;
    return pw.Wrap(children: children);
  }

  Future<pw.Widget> _buildInlineText(dom.Element element, CssStyle style) async {
    return pw.Text(element.text.trim(), style: style.toTextStyle());
  }

  Future<List<pw.Widget>> _buildInlineChildren(
      dom.Element element, CssStyle parentStyle) async {
    final widgets = <pw.Widget>[];

    for (final node in element.nodes) {
      if (node is dom.Text) {
        final text = node.text;
        if (text.trim().isNotEmpty) {
          widgets.add(pw.Text(text, style: parentStyle.toTextStyle()));
        }
      } else if (node is dom.Element) {
        final widget = await _parseElement(node, parentStyle);
        if (widget != null) {
          widgets.add(widget);
        }
      }
    }

    return widgets;
  }

  Future<pw.Widget> _buildUnorderedList(
      dom.Element element, CssStyle style) async {
    final items = <pw.Widget>[];
    for (final child in element.children) {
      if (child.localName?.toLowerCase() == 'li') {
        final itemStyle = _getComputedStyle(child, style);
        final content = await _buildInlineChildren(child, itemStyle);

        items.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: itemStyle.toTextStyle()),
                pw.Expanded(
                  child: content.length == 1
                      ? content.first
                      : pw.Wrap(children: content),
                ),
              ],
            ),
          ),
        );
      }
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items,
    );
  }

  Future<pw.Widget> _buildOrderedList(
      dom.Element element, CssStyle style) async {
    final items = <pw.Widget>[];
    var index = 1;
    for (final child in element.children) {
      if (child.localName?.toLowerCase() == 'li') {
        final itemStyle = _getComputedStyle(child, style);
        final content = await _buildInlineChildren(child, itemStyle);

        items.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('$index. ', style: itemStyle.toTextStyle()),
                pw.Expanded(
                  child: content.length == 1
                      ? content.first
                      : pw.Wrap(children: content),
                ),
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

  Future<pw.Widget> _buildListItem(dom.Element element, CssStyle style) async {
    return pw.Text(element.text.trim(), style: style.toTextStyle());
  }

  Future<pw.Widget> _buildLink(dom.Element element, CssStyle style) async {
    final href = element.attributes['href'] ?? '';
    style.color ??= PdfColors.blue;
    style.textDecoration = pw.TextDecoration.underline;

    return pw.UrlLink(
      destination: href,
      child: pw.Text(element.text.trim(), style: style.toTextStyle()),
    );
  }

  Future<pw.Widget?> _buildImage(dom.Element element) async {
    final src = element.attributes['src'];
    if (src == null || src.isEmpty) return null;

    try {
      Uint8List? imageData;

      if (src.startsWith('data:image')) {
        final base64Data = src.split(',').last;
        imageData = Uint8List.fromList(
          Uri.parse('data:application/octet-stream;base64,$base64Data')
                  .data
                  ?.contentAsBytes() ??
              [],
        );
      } else if (src.startsWith('http://') || src.startsWith('https://')) {
        if (_imageCache.containsKey(src)) {
          imageData = _imageCache[src];
        } else {
          try {
            final response = await http.get(Uri.parse(src)).timeout(
                  const Duration(seconds: 10),
                );
            if (response.statusCode == 200) {
              imageData = response.bodyBytes;
              _imageCache[src] = imageData;
            }
          } catch (_) {}
        }
      }

      if (imageData != null && imageData.isNotEmpty) {
        final image = pw.MemoryImage(imageData);
        final width = _parseDimension(element.attributes['width'] ?? '200');
        final height = _parseDimension(element.attributes['height'] ?? '150');
        return pw.Image(image, width: width, height: height);
      }
    } catch (_) {}

    return pw.Container(
      width: 200,
      height: 150,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
      ),
      child: pw.Center(
        child: pw.Text('[Image]',
            style: const pw.TextStyle(color: PdfColors.grey)),
      ),
    );
  }

  Future<pw.Widget> _buildTable(dom.Element element, CssStyle style) async {
    final rows = <pw.TableRow>[];

    for (final child in element.children) {
      final tagName = child.localName?.toLowerCase();
      if (tagName == 'thead' || tagName == 'tbody' || tagName == 'tfoot') {
        for (final row in child.children) {
          if (row.localName?.toLowerCase() == 'tr') {
            rows.add(await _buildTableRow(row, style));
          }
        }
      } else if (tagName == 'tr') {
        rows.add(await _buildTableRow(child, style));
      }
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      children: rows,
    );
  }

  Future<pw.TableRow> _buildTableRow(
      dom.Element element, CssStyle parentStyle) async {
    final cells = <pw.Widget>[];

    for (final child in element.children) {
      final tagName = child.localName?.toLowerCase();
      if (tagName == 'td' || tagName == 'th') {
        final cellStyle = _getComputedStyle(child, parentStyle);
        if (tagName == 'th') {
          cellStyle.fontWeight = pw.FontWeight.bold;
        }
        cells.add(
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(child.text.trim(), style: cellStyle.toTextStyle()),
          ),
        );
      }
    }

    return pw.TableRow(children: cells);
  }

  Future<pw.Widget> _buildBlockquote(
      dom.Element element, CssStyle style) async {
    style.fontStyle ??= pw.FontStyle.italic;
    style.color ??= PdfColors.grey700;

    final children = await _parseNodes(element.nodes, style);

    return pw.Container(
      margin: const pw.EdgeInsets.only(left: 16, top: 8, bottom: 8),
      padding: const pw.EdgeInsets.only(left: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: PdfColors.grey400, width: 4),
        ),
      ),
      child: children.length == 1
          ? children.first
          : pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: children,
            ),
    );
  }

  Future<pw.Widget> _buildCode(dom.Element element, CssStyle style) async {
    style.fontFamily = 'Courier';

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey200,
      ),
      child: pw.Text(
        element.text.trim(),
        style: pw.TextStyle(
          font: pw.Font.courier(),
          fontSize: style.fontSize ?? 10,
          color: style.color,
        ),
      ),
    );
  }

  pw.Widget _wrapWithDecoration(pw.Widget child, CssStyle style) {
    if (style.backgroundColor == null &&
        style.borderColor == null &&
        style.padding == null &&
        style.paddingTop == null &&
        style.paddingRight == null &&
        style.paddingBottom == null &&
        style.paddingLeft == null) {
      return child;
    }

    return pw.Container(
      padding: style.getEffectivePadding(),
      decoration: pw.BoxDecoration(
        color: style.backgroundColor,
        border: style.borderColor != null
            ? pw.Border.all(
                color: style.borderColor!,
                width: style.borderWidth ?? 1,
              )
            : style.borderLeftColor != null
                ? pw.Border(
                    left: pw.BorderSide(
                      color: style.borderLeftColor!,
                      width: style.borderLeftWidth ?? 4,
                    ),
                  )
                : null,
      ),
      child: child,
    );
  }

  pw.Widget _wrapWithMarginPadding(
    pw.Widget child,
    CssStyle style, {
    pw.EdgeInsets? defaultMargin,
  }) {
    final margin = style.getEffectiveMargin() ?? defaultMargin;
    if (margin != null) {
      return pw.Padding(padding: margin, child: child);
    }
    return child;
  }

  pw.CrossAxisAlignment _getCrossAxisAlignment(pw.TextAlign? textAlign) {
    switch (textAlign) {
      case pw.TextAlign.center:
        return pw.CrossAxisAlignment.center;
      case pw.TextAlign.right:
        return pw.CrossAxisAlignment.end;
      default:
        return pw.CrossAxisAlignment.start;
    }
  }

  // CSS parsing helpers

  PdfColor? _parseColor(String colorString) {
    final color = colorString.trim().toLowerCase();

    final namedColors = <String, PdfColor>{
      'red': PdfColors.red,
      'green': PdfColors.green,
      'blue': PdfColors.blue,
      'black': PdfColors.black,
      'white': PdfColors.white,
      'yellow': PdfColors.yellow,
      'orange': PdfColors.orange,
      'purple': PdfColors.purple,
      'pink': PdfColors.pink,
      'grey': PdfColors.grey,
      'gray': PdfColors.grey,
      'cyan': PdfColors.cyan,
      'magenta': const PdfColor(1, 0, 1),
      'lime': PdfColors.lime,
      'brown': PdfColors.brown,
      'indigo': PdfColors.indigo,
      'teal': PdfColors.teal,
      'navy': const PdfColor(0, 0, 0.5),
      'maroon': const PdfColor(0.5, 0, 0),
      'olive': const PdfColor(0.5, 0.5, 0),
      'aqua': PdfColors.cyan,
      'fuchsia': const PdfColor(1, 0, 1),
      'silver': PdfColors.grey400,
      'transparent': const PdfColor(0, 0, 0, 0),
    };

    if (namedColors.containsKey(color)) {
      return namedColors[color];
    }

    // Hex colors
    if (color.startsWith('#')) {
      try {
        var hex = color.substring(1);
        if (hex.length == 3) {
          hex = hex.split('').map((c) => '$c$c').join();
        }
        if (hex.length == 6) {
          final r = int.parse(hex.substring(0, 2), radix: 16);
          final g = int.parse(hex.substring(2, 4), radix: 16);
          final b = int.parse(hex.substring(4, 6), radix: 16);
          return PdfColor(r / 255, g / 255, b / 255);
        }
        if (hex.length == 8) {
          final r = int.parse(hex.substring(0, 2), radix: 16);
          final g = int.parse(hex.substring(2, 4), radix: 16);
          final b = int.parse(hex.substring(4, 6), radix: 16);
          final a = int.parse(hex.substring(6, 8), radix: 16);
          return PdfColor(r / 255, g / 255, b / 255, a / 255);
        }
      } catch (_) {}
    }

    // RGB/RGBA colors
    final rgbMatch =
        RegExp(r'rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+)\s*)?\)')
            .firstMatch(color);
    if (rgbMatch != null) {
      final r = int.parse(rgbMatch.group(1)!);
      final g = int.parse(rgbMatch.group(2)!);
      final b = int.parse(rgbMatch.group(3)!);
      final a = rgbMatch.group(4) != null ? double.parse(rgbMatch.group(4)!) : 1.0;
      return PdfColor(r / 255, g / 255, b / 255, a);
    }

    return null;
  }

  double? _parseFontSize(String sizeString) {
    final size = sizeString.trim().toLowerCase();

    // Named sizes
    final namedSizes = <String, double>{
      'xx-small': 8,
      'x-small': 10,
      'small': 12,
      'medium': 14,
      'large': 16,
      'x-large': 20,
      'xx-large': 24,
    };

    if (namedSizes.containsKey(size)) {
      return namedSizes[size];
    }

    return _parseDimension(size);
  }

  double? _parseDimension(String value) {
    final trimmed = value.trim().toLowerCase();

    if (trimmed.endsWith('px')) {
      return double.tryParse(trimmed.replaceAll('px', ''));
    } else if (trimmed.endsWith('pt')) {
      return double.tryParse(trimmed.replaceAll('pt', ''));
    } else if (trimmed.endsWith('em')) {
      final em = double.tryParse(trimmed.replaceAll('em', ''));
      if (em != null) return em * 14; // Base font size
    } else if (trimmed.endsWith('rem')) {
      final rem = double.tryParse(trimmed.replaceAll('rem', ''));
      if (rem != null) return rem * 14;
    } else if (trimmed.endsWith('%')) {
      final percent = double.tryParse(trimmed.replaceAll('%', ''));
      if (percent != null) return percent / 100 * 14;
    }

    return double.tryParse(trimmed);
  }

  pw.FontWeight _parseFontWeight(String value) {
    final v = value.trim().toLowerCase();
    if (v == 'bold' || v == 'bolder' || v == '700' || v == '800' || v == '900') {
      return pw.FontWeight.bold;
    }
    return pw.FontWeight.normal;
  }

  pw.EdgeInsets? _parsePadding(String paddingString) {
    final parts = paddingString.trim().split(RegExp(r'\s+'));
    final values = parts.map((p) => _parseDimension(p) ?? 0.0).toList();

    switch (values.length) {
      case 1:
        return pw.EdgeInsets.all(values[0]);
      case 2:
        return pw.EdgeInsets.symmetric(
            vertical: values[0], horizontal: values[1]);
      case 3:
        return pw.EdgeInsets.only(
            top: values[0],
            left: values[1],
            right: values[1],
            bottom: values[2]);
      case 4:
        return pw.EdgeInsets.only(
            top: values[0],
            right: values[1],
            bottom: values[2],
            left: values[3]);
      default:
        return null;
    }
  }

  void _parseBorder(CssStyle style, String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    for (final part in parts) {
      final dimension = _parseDimension(part);
      if (dimension != null) {
        style.borderWidth = dimension;
      } else {
        final color = _parseColor(part);
        if (color != null) {
          style.borderColor = color;
        }
      }
    }
    style.borderColor ??= PdfColors.black;
  }

  void _parseBorderSide(CssStyle style, String value, String side) {
    final parts = value.trim().split(RegExp(r'\s+'));
    for (final part in parts) {
      final dimension = _parseDimension(part);
      if (dimension != null) {
        if (side == 'left') style.borderLeftWidth = dimension;
      } else {
        final color = _parseColor(part);
        if (color != null) {
          if (side == 'left') style.borderLeftColor = color;
        }
      }
    }
  }

  pw.TextAlign? _parseTextAlign(String value) {
    switch (value.trim().toLowerCase()) {
      case 'center':
        return pw.TextAlign.center;
      case 'right':
        return pw.TextAlign.right;
      case 'justify':
        return pw.TextAlign.justify;
      default:
        return pw.TextAlign.left;
    }
  }
}

/// Represents parsed CSS styles that can be applied to PDF widgets.
class CssStyle {
  PdfColor? color;
  PdfColor? backgroundColor;
  double? fontSize;
  pw.FontWeight? fontWeight;
  pw.FontStyle? fontStyle;
  String? fontFamily;
  pw.TextDecoration? textDecoration;
  pw.TextAlign? textAlign;
  double? lineHeight;

  pw.EdgeInsets? padding;
  double? paddingTop;
  double? paddingRight;
  double? paddingBottom;
  double? paddingLeft;

  pw.EdgeInsets? margin;
  double? marginTop;
  double? marginRight;
  double? marginBottom;
  double? marginLeft;

  PdfColor? borderColor;
  double? borderWidth;
  PdfColor? borderLeftColor;
  double? borderLeftWidth;

  CssStyle();

  /// Creates a copy of another style (only inheritable properties).
  /// In CSS, only text-related properties are inherited (color, font-*, text-*, line-height).
  /// Properties like background-color, padding, margin, border are NOT inherited.
  CssStyle.from(CssStyle other)
      : color = other.color,
        fontSize = other.fontSize,
        fontWeight = other.fontWeight,
        fontStyle = other.fontStyle,
        fontFamily = other.fontFamily,
        textDecoration = other.textDecoration,
        textAlign = other.textAlign,
        lineHeight = other.lineHeight;

  /// Merges another style into this one.
  /// Only inheritable properties are taken from the base style.
  /// Non-inheritable properties (background, padding, margin, border) are only
  /// applied if explicitly set on this element.
  void mergeInheritable(CssStyle parent) {
    // Only inherit text-related properties from parent
    color = color ?? parent.color;
    fontSize = fontSize ?? parent.fontSize;
    fontWeight = fontWeight ?? parent.fontWeight;
    fontStyle = fontStyle ?? parent.fontStyle;
    fontFamily = fontFamily ?? parent.fontFamily;
    textDecoration = textDecoration ?? parent.textDecoration;
    textAlign = textAlign ?? parent.textAlign;
    lineHeight = lineHeight ?? parent.lineHeight;
    // Note: backgroundColor, padding, margin, border are NOT inherited
  }

  /// Merges another style into this one (applies all properties from other).
  /// Use this when combining styles from the same element (e.g., tag + class + id + inline).
  void merge(CssStyle other) {
    color = other.color ?? color;
    backgroundColor = other.backgroundColor ?? backgroundColor;
    fontSize = other.fontSize ?? fontSize;
    fontWeight = other.fontWeight ?? fontWeight;
    fontStyle = other.fontStyle ?? fontStyle;
    fontFamily = other.fontFamily ?? fontFamily;
    textDecoration = other.textDecoration ?? textDecoration;
    textAlign = other.textAlign ?? textAlign;
    lineHeight = other.lineHeight ?? lineHeight;
    padding = other.padding ?? padding;
    paddingTop = other.paddingTop ?? paddingTop;
    paddingRight = other.paddingRight ?? paddingRight;
    paddingBottom = other.paddingBottom ?? paddingBottom;
    paddingLeft = other.paddingLeft ?? paddingLeft;
    margin = other.margin ?? margin;
    marginTop = other.marginTop ?? marginTop;
    marginRight = other.marginRight ?? marginRight;
    marginBottom = other.marginBottom ?? marginBottom;
    marginLeft = other.marginLeft ?? marginLeft;
    borderColor = other.borderColor ?? borderColor;
    borderWidth = other.borderWidth ?? borderWidth;
    borderLeftColor = other.borderLeftColor ?? borderLeftColor;
    borderLeftWidth = other.borderLeftWidth ?? borderLeftWidth;
  }

  /// Converts to PDF TextStyle.
  pw.TextStyle toTextStyle() {
    return pw.TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: textDecoration,
      lineSpacing: lineHeight,
    );
  }

  /// Gets effective padding.
  pw.EdgeInsets? getEffectivePadding() {
    if (padding != null) return padding;
    if (paddingTop != null ||
        paddingRight != null ||
        paddingBottom != null ||
        paddingLeft != null) {
      return pw.EdgeInsets.only(
        top: paddingTop ?? 0,
        right: paddingRight ?? 0,
        bottom: paddingBottom ?? 0,
        left: paddingLeft ?? 0,
      );
    }
    return null;
  }

  /// Gets effective margin.
  pw.EdgeInsets? getEffectiveMargin() {
    if (margin != null) return margin;
    if (marginTop != null ||
        marginRight != null ||
        marginBottom != null ||
        marginLeft != null) {
      return pw.EdgeInsets.only(
        top: marginTop ?? 0,
        right: marginRight ?? 0,
        bottom: marginBottom ?? 0,
        left: marginLeft ?? 0,
      );
    }
    return null;
  }
}
