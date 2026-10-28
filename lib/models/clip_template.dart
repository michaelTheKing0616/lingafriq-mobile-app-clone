import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/services/word_of_the_day_service.dart';

/// P9-949 — clip starter templates bound to verified content only.
enum ClipTemplatesAccessGate {
  loading,
  allowed,
  blockedMinor,
  blockedAgeUnknown,
  offline,
}

enum ClipTemplateKind {
  phraseOfDay,
  proverbExplainer,
  tongueTwister,
}

extension ClipTemplateKindX on ClipTemplateKind {
  String get copyKey => switch (this) {
        ClipTemplateKind.phraseOfDay => 'template.phrase',
        ClipTemplateKind.proverbExplainer => 'template.proverb',
        ClipTemplateKind.tongueTwister => 'template.twister',
      };

  String get title => switch (this) {
        ClipTemplateKind.phraseOfDay => 'Phrase of the day',
        ClipTemplateKind.proverbExplainer => 'Proverb explainer',
        ClipTemplateKind.tongueTwister => 'Tongue twister',
      };

  String get subtitle => switch (this) {
        ClipTemplateKind.phraseOfDay =>
          'Share today\'s verified word and what it means to you.',
        ClipTemplateKind.proverbExplainer =>
          'Teach a cited proverb — meaning first, then your take.',
        ClipTemplateKind.tongueTwister =>
          'Practice a sourced tone pair slowly, then at speaking pace.',
      };
}

@immutable
class ClipTemplateContent {
  const ClipTemplateContent({
    required this.kind,
    required this.languageTag,
    required this.promptLines,
    required this.suggestedCaption,
    required this.verificationStatus,
    required this.sourceId,
    this.headline,
  });

  final ClipTemplateKind kind;
  final String languageTag;
  final List<String> promptLines;
  final String suggestedCaption;
  final String verificationStatus;
  final String sourceId;
  final String? headline;

  bool get hasVerifiedBinding =>
      verificationStatus.isNotEmpty && sourceId.isNotEmpty;
}

@immutable
class ClipTemplatePreset {
  const ClipTemplatePreset({
    required this.languageTag,
    required this.suggestedCaption,
    required this.kind,
    required this.sourceId,
  });

  final String languageTag;
  final String suggestedCaption;
  final ClipTemplateKind kind;
  final String sourceId;
}

/// One-shot handoff into [ClipCameraScreen] after template pick (P9-949 AC1).
class ClipTemplatePendingStore {
  ClipTemplatePendingStore._();

  static ClipTemplatePreset? _pending;

  static void set(ClipTemplatePreset preset) => _pending = preset;

  static ClipTemplatePreset? take() {
    final value = _pending;
    _pending = null;
    return value;
  }

  @visibleForTesting
  static void clear() => _pending = null;
}

const _verifiedStatuses = {
  'expert_reviewed',
  'native_verified',
};

class ClipTemplateRepository {
  ClipTemplateRepository({
    WordOfTheDayService? wordOfTheDay,
    Future<String> Function(String assetPath)? readAsset,
  })  : _wotd = wordOfTheDay ?? WordOfTheDayService(),
        _readAsset = readAsset ?? rootBundle.loadString;

  final WordOfTheDayService _wotd;
  final Future<String> Function(String assetPath) _readAsset;

  Future<ClipTemplateContent?> load({
    required ClipTemplateKind kind,
    required String languageTag,
    DateTime? nowUtc,
  }) async {
    final lang = languageTag.trim().toLowerCase();
    if (lang.isEmpty) return null;

    return switch (kind) {
      ClipTemplateKind.phraseOfDay => _phraseOfDay(lang, nowUtc),
      ClipTemplateKind.proverbExplainer => _proverb(lang),
      ClipTemplateKind.tongueTwister => _twister(lang),
    };
  }

  Future<ClipTemplateContent?> _phraseOfDay(
    String lang,
    DateTime? nowUtc,
  ) async {
    final wotd = await _wotd.loadForToday(language: lang, nowUtc: nowUtc);
    if (wotd == null) return null;
    final lex = wotd.lexeme;
    final form = lex.standardOrthography.trim().isNotEmpty
        ? lex.standardOrthography.trim()
        : lex.lemma.trim();
    if (form.isEmpty) return null;

    final status = lex.verificationStatus.trim().toLowerCase();
    if (!_verifiedStatuses.contains(status)) return null;

    final story = wotd.story.trim();
    final caption = story.isNotEmpty
        ? '$form — $story'
        : 'Today\'s word: $form';

    return ClipTemplateContent(
      kind: ClipTemplateKind.phraseOfDay,
      languageTag: lang,
      headline: form,
      promptLines: [
        'Say the word: $form',
        if (story.isNotEmpty) 'Share what it means: $story',
        'End with one sentence about when you would use it.',
      ],
      suggestedCaption: caption,
      verificationStatus: status,
      sourceId: lex.lexemeId,
    );
  }

  Future<ClipTemplateContent?> _proverb(String lang) async {
    final path = 'assets/data/proverbs/$lang.json';
    try {
      final raw = await _readAsset(path);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final entries = decoded['entries'];
      if (entries is! List || entries.isEmpty) return null;

      for (final row in entries) {
        if (row is! Map) continue;
        final map = row.cast<String, dynamic>();
        final status =
            (map['verification_status'] as String? ?? '').trim().toLowerCase();
        if (!_verifiedStatuses.contains(status)) continue;
        final target = (map['target_text'] as String? ?? '').trim();
        if (target.isEmpty) continue;
        final gloss = (map['gloss_en'] as String? ?? '').trim();
        final id = (map['id'] as String? ?? '').trim();
        if (id.isEmpty) continue;

        final provenance = map['provenance'];
        var sourceId = id;
        if (provenance is Map) {
          final sources = provenance['sources'];
          if (sources is List && sources.isNotEmpty) {
            final first = sources.first;
            if (first is Map) {
              final cite = first['citation'] as String? ?? first['id'] as String?;
              if (cite != null && cite.trim().isNotEmpty) {
                sourceId = cite.trim();
              }
            }
          }
        }

        return ClipTemplateContent(
          kind: ClipTemplateKind.proverbExplainer,
          languageTag: lang,
          headline: target,
          promptLines: [
            'Say the proverb: $target',
            if (gloss.isNotEmpty) 'Explain in plain English: $gloss',
            'Share when someone might hear this at home.',
          ],
          suggestedCaption: gloss.isNotEmpty ? '$target — $gloss' : target,
          verificationStatus: status,
          sourceId: sourceId,
        );
      }
    } on FlutterError {
      return null;
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<ClipTemplateContent?> _twister(String lang) async {
    try {
      final raw = await _readAsset('assets/data/tone/minimal_pairs.json');
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final languages = decoded['languages'];
      if (languages is! Map) return null;
      final block = languages[lang];
      if (block is! Map) return null;
      final drills = block['drills'];
      if (drills is! List || drills.isEmpty) return null;

      for (final drill in drills) {
        if (drill is! Map) continue;
        final map = drill.cast<String, dynamic>();
        final pairSource = (map['pair_source_id'] as String? ?? '').trim();
        if (pairSource.isEmpty) continue;
        final options = map['options'];
        if (options is! List || options.length < 2) continue;

        final forms = <String>[];
        var sourceId = pairSource;
        for (final opt in options) {
          if (opt is! Map) continue;
          final form = (opt['form'] as String? ?? '').trim();
          if (form.isNotEmpty) forms.add(form);
          final sid = (opt['source_id'] as String? ?? '').trim();
          if (sid.isNotEmpty) sourceId = sid;
        }
        if (forms.length < 2) continue;

        final line = forms.join(' · ');
        return ClipTemplateContent(
          kind: ClipTemplateKind.tongueTwister,
          languageTag: lang,
          headline: line,
          promptLines: [
            'Slowly: ${forms.join(', then ')}',
            'Again at natural speed — keep tones clear.',
            'Invite a friend to repeat the pair.',
          ],
          suggestedCaption:
              'Tone practice: $line (${map['prompt_gloss_en'] ?? 'minimal pair'})',
          verificationStatus: 'expert_reviewed',
          sourceId: sourceId,
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  ClipTemplatePreset presetFrom(ClipTemplateContent content) {
    return ClipTemplatePreset(
      languageTag: content.languageTag,
      suggestedCaption: content.suggestedCaption,
      kind: content.kind,
      sourceId: content.sourceId,
    );
  }
}

/// Detail panel for a bound template (widget/golden tests, P9-949).
class ClipTemplateDetailPanel extends StatelessWidget {
  const ClipTemplateDetailPanel({
    super.key,
    required this.content,
    required this.onStartClip,
  });

  final ClipTemplateContent content;
  final VoidCallback onStartClip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = content.verificationStatus.replaceAll('_', ' ');
    return Card(
      elevation: 0,
      color: PanAfricanColors.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    content.headline ?? content.kind.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(
                  label: Text(statusLabel),
                  backgroundColor: PanAfricanColors.primaryContainer,
                  labelStyle: TextStyle(
                    color: PanAfricanColors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final line in content.promptLines)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(line, style: theme.textTheme.bodyLarge),
              ),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: 'Start clip with ${content.kind.title}',
              child: FilledButton(
                onPressed: onStartClip,
                child: const Text('Start clip'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@visibleForTesting
ClipTemplateContent? pickFirstVerifiedProverb(
  List<Map<String, dynamic>> entries,
) {
  for (final map in entries) {
    final status =
        (map['verification_status'] as String? ?? '').trim().toLowerCase();
    if (!_verifiedStatuses.contains(status)) continue;
    final target = (map['target_text'] as String? ?? '').trim();
    if (target.isEmpty) continue;
    final id = (map['id'] as String? ?? '').trim();
    if (id.isEmpty) continue;
    return ClipTemplateContent(
      kind: ClipTemplateKind.proverbExplainer,
      languageTag: 'yo',
      headline: target,
      promptLines: [target],
      suggestedCaption: target,
      verificationStatus: status,
      sourceId: id,
    );
  }
  return null;
}
