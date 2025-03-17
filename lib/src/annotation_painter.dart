import 'package:flutter/material.dart';
import 'text_annotation.dart';
import 'linear_annotation.dart';

// AnnotationPainter class
class AnnotationPainter extends CustomPainter {
  final List<LinearAnnotation> linearAnnotations;
  final List<TextAnnotation> textAnnotations;
  final Color color;

  AnnotationPainter(
    this.linearAnnotations,
    this.textAnnotations,
    this.color,
  );

  // Paint annotations and text on the canvas
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (var element in linearAnnotations) {
      if (element.annotations.isNotEmpty) {
        if (element.annotationType == 'line') {
          for (var i = 0; i < element.annotations.length - 1; i++) {
            canvas.drawLine(element.annotations[i], element.annotations[i + 1], paint);
          }
        } else if (element.annotationType == 'rectangle') {
          final rect = Rect.fromPoints(element.annotations.first, element.annotations.last);
          canvas.drawRect(rect, paint);
        } else if (element.annotationType == 'oval') {
          final oval = Rect.fromPoints(element.annotations.first, element.annotations.last);
          canvas.drawOval(oval, paint);
        }
      }
    }

    drawTextAnnotations(canvas); // Draw text annotations
  }

  // Draw text annotations on the canvas
  void drawTextAnnotations(Canvas canvas) {
    for (var annotation in textAnnotations) {
      final textSpan = TextSpan(
        text: annotation.text,
        style: TextStyle(color: annotation.textColor, fontSize: annotation.fontSize),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final textPosition = Offset(
        annotation.position.dx - textPainter.width / 2,
        annotation.position.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, textPosition);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
