import 'package:flutter/material.dart';

// LinearAnnotation class
class LinearAnnotation {
  final List<Offset> annotations;
  final String annotationType;

  LinearAnnotation({
    required this.annotations,
    required this.annotationType,
  });
}