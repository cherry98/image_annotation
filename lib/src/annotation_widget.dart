import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'text_annotation.dart';
import 'annotation_painter.dart';
import 'linear_annotation.dart';

// ImageAnnotation class
class ImageAnnotation extends StatefulWidget {
  final String imagePath;
  final String annotationType;
  final Color color;
  final Color buttonColor;

  const ImageAnnotation({
    super.key,
    required this.imagePath,
    required this.annotationType,
    this.color = Colors.red,
    this.buttonColor = Colors.black,
  });

  @override
  _ImageAnnotationState createState() => _ImageAnnotationState();
}

class _ImageAnnotationState extends State<ImageAnnotation> {
  // List of annotation points for different shapes
  List<LinearAnnotation> linearAnnotations = [];
  List<Offset> currentAnnotation = []; // Current annotation points
  List<TextAnnotation> textAnnotations = []; // List of text annotations
  Size? imageSize; // Size of the image
  Offset? imageOffset; // Offset of the image on the screen
  List<bool> totalList = []; //text=true else=false use to remove list

  @override
  void initState() {
    super.initState();
    loadImageSize();
  }

  // Load image size asynchronously and set imageSize state
  void loadImageSize() async {
    final image = Image.asset(widget.imagePath);
    final completer = Completer<ui.Image>();

    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(info.image);
      }),
    );

    final loadedImage = await completer.future;
    setState(() {
      imageSize = calculateImageSize(loadedImage);
    });
  }

  // Calculate the image size to fit the screen while maintaining the aspect ratio
  Size calculateImageSize(ui.Image image) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final imageRatio = image.width / image.height;
    final screenRatio = screenWidth / screenHeight;

    double width;
    double height;

    if (imageRatio > screenRatio) {
      width = screenWidth;
      height = screenWidth / imageRatio;
    } else {
      height = screenHeight;
      width = screenHeight * imageRatio;
    }

    return Size(width, height);
  }

  // Calculate the offset of the image on the screen
  void calculateImageOffset() {
    if (imageSize != null) {
      final imageWidget = context.findRenderObject() as RenderBox?;
      final imagePosition = imageWidget?.localToGlobal(Offset.zero);
      final widgetPosition = (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero);
      final offsetX = imagePosition!.dx - widgetPosition.dx;
      final offsetY = imagePosition.dy - widgetPosition.dy;
      setState(() {
        imageOffset = Offset(offsetX, offsetY);
      });
    }
  }

  // Start a new annotation
  void startNewAnnotation() {
    setState(() {
      totalList.add(false);
      currentAnnotation = [];
      final tempAnnotation = LinearAnnotation(annotations: currentAnnotation, annotationType: widget.annotationType);
      linearAnnotations.add(tempAnnotation);
    });
  }

  // Draw shape based on the current position
  void drawShape(Offset position) {
    if (position.dx >= 0 && position.dy >= 0 && position.dx <= imageSize!.width && position.dy <= imageSize!.height) {
      setState(() {
        currentAnnotation.add(position);
      });
    }
  }

  // Add a text annotation to the list
  void addTextAnnotation(Offset position, String text, Color textColor, double fontSize) {
    setState(() {
      totalList.add(true);
      textAnnotations.add(TextAnnotation(
        position: position,
        text: text,
        textColor: textColor,
        fontSize: fontSize,
      ));
    });
  }

  // Clear the last added annotation
  void clearLastAnnotation() {
    setState(() {
      if (totalList.last) {
        if (textAnnotations.isNotEmpty) {
          textAnnotations.removeLast();
        }
      } else {
        if (linearAnnotations.isNotEmpty) {
          linearAnnotations.removeLast();
        }
      }
      totalList.removeLast();
    });
  }

  // Clear all annotations
  void clearAllAnnotations() {
    setState(() {
      linearAnnotations.clear();
      textAnnotations.clear();
      currentAnnotation = [];
    });
  }

  // Show a dialog to add text annotation
  void _showTextAnnotationDialog(BuildContext context, Offset localPosition) {
    String text = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Text Annotation'),
          content: TextField(
            onChanged: (value) {
              text = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                if (text.isNotEmpty) {
                  // Add the text annotation
                  addTextAnnotation(localPosition, text, widget.color, 16.0);
                }
              },
              child: Text(
                'Add',
                style: TextStyle(
                  color: widget.buttonColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: widget.buttonColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Build the widget
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      calculateImageOffset();
    });

    if (imageSize == null || imageOffset == null) {
      return const CircularProgressIndicator(); // Placeholder or loading indicator while the image size and offset are being retrieved
    }

    return RepaintBoundary(
      child: Stack(
        children: [
          Image.asset(
            widget.imagePath,
            width: imageSize!.width,
            height: imageSize!.height,
          ),
          Positioned(
            left: imageOffset!.dx,
            top: imageOffset!.dy,
            child: GestureDetector(
              onLongPress: clearAllAnnotations,
              onDoubleTap: clearLastAnnotation,
              onTapDown: (details) {
                if (widget.annotationType == 'text') {
                  _showTextAnnotationDialog(context, details.localPosition);
                }
              },
              onPanStart: (_) => startNewAnnotation(),
              onPanUpdate: (details) {
                drawShape(details.localPosition);
              },
              child: CustomPaint(
                painter: AnnotationPainter(linearAnnotations, textAnnotations, widget.color),
                size: imageSize!,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
