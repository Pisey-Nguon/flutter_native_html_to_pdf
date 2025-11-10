/// Represents a PDF page size with width and height in points (72 points = 1 inch)
class PdfPageSize {
  final double width;
  final double height;
  final String name;

  const PdfPageSize._({
    required this.width,
    required this.height,
    required this.name,
  });

  /// A4 page size: 210mm x 297mm (8.27" x 11.69")
  static const a4 = PdfPageSize._(width: 595.2, height: 841.8, name: 'A4');

  /// US Letter page size: 8.5" x 11"
  static const letter = PdfPageSize._(width: 612, height: 792, name: 'Letter');

  /// US Legal page size: 8.5" x 14"
  static const legal = PdfPageSize._(width: 612, height: 1008, name: 'Legal');

  /// A3 page size: 297mm x 420mm (11.69" x 16.54")
  static const a3 = PdfPageSize._(width: 841.8, height: 1190.4, name: 'A3');

  /// A5 page size: 148mm x 210mm (5.83" x 8.27")
  static const a5 = PdfPageSize._(width: 419.4, height: 595.2, name: 'A5');

  /// US Tabloid page size: 11" x 17"
  static const tabloid = PdfPageSize._(width: 792, height: 1224, name: 'Tabloid');

  /// Create a custom page size
  /// [width] and [height] are in points (72 points = 1 inch)
  factory PdfPageSize.custom({
    required double width,
    required double height,
    String? name,
  }) {
    return PdfPageSize._(
      width: width,
      height: height,
      name: name ?? 'Custom',
    );
  }

  /// Convert to a map for passing to native platforms
  Map<String, dynamic> toMap() {
    return {
      'width': width,
      'height': height,
      'name': name,
    };
  }

  @override
  String toString() => 'PdfPageSize($name: ${width}x$height pts)';
}
