import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Status of a single processing step.
enum ProcessingStepStatus { pending, active, completed, failed }

/// Data for a single step in the processing pipeline.
class ProcessingStep {
  final String label;
  final ProcessingStepStatus status;
  final double? progress;

  const ProcessingStep({
    required this.label,
    required this.status,
    this.progress,
  });
}

/// Step checklist with animated progress for AI processing stages.
///
/// Renders a vertical list of processing steps with completion state
/// icons. Active steps show a spinning indicator; completed steps show
/// a check; failed steps show an error icon. An optional [progress]
/// value (0.0 – 1.0) renders a linear bar beneath the active step.
class ProcessingStepIndicator extends StatelessWidget {
  final List<ProcessingStep> steps;

  const ProcessingStepIndicator({
    super.key,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;
        return _StepRow(
          step: step,
          isLast: isLast,
          colors: colors,
        );
      }),
    );
  }
}

class _StepRow extends StatelessWidget {
  final ProcessingStep step;
  final bool isLast;
  final ColorScheme colors;

  const _StepRow({
    required this.step,
    required this.isLast,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIndicatorColumn(),
          SizedBox(width: 12.w),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildIndicatorColumn() {
    return SizedBox(
      width: 24.w,
      child: Column(
        children: [
          _buildIcon(),
          if (!isLast)
            Expanded(
              child: Container(
                width: 2.w,
                margin: EdgeInsets.symmetric(vertical: 4.h),
                color: step.status == ProcessingStepStatus.completed
                    ? const Color(0xFF4CAF50)
                    : colors.onSurface.withOpacity(0.1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    switch (step.status) {
      case ProcessingStepStatus.completed:
        return Container(
          width: 24.w,
          height: 24.w,
          decoration: const BoxDecoration(
            color: Color(0xFF4CAF50),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: 14.sp,
            color: Colors.white,
          ),
        );
      case ProcessingStepStatus.active:
        return SizedBox(
          width: 24.w,
          height: 24.w,
          child: CircularProgressIndicator(
            strokeWidth: 2.5.w,
            valueColor: AlwaysStoppedAnimation(colors.primary),
          ),
        );
      case ProcessingStepStatus.failed:
        return Container(
          width: 24.w,
          height: 24.w,
          decoration: BoxDecoration(
            color: colors.error,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close_rounded,
            size: 14.sp,
            color: colors.onError,
          ),
        );
      case ProcessingStepStatus.pending:
        return Container(
          width: 24.w,
          height: 24.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.onSurface.withOpacity(0.2),
              width: 2.w,
            ),
          ),
        );
    }
  }

  Widget _buildContent() {
    final textOpacity = switch (step.status) {
      ProcessingStepStatus.completed => 0.55,
      ProcessingStepStatus.active => 1.0,
      ProcessingStepStatus.failed => 0.75,
      ProcessingStepStatus.pending => 0.35,
    };

    final decoration = step.status == ProcessingStepStatus.completed
        ? TextDecoration.lineThrough
        : TextDecoration.none;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: step.status == ProcessingStepStatus.active
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: step.status == ProcessingStepStatus.failed
                  ? colors.error
                  : colors.onSurface.withOpacity(textOpacity),
              decoration: decoration,
              decorationColor: colors.onSurface.withOpacity(0.3),
            ),
          ),
          if (step.status == ProcessingStepStatus.active &&
              step.progress != null)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2.r),
                child: SizedBox(
                  height: 4.h,
                  child: LinearProgressIndicator(
                    value: step.progress,
                    backgroundColor: colors.onSurface.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation(colors.primary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
