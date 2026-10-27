import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:lingafriq/games/festival/festival_theme_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Village Festival hub strip (P8-931).
class VillageFestivalHubBanner extends StatefulWidget {
  const VillageFestivalHubBanner({
    super.key,
    this.onGameSelected,
    this.utcNowOverride,
  });

  final void Function(String gameId)? onGameSelected;
  final DateTime? utcNowOverride;

  @override
  State<VillageFestivalHubBanner> createState() => _VillageFestivalHubBannerState();
}

class _VillageFestivalHubBannerState extends State<VillageFestivalHubBanner> {
  VillageFestivalSnapshot? _snapshot;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final utc = widget.utcNowOverride;
      final snap = utc != null
          ? FestivalThemeService.instance.snapshotAt(utc)
          : await FestivalThemeService.instance.loadActive();
      if (!mounted) return;
      setState(() {
        _snapshot = snap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final spacing = PanAfricanSpacing.md;

    if (_loading) {
      return Semantics(
        label: VillageFestivalCopy.title,
        child: _shell(
          context,
          child: SizedBox(
            height: 120,
            child: Center(
              child: reduceMotion
                  ? Text(
                      VillageFestivalCopy.loading,
                      style: theme.textTheme.bodyMedium,
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    if (_error != null || _snapshot == null) {
      return Semantics(
        label: VillageFestivalCopy.error,
        child: _shell(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                VillageFestivalCopy.error,
                style: theme.textTheme.titleSmall,
              ),
              SizedBox(height: spacing),
              TextButton(
                onPressed: _load,
                child: Text(VillageFestivalCopy.retry),
              ),
            ],
          ),
        ),
      );
    }

    final snap = _snapshot!;
    final daysLabel = snap.daysLeftInWeek == 0
        ? VillageFestivalCopy.endsToday
        : VillageFestivalCopy.daysLeft(snap.daysLeftInWeek);

    return Semantics(
      label:
          '${VillageFestivalCopy.title}. ${snap.themeLabel}. $daysLabel',
      child: _shell(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              VillageFestivalCopy.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: spacing / 2),
            Text(
              snap.themeLabel,
              style: theme.textTheme.titleSmall,
            ),
            SizedBox(height: spacing / 2),
            Text(
              daysLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing),
            Text(
              VillageFestivalCopy.instructions,
              style: theme.textTheme.bodySmall,
            ),
            SizedBox(height: spacing),
            Text(
              VillageFestivalCopy.supportedGamesHeading,
              style: theme.textTheme.labelLarge,
            ),
            SizedBox(height: spacing / 2),
            Wrap(
              spacing: spacing / 2,
              runSpacing: spacing / 2,
              children: [
                for (final gameId in snap.supportedGameIds)
                  ActionChip(
                    label: Text(_gameLabel(gameId)),
                    onPressed: widget.onGameSelected == null
                        ? null
                        : () => widget.onGameSelected!(gameId),
                  ),
              ],
            ),
            if (FestivalThemeService.instance.lastPoolNote ==
                'no_festival_content') ...[
              SizedBox(height: spacing),
              Text(
                VillageFestivalCopy.noFestivalContent,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _shell(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    final spacing = PanAfricanSpacing.md;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: spacing, vertical: spacing / 2),
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: SingleChildScrollView(child: child),
      ),
    );
  }

  String _gameLabel(String gameId) {
    return gameId
        .split('_')
        .map((part) =>
            part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

/// Copy keys: games.village_festival.* (ARB wiring follows in localization pass).
class VillageFestivalCopy {
  static const title = 'Village Festival';
  static const instructions =
      'This week’s words lean into one theme across Arcade games. Your review queue still comes first.';
  static const loading = 'Loading this week’s festival…';
  static const error = 'We could not load the Village Festival. Try again.';
  static const retry = 'Try again';
  static const endsToday = 'New theme starts tomorrow';
  static const supportedGamesHeading = 'Games joining in';
  static const noFestivalContent =
      'No festival-tagged words are ready for this theme yet. Games use their usual word pool.';
  static const practiceLabel = 'Practice — scores do not count toward leagues';
  static const whyWrong =
      'Listen again, then match the tone and meaning before you move on.';

  static String daysLeft(int days) =>
      days == 1 ? '1 day left this week' : '$days days left this week';
}
