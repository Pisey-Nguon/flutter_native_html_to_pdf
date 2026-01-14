/// Represents a PDF page size with width and height in points (72 points = 1 inch).
///
/// This class provides predefined page sizes (A4, Letter, Legal, etc.) as well as
/// the ability to create custom page sizes.
class PdfPageSize {
  /// The width of the page in points (72 points = 1 inch).
  final double width;

  /// The height of the page in points (72 points = 1 inch).
  final double height;

  /// A human-readable name for the page size.
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
  static const tabloid =
      PdfPageSize._(width: 792, height: 1224, name: 'Tabloid');

  /// B5 page size: 176mm x 250mm (6.93" x 9.84")
  static const b5 = PdfPageSize._(width: 498.9, height: 708.7, name: 'B5');

  /// Executive page size: 7.25" x 10.5"
  static const executive =
      PdfPageSize._(width: 522, height: 756, name: 'Executive');

  /// Create a custom page size.
  ///
  /// [width] and [height] are in points (72 points = 1 inch).
  /// [name] is an optional human-readable name for the page size.
  ///
  /// Example:
  /// ```dart
  /// // Create a 6" x 9" custom page size
  /// final customSize = PdfPageSize.custom(
  ///   width: 432, // 6 * 72
  ///   height: 648, // 9 * 72
  ///   name: 'Trade Book',
  /// );
  /// ```
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

  /// Create a page size from millimeters.
  ///
  /// [widthMm] and [heightMm] are in millimeters.
  /// [name] is an optional human-readable name for the page size.
  factory PdfPageSize.fromMillimeters({
    required double widthMm,
    required double heightMm,
    String? name,
  }) {
    // 1 inch = 25.4mm, 1 inch = 72 points
    // So 1mm = 72/25.4 points ≈ 2.834645669 points
    const mmToPoints = 72 / 25.4;
    return PdfPageSize._(
      width: widthMm * mmToPoints,
      height: heightMm * mmToPoints,
      name: name ?? 'Custom',
    );
  }

  /// Create a page size from inches.
  ///
  /// [widthInches] and [heightInches] are in inches.
  /// [name] is an optional human-readable name for the page size.
  factory PdfPageSize.fromInches({
    required double widthInches,
    required double heightInches,
    String? name,
  }) {
    // 1 inch = 72 points
    return PdfPageSize._(
      width: widthInches * 72,
      height: heightInches * 72,
      name: name ?? 'Custom',
    );
  }

  /// Returns a landscape version of this page size.
  PdfPageSize get landscape {
    if (width > height) return this;
    return PdfPageSize._(
      width: height,
      height: width,
      name: '$name Landscape',
    );
  }

  /// Returns a portrait version of this page size.
  PdfPageSize get portrait {
    if (height > width) return this;
    return PdfPageSize._(
      width: height,
      height: width,
      name: '$name Portrait',
    );
  }

  @override
  String toString() => 'PdfPageSize($name: ${width}x$height pts)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PdfPageSize &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => width.hashCode ^ height.hashCode;
}
