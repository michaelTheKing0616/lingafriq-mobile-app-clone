import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/pan_african_design_system.dart';

/// Production-ready interactive whiteboard widget
/// Supports drawing, erasing, color selection, and real-time collaboration
class InteractiveWhiteboard extends StatefulWidget {
  final String? roomId;
  final Function(List<DrawingPoint>)? onDrawingUpdate;
  final List<DrawingPoint>? initialDrawing;

  const InteractiveWhiteboard({
    Key? key,
    this.roomId,
    this.onDrawingUpdate,
    this.initialDrawing,
  }) : super(key: key);

  @override
  State<InteractiveWhiteboard> createState() => _InteractiveWhiteboardState();
}

class _InteractiveWhiteboardState extends State<InteractiveWhiteboard> {
  final List<DrawingPoint> _points = [];
  Color _currentColor = PanAfricanColors.primary;
  double _strokeWidth = 3.0;
  bool _isErasing = false;
  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.initialDrawing != null) {
      _points.addAll(widget.initialDrawing!);
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _points.add(DrawingPoint(
        point: details.localPosition,
        color: _isErasing ? Colors.transparent : _currentColor,
        width: _strokeWidth,
        isErase: _isErasing,
      ));
    });
    _notifyUpdate();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _points.add(DrawingPoint(
        point: details.localPosition,
        color: _isErasing ? Colors.transparent : _currentColor,
        width: _strokeWidth,
        isErase: _isErasing,
      ));
    });
    _notifyUpdate();
  }

  void _onPanEnd(DragEndDetails details) {
    _notifyUpdate();
  }

  void _notifyUpdate() {
    if (widget.onDrawingUpdate != null) {
      widget.onDrawingUpdate!(_points);
    }
  }

  void _clearBoard() {
    setState(() {
      _points.clear();
    });
    _notifyUpdate();
    HapticFeedback.mediumImpact();
  }

  void _undo() {
    if (_points.isNotEmpty) {
      setState(() {
        _points.removeLast();
      });
      _notifyUpdate();
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        boxShadow: PanAfricanShadows.md,
      ),
      child: Column(
        children: [
          // Toolbar
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.md,
              vertical: PanAfricanSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark 
                  ? PanAfricanColors.surfaceContainerDark 
                  : PanAfricanColors.surfaceContainerLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(PanAfricanRadius.lg),
                topRight: Radius.circular(PanAfricanRadius.lg),
              ),
            ),
            child: Row(
              children: [
                // Color picker
                _buildColorButton(Colors.black, isDark),
                SizedBox(width: PanAfricanSpacing.xs),
                _buildColorButton(PanAfricanColors.primary, isDark),
                SizedBox(width: PanAfricanSpacing.xs),
                _buildColorButton(PanAfricanColors.kenteRed, isDark),
                SizedBox(width: PanAfricanSpacing.xs),
                _buildColorButton(PanAfricanColors.kenteBlue, isDark),
                SizedBox(width: PanAfricanSpacing.xs),
                _buildColorButton(Colors.green, isDark),
                Spacer(),
                // Stroke width
                IconButton(
                  icon: Icon(Icons.brush, size: 20.sp),
                  onPressed: () => _showStrokeWidthDialog(context),
                  tooltip: 'Brush Size',
                ),
                // Eraser
                IconButton(
                  icon: Icon(
                    _isErasing ? Icons.auto_fix_high : Icons.auto_fix_off,
                    color: _isErasing ? PanAfricanColors.primary : null,
                  ),
                  onPressed: () {
                    setState(() {
                      _isErasing = !_isErasing;
                    });
                    HapticFeedback.lightImpact();
                  },
                  tooltip: 'Eraser',
                ),
                // Undo
                IconButton(
                  icon: Icon(Icons.undo),
                  onPressed: _undo,
                  tooltip: 'Undo',
                ),
                // Clear
                IconButton(
                  icon: Icon(Icons.clear_all, color: PanAfricanColors.error),
                  onPressed: _clearBoard,
                  tooltip: 'Clear All',
                ),
              ],
            ),
          ),
          // Drawing area
          Expanded(
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                key: _repaintKey,
                painter: WhiteboardPainter(_points),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color, bool isDark) {
    final isSelected = _currentColor == color && !_isErasing;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentColor = color;
          _isErasing = false;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: 32.w,
        height: 32.h,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected 
                ? PanAfricanColors.primary 
                : (isDark ? Colors.white24 : Colors.black12),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? PanAfricanShadows.sm : null,
        ),
      ),
    );
  }

  void _showStrokeWidthDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Brush Size'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: _strokeWidth,
                min: 1.0,
                max: 20.0,
                divisions: 19,
                label: _strokeWidth.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _strokeWidth = value;
                  });
                },
              ),
              Text('${_strokeWidth.toStringAsFixed(1)}px'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Done'),
          ),
        ],
      ),
    );
  }
}

/// Drawing point model
class DrawingPoint {
  final Offset point;
  final Color color;
  final double width;
  final bool isErase;

  DrawingPoint({
    required this.point,
    required this.color,
    required this.width,
    this.isErase = false,
  });

  Map<String, dynamic> toJson() => {
    'x': point.dx,
    'y': point.dy,
    'color': color.value,
    'width': width,
    'isErase': isErase,
  };

  factory DrawingPoint.fromJson(Map<String, dynamic> json) => DrawingPoint(
    point: Offset(json['x']?.toDouble() ?? 0, json['y']?.toDouble() ?? 0),
    color: Color(json['color'] ?? 0xFF000000),
    width: json['width']?.toDouble() ?? 3.0,
    isErase: json['isErase'] ?? false,
  );
}

/// Custom painter for whiteboard
class WhiteboardPainter extends CustomPainter {
  final List<DrawingPoint> points;

  WhiteboardPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      if (current.isErase) {
        // Erase mode - use blend mode to erase
        final paint = Paint()
          ..color = Colors.transparent
          ..strokeWidth = current.width
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.clear;
        canvas.drawLine(current.point, next.point, paint);
      } else {
        // Draw mode
        final paint = Paint()
          ..color = current.color
          ..strokeWidth = current.width
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(current.point, next.point, paint);
      }
    }
  }

  @override
  bool shouldRepaint(WhiteboardPainter oldDelegate) {
    return oldDelegate.points.length != points.length;
  }
}

