import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Asymmetric bento-grid layout helper.
///
/// Takes a list of children with column spans (out of 12) to create
/// responsive bento layouts. Items flow into rows automatically.
///
/// ```dart
/// GriotBentoGrid(
///   gap: 12,
///   items: [
///     GriotBentoItem(span: 8, child: LargeCard()),
///     GriotBentoItem(span: 4, child: SmallCard()),
///     GriotBentoItem(span: 6, child: MediumCard()),
///     GriotBentoItem(span: 6, child: MediumCard()),
///   ],
/// )
/// ```
class GriotBentoGrid extends StatelessWidget {
  const GriotBentoGrid({
    super.key,
    required this.items,
    this.gap = 12,
    this.totalColumns = 12,
  });

  final List<GriotBentoItem> items;

  /// Gap between cells.
  final double gap;

  /// Total grid columns (default 12).
  final int totalColumns;

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();
    final gapSize = gap.r;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rows.length, (rowIndex) {
        final row = rows[rowIndex];
        return Padding(
          padding: EdgeInsets.only(bottom: rowIndex < rows.length - 1 ? gapSize : 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(row.length, (colIndex) {
                final item = row[colIndex];
                return Expanded(
                  flex: item.span,
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: colIndex < row.length - 1 ? gapSize : 0,
                    ),
                    child: item.child,
                  ),
                );
              }),
            ),
          ),
        );
      }),
    );
  }

  List<List<GriotBentoItem>> _buildRows() {
    final rows = <List<GriotBentoItem>>[];
    var currentRow = <GriotBentoItem>[];
    var currentSpan = 0;

    for (final item in items) {
      if (currentSpan + item.span > totalColumns && currentRow.isNotEmpty) {
        rows.add(currentRow);
        currentRow = [];
        currentSpan = 0;
      }
      currentRow.add(item);
      currentSpan += item.span;

      if (currentSpan >= totalColumns) {
        rows.add(currentRow);
        currentRow = [];
        currentSpan = 0;
      }
    }

    if (currentRow.isNotEmpty) rows.add(currentRow);
    return rows;
  }
}

/// A single item in [GriotBentoGrid].
class GriotBentoItem {
  const GriotBentoItem({
    required this.span,
    required this.child,
  });

  /// Column span out of [GriotBentoGrid.totalColumns] (default 12).
  final int span;

  final Widget child;
}
