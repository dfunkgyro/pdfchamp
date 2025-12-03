// lib/models/pdf_font.dart
import 'package:flutter/material.dart';
import 'dart:typed_data';

class PDFFont {
  final String name;
  final String family;
  final FontWeight weight;
  final FontStyle style;
  final double size;
  final PdfColor color;
  final TextDecoration decoration;
  final double letterSpacing;
  final double lineHeight;
  final TextAlign alignment;
  final Uint8List? fontData;
  final bool isEmbedded;

  PDFFont({
    required this.name,
    required this.family,
    this.weight = FontWeight.normal,
    this.style = FontStyle.normal,
    this.size = 12,
    this.color = const PdfColor(0, 0, 0),
    this.decoration = TextDecoration.none,
    this.letterSpacing = 0,
    this.lineHeight = 1.2,
    this.alignment = TextAlign.left,
    this.fontData,
    this.isEmbedded = false,
  });

  // Convert to PDF library's font
  pw.Font get pwFont {
    if (fontData != null && isEmbedded) {
      return pw.Font.ttf(fontData!);
    }
    // Return default font
    return pw.Font.courier();
  }

  // Get font style string
  String get styleString {
    String styleStr = '';
    if (weight == FontWeight.bold) styleStr += 'Bold';
    if (style == FontStyle.italic) styleStr += 'Italic';
    return styleStr.isNotEmpty ? styleStr : 'Regular';
  }

  // Create copy with modifications
  PDFFont copyWith({
    String? name,
    String? family,
    FontWeight? weight,
    FontStyle? style,
    double? size,
    PdfColor? color,
    TextDecoration? decoration,
    double? letterSpacing,
    double? lineHeight,
    TextAlign? alignment,
  }) {
    return PDFFont(
      name: name ?? this.name,
      family: family ?? this.family,
      weight: weight ?? this.weight,
      style: style ?? this.style,
      size: size ?? this.size,
      color: color ?? this.color,
      decoration: decoration ?? this.decoration,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      alignment: alignment ?? this.alignment,
      fontData: fontData,
      isEmbedded: isEmbedded,
    );
  }
}

class PdfColor {
  final int r;
  final int g;
  final int b;
  final double a;

  const PdfColor(this.r, this.g, this.b, [this.a = 1.0]);

  Color get flutterColor => Color.fromRGBO(r, g, b, a);
}