import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'learning_path_painter.dart';
import 'path_node_widget.dart';

/// Scrollable learning path widget that displays lessons in a Duolingo-style
/// zigzag pattern with curved connections.
class LearningPathWidget extends StatelessWidget {
  final List<Lesson> lessons;
  final int currentIndex;
  final ScrollController? scrollController;
  final double nodeSize;
  final double nodeSpacing;
  final double horizontalPadding;

  const LearningPathWidget({
    super.key,
    required this.lessons,
    required this.currentIndex,
    this.scrollController,
    this.nodeSize = 64,
    this.nodeSpacing = 120,
    this.horizontalPadding = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final nodeRadius = nodeSize / 2;
    final leftX = horizontalPadding + nodeRadius;
    final rightX = screenWidth - horizontalPadding - nodeRadius;
    final centerX = screenWidth / 2;

    return CustomPaint(
      painter: LearningPathPainter(
        nodePositions: _calculateNodePositions(
          lessons.length,
          nodeSpacing,
          leftX,
          rightX,
          centerX,
        ),
        currentIndex: currentIndex,
        primaryColor: PanAfricanColors.primary,
        inactiveColor: PanAfricanColors.neutralMedium.withOpacity(0.3),
      ),
      child: Stack(
        children: _buildNodes(
          context,
          lessons,
          nodeSpacing,
          leftX,
          rightX,
          centerX,
        ),
      ),
    );
  }

  List<PathNodePosition> _calculateNodePositions(
    int nodeCount,
    double spacing,
    double leftX,
    double rightX,
    double centerX,
  ) {
    final positions = <PathNodePosition>[];
    
    for (int i = 0; i < nodeCount; i++) {
      double x;
      if (i == 0) {
        x = centerX;
      } else {
        final isEven = i % 2 == 0;
        x = isEven ? rightX : leftX;
      }
      
      final y = 40.h + (i * spacing);
      positions.add(PathNodePosition(x, y));
    }
    
    return positions;
  }

  List<Widget> _buildNodes(
    BuildContext context,
    List<Lesson> lessons,
    double spacing,
    double leftX,
    double rightX,
    double centerX,
  ) {
    final nodes = <Widget>[];
    
    for (int i = 0; i < lessons.length; i++) {
      double x;
      if (i == 0) {
        x = centerX;
      } else {
        final isEven = i % 2 == 0;
        x = isEven ? rightX : leftX;
      }
      
      final y = 40.h + (i * spacing);
      
      final state = _getNodeState(i, lessons[i]);
      
      nodes.add(
        Positioned(
          left: x - nodeSize / 2,
          top: y - nodeSize / 2,
          child: PathNodeWidget(
            lesson: lessons[i],
            state: state,
            index: i,
            size: nodeSize,
          ),
        ),
      );
    }
    
    return nodes;
  }

  PathNodeState _getNodeState(int index, Lesson lesson) {
    if (index > currentIndex) {
      return PathNodeState.locked;
    } else if (index == currentIndex) {
      return PathNodeState.current;
    } else if (lesson.completed == lesson.count && lesson.count > 0) {
      final perfectScore = lesson.score >= lesson.count * 10;
      return perfectScore ? PathNodeState.crowned : PathNodeState.completed;
    } else {
      return PathNodeState.completed;
    }
  }
}
