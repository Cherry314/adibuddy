import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import '../models/image_group.dart';

class Stroke {
  final List<Offset> points;
  final Color color;
  final double width;
  Stroke({required this.points, required this.color, required this.width});
}

class DrawScreen extends StatefulWidget {
  final ImageGroup group;
  const DrawScreen({required this.group, Key? key}) : super(key: key);

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  ui.Image? baseImage;

  /// Cached overlay images
  List<ui.Image?> cachedOverlayImages = [];
  List<ui.Image> overlayImages = [];
  Set<int> selectedOverlays = {};

  List<Stroke> strokes = [];
  Stroke? currentStroke;

  Color currentColor = Colors.red;
  double currentWidth = 4.0;

  final List<Color> palette = [Colors.red, Colors.green, Colors.blue, Colors.yellow];
  final List<double> widths = [2.0, 4.0, 8.0, 12.0];

  bool isPanZoom = false;
  TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _loadBaseImage();
    _preloadOverlayImages();   // <-- Preload overlays ONCE
  }

  Future<ui.Image> _loadUiImage(String imagePath) async {
    Uint8List list;

    // Check if it's a file path (user image) or asset path
    if (imagePath.startsWith('/') || imagePath.startsWith('C:') ||
        imagePath.contains('user_images')) {
      // It's a file path - load from file system
      final file = File(imagePath);
      list = await file.readAsBytes();
    } else {
      // It's an asset path - load from bundle
      final data = await rootBundle.load(imagePath);
      list = Uint8List.view(data.buffer);
    }

    final codec = await ui.instantiateImageCodec(list);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _loadBaseImage() async {
    try {
      final img = await _loadUiImage(widget.group.baseImage);
      setState(() => baseImage = img);
    } catch (e) {
      setState(() => baseImage = null);
    }
  }

  /// Preload ALL overlay images once (fast UI)
  void _preloadOverlayImages() async {
    cachedOverlayImages = List.filled(widget.group.overlays.length, null);

    for (int i = 0; i < widget.group.overlays.length; i++) {
      final file = widget.group.overlays[i].fileName;
      try {
        final img = await _loadUiImage(file);
        cachedOverlayImages[i] = img;
      } catch (_) {
        cachedOverlayImages[i] = null;
      }
    }

    setState(() {}); // overlays ready
  }

  /// Build list of overlays currently selected
  void _refreshOverlayList() {
    overlayImages = [
      for (int index in selectedOverlays)
        if (cachedOverlayImages[index] != null) cachedOverlayImages[index]!
    ];
    setState(() {});
  }

  Offset _transformPoint(Offset point) {
    final matrix = _transformationController.value;
    final inverse = vmath.Matrix4.inverted(matrix);
    final v = inverse.transform3(vmath.Vector3(point.dx, point.dy, 0));
    return Offset(v.x, v.y);
  }

  void _startStroke(Offset pos) {
    currentStroke = Stroke(
      points: [_transformPoint(pos)],
      color: currentColor,
      width: currentWidth,
    );
  }

  void _appendStroke(Offset pos) {
    if (currentStroke == null) return;
    setState(() => currentStroke!.points.add(_transformPoint(pos)));
  }

  void _endStroke() {
    if (currentStroke == null) return;
    setState(() {
      strokes.add(currentStroke!);
      currentStroke = null;
    });
  }

  void _clearStrokes() {
    setState(() {
      strokes.clear();
      currentStroke = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final overlayCount = widget.group.overlays.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear drawings',
            onPressed: _clearStrokes,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              Widget canvas = Container(
                color: Colors.white,
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _StackPainter(
                    baseImage: baseImage,
                    overlayImages: overlayImages,
                    strokes: strokes,
                    currentStroke: currentStroke,
                  ),
                ),
              );

              if (isPanZoom) {
                return InteractiveViewer(
                  transformationController: _transformationController,
                  panEnabled: true,
                  scaleEnabled: true,
                  child: canvas,
                );
              }

              return GestureDetector(
                onPanStart: (d) => _startStroke(d.localPosition),
                onPanUpdate: (d) => _appendStroke(d.localPosition),
                onPanEnd: (_) => _endStroke(),
                child: Transform(
                  transform: _transformationController.value,
                  alignment: Alignment.topLeft,
                  child: canvas,
                ),
              );
            }),
          ),

          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.grey[100],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (overlayCount > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Overlays:"),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (int i = 0; i < overlayCount; i++)
                              FilterChip(
                                label: Text(widget.group.overlays[i].label),
                                selected: selectedOverlays.contains(i),
                                onSelected: (selected) {
                                  if (selected) {
                                    selectedOverlays.add(i);
                                  } else {
                                    selectedOverlays.remove(i);
                                  }
                                  _refreshOverlayList();  // <-- instant
                                },
                              ),
                          ],
                        ),
                      ],
                    ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Row(
                        children: [
                          const Text('Color:'),
                          const SizedBox(width: 8),
                          ...palette.map((c) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: GestureDetector(
                              onTap: () => setState(() => currentColor = c),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: currentColor == c ? Colors.black : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          )),
                          const SizedBox(width: 12),
                          const Text('Width:'),
                          const SizedBox(width: 8),
                          DropdownButton<double>(
                            value: currentWidth,
                            items: widths
                                .map((w) => DropdownMenuItem(
                              value: w,
                              child: Text(w.toStringAsFixed(0)),
                            ))
                                .toList(),
                            onChanged: (v) => setState(() => currentWidth = v ?? currentWidth),
                          ),
                          const SizedBox(width: 12),
                          Row(
                            children: [
                              const Text("Pan/Zoom"),
                              Switch(
                                value: isPanZoom,
                                onChanged: (val) => setState(() => isPanZoom = val),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _clearStrokes,
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                        iconSize: 32,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StackPainter extends CustomPainter {
  final ui.Image? baseImage;
  final List<ui.Image> overlayImages;
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  _StackPainter({
    this.baseImage,
    required this.overlayImages,
    required this.strokes,
    this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw base image without any filters
    if (baseImage != null) _drawImageFit(
        canvas, size, baseImage!, paint, isOverlay: false);

    // Draw overlay images with white transparency
    for (final overlay in overlayImages) {
      _drawImageFit(canvas, size, overlay, paint, isOverlay: true);
    }

    for (final s in strokes)
      _drawStroke(canvas, s);
    if (currentStroke != null) _drawStroke(canvas, currentStroke!);
  }

  void _drawImageFit(Canvas canvas, Size size, ui.Image img, Paint paint,
      {required bool isOverlay}) {
    final imgW = img.width.toDouble();
    final imgH = img.height.toDouble();
    final scale = math.min(size.width / imgW, size.height / imgH);
    final dstW = imgW * scale;
    final dstH = imgH * scale;
    final dx = (size.width - dstW) / 2;
    final dy = (size.height - dstH) / 2;
    final dst = Rect.fromLTWH(dx, dy, dstW, dstH);
    final src = Rect.fromLTWH(0, 0, imgW, imgH);

    // No color filter needed - overlay images have proper alpha channels
    // Base images and overlays are drawn as-is

    canvas.drawImageRect(img, src, dst, paint);

    // Reset paint for next draw
    paint.colorFilter = null;
  }

  void _drawStroke(Canvas canvas, Stroke s) {
    if (s.points.isEmpty) return;
    final path = Path()..moveTo(s.points[0].dx, s.points[0].dy);
    for (int i = 1; i < s.points.length; i++) {
      path.lineTo(s.points[i].dx, s.points[i].dy);
    }

    final p = Paint()
      ..color = s.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _StackPainter old) {
    return old.baseImage != baseImage ||
        old.overlayImages != overlayImages ||
        old.strokes != strokes ||
        old.currentStroke != currentStroke;
  }
}
