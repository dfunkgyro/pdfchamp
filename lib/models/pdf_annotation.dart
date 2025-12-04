import 'package:flutter/material.dart';

/// Base class for PDF annotations
abstract class PdfAnnotation {
  final String id;
  final int pageNumber;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final String? author;
  final Color color;
  final double opacity;

  const PdfAnnotation({
    required this.id,
    required this.pageNumber,
    required this.createdAt,
    this.modifiedAt,
    this.author,
    required this.color,
    this.opacity = 1.0,
  });

  /// Convert annotation to JSON for storage
  Map<String, dynamic> toJson();

  /// Get annotation type name
  String get type;

  /// Copy annotation with modifications
  PdfAnnotation copyWith({
    DateTime? modifiedAt,
    Color? color,
    double? opacity,
  });
}

/// Highlight annotation
class HighlightAnnotation extends PdfAnnotation {
  final Rect rect;
  final String? selectedText;

  const HighlightAnnotation({
    required super.id,
    required super.pageNumber,
    required super.createdAt,
    super.modifiedAt,
    super.author,
    required super.color,
    super.opacity = 0.3,
    required this.rect,
    this.selectedText,
  });

  @override
  String get type => 'highlight';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'pageNumber': pageNumber,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'author': author,
      'color': color.value,
      'opacity': opacity,
      'rect': {
        'left': rect.left,
        'top': rect.top,
        'right': rect.right,
        'bottom': rect.bottom,
      },
      'selectedText': selectedText,
    };
  }

  factory HighlightAnnotation.fromJson(Map<String, dynamic> json) {
    return HighlightAnnotation(
      id: json['id'] as String,
      pageNumber: json['pageNumber'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null,
      author: json['author'] as String?,
      color: Color(json['color'] as int),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.3,
      rect: Rect.fromLTRB(
        (json['rect']['left'] as num).toDouble(),
        (json['rect']['top'] as num).toDouble(),
        (json['rect']['right'] as num).toDouble(),
        (json['rect']['bottom'] as num).toDouble(),
      ),
      selectedText: json['selectedText'] as String?,
    );
  }

  @override
  HighlightAnnotation copyWith({
    DateTime? modifiedAt,
    Color? color,
    double? opacity,
    Rect? rect,
  }) {
    return HighlightAnnotation(
      id: id,
      pageNumber: pageNumber,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      author: author,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      rect: rect ?? this.rect,
      selectedText: selectedText,
    );
  }
}

/// Text comment annotation
class CommentAnnotation extends PdfAnnotation {
  final Offset position;
  final String comment;
  final List<CommentReply>? replies;

  const CommentAnnotation({
    required super.id,
    required super.pageNumber,
    required super.createdAt,
    super.modifiedAt,
    super.author,
    required super.color,
    super.opacity = 1.0,
    required this.position,
    required this.comment,
    this.replies,
  });

  @override
  String get type => 'comment';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'pageNumber': pageNumber,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'author': author,
      'color': color.value,
      'opacity': opacity,
      'position': {
        'dx': position.dx,
        'dy': position.dy,
      },
      'comment': comment,
      'replies': replies?.map((r) => r.toJson()).toList(),
    };
  }

  factory CommentAnnotation.fromJson(Map<String, dynamic> json) {
    return CommentAnnotation(
      id: json['id'] as String,
      pageNumber: json['pageNumber'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null,
      author: json['author'] as String?,
      color: Color(json['color'] as int),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      position: Offset(
        (json['position']['dx'] as num).toDouble(),
        (json['position']['dy'] as num).toDouble(),
      ),
      comment: json['comment'] as String,
      replies: (json['replies'] as List<dynamic>?)
          ?.map((r) => CommentReply.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  CommentAnnotation copyWith({
    DateTime? modifiedAt,
    Color? color,
    double? opacity,
    String? comment,
    List<CommentReply>? replies,
  }) {
    return CommentAnnotation(
      id: id,
      pageNumber: pageNumber,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      author: author,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      position: position,
      comment: comment ?? this.comment,
      replies: replies ?? this.replies,
    );
  }
}

/// Comment reply
class CommentReply {
  final String id;
  final String author;
  final String text;
  final DateTime createdAt;

  const CommentReply({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CommentReply.fromJson(Map<String, dynamic> json) {
    return CommentReply(
      id: json['id'] as String,
      author: json['author'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Drawing annotation (freehand)
class DrawingAnnotation extends PdfAnnotation {
  final List<DrawingPath> paths;
  final double strokeWidth;

  const DrawingAnnotation({
    required super.id,
    required super.pageNumber,
    required super.createdAt,
    super.modifiedAt,
    super.author,
    required super.color,
    super.opacity = 1.0,
    required this.paths,
    required this.strokeWidth,
  });

  @override
  String get type => 'drawing';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'pageNumber': pageNumber,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'author': author,
      'color': color.value,
      'opacity': opacity,
      'paths': paths.map((p) => p.toJson()).toList(),
      'strokeWidth': strokeWidth,
    };
  }

  factory DrawingAnnotation.fromJson(Map<String, dynamic> json) {
    return DrawingAnnotation(
      id: json['id'] as String,
      pageNumber: json['pageNumber'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null,
      author: json['author'] as String?,
      color: Color(json['color'] as int),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      paths: (json['paths'] as List<dynamic>)
          .map((p) => DrawingPath.fromJson(p as Map<String, dynamic>))
          .toList(),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
    );
  }

  @override
  DrawingAnnotation copyWith({
    DateTime? modifiedAt,
    Color? color,
    double? opacity,
    List<DrawingPath>? paths,
    double? strokeWidth,
  }) {
    return DrawingAnnotation(
      id: id,
      pageNumber: pageNumber,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      author: author,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      paths: paths ?? this.paths,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}

/// Drawing path
class DrawingPath {
  final List<Offset> points;

  const DrawingPath({required this.points});

  Map<String, dynamic> toJson() {
    return {
      'points': points
          .map((p) => {
                'dx': p.dx,
                'dy': p.dy,
              })
          .toList(),
    };
  }

  factory DrawingPath.fromJson(Map<String, dynamic> json) {
    return DrawingPath(
      points: (json['points'] as List<dynamic>)
          .map((p) => Offset(
                (p['dx'] as num).toDouble(),
                (p['dy'] as num).toDouble(),
              ))
          .toList(),
    );
  }
}

/// Text annotation (added text)
class TextAnnotation extends PdfAnnotation {
  final Offset position;
  final String text;
  final String fontFamily;
  final double fontSize;
  final FontWeight fontWeight;

  const TextAnnotation({
    required super.id,
    required super.pageNumber,
    required super.createdAt,
    super.modifiedAt,
    super.author,
    required super.color,
    super.opacity = 1.0,
    required this.position,
    required this.text,
    this.fontFamily = 'Roboto',
    this.fontSize = 14.0,
    this.fontWeight = FontWeight.normal,
  });

  @override
  String get type => 'text';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'pageNumber': pageNumber,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'author': author,
      'color': color.value,
      'opacity': opacity,
      'position': {
        'dx': position.dx,
        'dy': position.dy,
      },
      'text': text,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'fontWeight': fontWeight.index,
    };
  }

  factory TextAnnotation.fromJson(Map<String, dynamic> json) {
    return TextAnnotation(
      id: json['id'] as String,
      pageNumber: json['pageNumber'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null,
      author: json['author'] as String?,
      color: Color(json['color'] as int),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      position: Offset(
        (json['position']['dx'] as num).toDouble(),
        (json['position']['dy'] as num).toDouble(),
      ),
      text: json['text'] as String,
      fontFamily: json['fontFamily'] as String? ?? 'Roboto',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
      fontWeight: FontWeight.values[json['fontWeight'] as int? ?? 3],
    );
  }

  @override
  TextAnnotation copyWith({
    DateTime? modifiedAt,
    Color? color,
    double? opacity,
    String? text,
    double? fontSize,
  }) {
    return TextAnnotation(
      id: id,
      pageNumber: pageNumber,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      author: author,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      position: position,
      text: text ?? this.text,
      fontFamily: fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight,
    );
  }
}

/// Shape annotation (rectangles, circles, lines)
class ShapeAnnotation extends PdfAnnotation {
  final ShapeType shapeType;
  final Rect bounds;
  final double strokeWidth;
  final bool filled;

  const ShapeAnnotation({
    required super.id,
    required super.pageNumber,
    required super.createdAt,
    super.modifiedAt,
    super.author,
    required super.color,
    super.opacity = 1.0,
    required this.shapeType,
    required this.bounds,
    required this.strokeWidth,
    this.filled = false,
  });

  @override
  String get type => 'shape';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'pageNumber': pageNumber,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'author': author,
      'color': color.value,
      'opacity': opacity,
      'shapeType': shapeType.name,
      'bounds': {
        'left': bounds.left,
        'top': bounds.top,
        'right': bounds.right,
        'bottom': bounds.bottom,
      },
      'strokeWidth': strokeWidth,
      'filled': filled,
    };
  }

  factory ShapeAnnotation.fromJson(Map<String, dynamic> json) {
    return ShapeAnnotation(
      id: json['id'] as String,
      pageNumber: json['pageNumber'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null,
      author: json['author'] as String?,
      color: Color(json['color'] as int),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      shapeType:
          ShapeType.values.firstWhere((e) => e.name == json['shapeType']),
      bounds: Rect.fromLTRB(
        (json['bounds']['left'] as num).toDouble(),
        (json['bounds']['top'] as num).toDouble(),
        (json['bounds']['right'] as num).toDouble(),
        (json['bounds']['bottom'] as num).toDouble(),
      ),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      filled: json['filled'] as bool? ?? false,
    );
  }

  @override
  ShapeAnnotation copyWith({
    DateTime? modifiedAt,
    Color? color,
    double? opacity,
    Rect? bounds,
    double? strokeWidth,
    bool? filled,
  }) {
    return ShapeAnnotation(
      id: id,
      pageNumber: pageNumber,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      author: author,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      shapeType: shapeType,
      bounds: bounds ?? this.bounds,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      filled: filled ?? this.filled,
    );
  }
}

/// Shape types
enum ShapeType {
  rectangle,
  circle,
  line,
  arrow,
}

/// Redaction annotation (blacked out area)
class RedactionAnnotation extends PdfAnnotation {
  final Rect rect;
  final String? replacementText;

  const RedactionAnnotation({
    required super.id,
    required super.pageNumber,
    required super.createdAt,
    super.modifiedAt,
    super.author,
    super.color = Colors.black,
    super.opacity = 1.0,
    required this.rect,
    this.replacementText,
  });

  @override
  String get type => 'redaction';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'pageNumber': pageNumber,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'author': author,
      'color': color.value,
      'opacity': opacity,
      'rect': {
        'left': rect.left,
        'top': rect.top,
        'right': rect.right,
        'bottom': rect.bottom,
      },
      'replacementText': replacementText,
    };
  }

  factory RedactionAnnotation.fromJson(Map<String, dynamic> json) {
    return RedactionAnnotation(
      id: json['id'] as String,
      pageNumber: json['pageNumber'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null,
      author: json['author'] as String?,
      color: Color(json['color'] as int? ?? Colors.black.value),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      rect: Rect.fromLTRB(
        (json['rect']['left'] as num).toDouble(),
        (json['rect']['top'] as num).toDouble(),
        (json['rect']['right'] as num).toDouble(),
        (json['rect']['bottom'] as num).toDouble(),
      ),
      replacementText: json['replacementText'] as String?,
    );
  }

  @override
  RedactionAnnotation copyWith({
    DateTime? modifiedAt,
    Color? color,
    double? opacity,
    Rect? rect,
    String? replacementText,
  }) {
    return RedactionAnnotation(
      id: id,
      pageNumber: pageNumber,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      author: author,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      rect: rect ?? this.rect,
      replacementText: replacementText ?? this.replacementText,
    );
  }
}
