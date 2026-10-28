import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/services/chat/chat_room_learning_service.dart';
import 'package:lingafriq/services/chat/on_device_overlay_service.dart';
import 'package:lingafriq/services/lexicon_lookup_service.dart';
import 'package:lingafriq/utils/modern_griot_design_system.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart' show PanAfricanSpacing;
import 'package:lingafriq/widgets/tone_contour_line.dart';

/// copy_keys: tonelens.title, tonelens.unsure, gloss.save
class ToneLensSheetCopy {
  static const title = 'Tone Lens';
  static const unsure =
      'We are not sure about the tone pattern for this word yet.';
  static const save = 'Save to review';
  static const saved = 'Saved for review';
  static const offline =
      'Word help works offline when your language pack is downloaded.';
  static const notFound = 'No verified entry for this word yet.';
}

enum ToneLensSheetPhase {
  loading,
  ready,
  saved,
  offline,
  error,
}

class ToneLensSheetModel {
  const ToneLensSheetModel({
    required this.surface,
    required this.lookup,
    required this.tone,
    this.savedItemId,
  });

  final String surface;
  final LexiconLookupResult lookup;
  final ToneLensOverlayResult tone;
  final String? savedItemId;

  bool get canSave =>
      lookup.kind == LexiconLookupKind.hit && lookup.lexeme != null;

  bool get toneUnsure => !tone.toneData.hasContour;
}

Future<ToneLensSheetModel?> showToneLensSheet({
  required BuildContext context,
  required ChatRoomLearningService service,
  required String messageId,
  required String word,
  bool e2ee = true,
}) async {
  return showModalBottomSheet<ToneLensSheetModel>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) {
      return _ToneLensSheetBody(
        service: service,
        messageId: messageId,
        word: word,
        e2ee: e2ee,
      );
    },
  );
}

class _ToneLensSheetBody extends StatefulWidget {
  const _ToneLensSheetBody({
    required this.service,
    required this.messageId,
    required this.word,
    required this.e2ee,
  });

  final ChatRoomLearningService service;
  final String messageId;
  final String word;
  final bool e2ee;

  @override
  State<_ToneLensSheetBody> createState() => _ToneLensSheetBodyState();
}

class _ToneLensSheetBodyState extends State<_ToneLensSheetBody> {
  ToneLensSheetPhase _phase = ToneLensSheetPhase.loading;
  ToneLensSheetModel? _model;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final policy = await widget.service.resolveSurfacePolicy();
      if (policy != ChatLearningSurfacePolicy.available) {
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }
      final gloss = await widget.service.glossWord(
        messageId: widget.messageId,
        word: widget.word,
        e2ee: widget.e2ee,
      );
      final tone = await widget.service.toneLensForWord(
        messageId: widget.messageId,
        word: widget.word,
        e2ee: widget.e2ee,
      );
      if (!mounted) return;
      setState(() {
        _model = ToneLensSheetModel(
          surface: gloss.surface,
          lookup: gloss.lookup,
          tone: tone,
        );
        _phase = gloss.lookup.kind == LexiconLookupKind.offlineMissing
            ? ToneLensSheetPhase.offline
            : ToneLensSheetPhase.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = ToneLensSheetPhase.error;
        _error = e.toString();
      });
    }
  }

  Future<void> _save() async {
    final model = _model;
    if (model == null || !model.canSave) return;
    try {
      final result = await widget.service.saveWordToReview(lookup: model.lookup);
      if (!mounted) return;
      setState(() {
        _phase = ToneLensSheetPhase.saved;
        _model = ToneLensSheetModel(
          surface: model.surface,
          lookup: model.lookup,
          tone: model.tone,
          savedItemId: result.itemId,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = ToneLensSheetPhase.error;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        PanAfricanSpacing.lg.w,
        PanAfricanSpacing.sm.h,
        PanAfricanSpacing.lg.w,
        PanAfricanSpacing.lg.h + bottom,
      ),
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_phase == ToneLensSheetPhase.loading) {
      return SizedBox(
        height: 160.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_phase == ToneLensSheetPhase.error) {
      return Text(
        _error ?? 'Something went wrong.',
        style: ModernGriotTypography.bodyMedium(context: context),
      );
    }

    final model = _model!;
    final scheme = Theme.of(context).colorScheme;
    final glossText = switch (model.lookup.kind) {
      LexiconLookupKind.hit =>
        model.lookup.resolvedLemma ?? model.lookup.surface,
      LexiconLookupKind.notFound => ToneLensSheetCopy.notFound,
      LexiconLookupKind.offlineMissing => ToneLensSheetCopy.offline,
    };

    return Semantics(
      label: ToneLensSheetCopy.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ToneLensSheetCopy.title,
            style: ModernGriotTypography.titleMedium(context: context),
          ),
          SizedBox(height: PanAfricanSpacing.sm.h),
          Text(
            model.surface,
            style: ModernGriotTypography.headlineSmall(context: context).copyWith(
              color: scheme.primary,
            ),
          ),
          SizedBox(height: PanAfricanSpacing.xs.h),
          Text(
            glossText,
            style: ModernGriotTypography.bodyLarge(context: context),
          ),
          SizedBox(height: PanAfricanSpacing.md.h),
          if (model.toneUnsure)
            Text(
              ToneLensSheetCopy.unsure,
              style: ModernGriotTypography.bodyMedium(context: context).copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            ToneContourLine(
              tonePattern: model.tone.toneData.tonePattern,
              syllables: model.tone.toneData.syllables,
              height: 48.h,
            ),
          SizedBox(height: PanAfricanSpacing.lg.h),
          if (_phase == ToneLensSheetPhase.saved)
            Text(
              ToneLensSheetCopy.saved,
              style: ModernGriotTypography.labelLarge(context: context).copyWith(
                color: scheme.secondary,
              ),
            )
          else
            FilledButton(
              onPressed: model.canSave ? _save : null,
              style: FilledButton.styleFrom(
                minimumSize: Size.fromHeight(48.h),
              ),
              child: Text(ToneLensSheetCopy.save),
            ),
        ],
      ),
    );
  }
}
