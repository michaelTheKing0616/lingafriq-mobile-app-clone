import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Copy keys and one-sentence tips revived from preloader intro text.
abstract final class FirstUseTipIds {
  static const games = 'tip.games';
  static const gamification = 'tip.gamification';
  static const polie = 'tip.polie';
  static const features = 'tip.features';

  static const all = [games, gamification, polie, features];
}

abstract final class FirstUseTipCopy {
  static const games =
      'Learn through play! 35 unique games designed for African language learning.';
  static const gamification =
      'Earn XP, level up, collect currencies, and unlock badges as you learn!';
  static const polie =
      'Your AI language assistant with 6 powerful modes for comprehensive learning.';
  static const features =
      'Informative pre-loader screen that explains new features and terminologies.';
}

enum FirstUseTipPhase { shown, hidden }

String firstUseTipPrefKey(String tipId) => 'first_use_tip_dismissed_$tipId';

/// Injectable persistence for dismissed tip ids (SharedPreferences or shared map).
class FirstUseTipDismissStorage {
  FirstUseTipDismissStorage(
    this._dismissed, {
    SharedPreferences? prefs,
    required bool persistToSharedPreferences,
  })  : _prefs = prefs,
        _persistToSharedPreferences = persistToSharedPreferences;

  final Map<String, bool> _dismissed;
  SharedPreferences? _prefs;
  final bool _persistToSharedPreferences;

  factory FirstUseTipDismissStorage.inMemory(Map<String, bool> dismissed) {
    return FirstUseTipDismissStorage(
      dismissed,
      persistToSharedPreferences: false,
    );
  }

  factory FirstUseTipDismissStorage.sharedPreferences(SharedPreferences prefs) {
    final dismissed = <String, bool>{};
    for (final id in FirstUseTipIds.all) {
      final key = firstUseTipPrefKey(id);
      if (prefs.getBool(key) ?? false) {
        dismissed[key] = true;
      }
    }
    return FirstUseTipDismissStorage(
      dismissed,
      prefs: prefs,
      persistToSharedPreferences: true,
    );
  }

  /// App default: memory cache hydrated and written through to SharedPreferences.
  static FirstUseTipDismissStorage createLazySharedPreferences() {
    final dismissed = <String, bool>{};
    final storage = FirstUseTipDismissStorage(
      dismissed,
      persistToSharedPreferences: true,
    );
    SharedPreferences.getInstance().then((prefs) {
      storage._prefs = prefs;
      for (final id in FirstUseTipIds.all) {
        final key = firstUseTipPrefKey(id);
        if (prefs.getBool(key) ?? false) {
          dismissed[key] = true;
        }
      }
    });
    return storage;
  }

  bool isDismissed(String tipId) {
    return _dismissed[firstUseTipPrefKey(tipId)] ?? false;
  }

  void dismiss(String tipId) {
    final key = firstUseTipPrefKey(tipId);
    _dismissed[key] = true;
    if (!_persistToSharedPreferences) {
      return;
    }
    if (_prefs != null) {
      _prefs!.setBool(key, true);
      return;
    }
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      prefs.setBool(key, true);
    });
  }
}

/// Records dismissed tip ids; construct per test or use [defaultStore] in app code.
class FirstUseTipStore {
  FirstUseTipStore(this._storage);

  final FirstUseTipDismissStorage _storage;

  static FirstUseTipStore? _defaultStore;

  static FirstUseTipStore get defaultStore {
    return _defaultStore ??= FirstUseTipStore(
      FirstUseTipDismissStorage.createLazySharedPreferences(),
    );
  }

  /// Tests: share [dismissedMap] across multiple store instances.
  factory FirstUseTipStore.inMemory([Map<String, bool>? dismissedMap]) {
    return FirstUseTipStore(
      FirstUseTipDismissStorage.inMemory(dismissedMap ?? {}),
    );
  }

  FirstUseTipPhase firstUseTip(String id) {
    return _storage.isDismissed(id) ? FirstUseTipPhase.hidden : FirstUseTipPhase.shown;
  }

  void dismiss(String id) {
    _storage.dismiss(id);
  }

  bool isDismissed(String id) => _storage.isDismissed(id);
}

FirstUseTipStore resolveFirstUseTipStore(FirstUseTipStore? provided) {
  return provided ?? FirstUseTipStore.defaultStore;
}

String firstUseTipSentence(String tipId) {
  switch (tipId) {
    case FirstUseTipIds.games:
      return FirstUseTipCopy.games;
    case FirstUseTipIds.gamification:
      return FirstUseTipCopy.gamification;
    case FirstUseTipIds.polie:
      return FirstUseTipCopy.polie;
    case FirstUseTipIds.features:
      return FirstUseTipCopy.features;
    default:
      return '';
  }
}

class FirstUseTip extends StatelessWidget {
  const FirstUseTip({
    super.key,
    required this.store,
    required this.tipId,
    required this.sentence,
    this.onDismiss,
  });

  final FirstUseTipStore store;
  final String tipId;
  final String sentence;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    if (store.firstUseTip(tipId) == FirstUseTipPhase.hidden) {
      return const SizedBox.shrink(key: ValueKey('phase-hidden'));
    }

    return Material(
      key: const ValueKey('phase-shown'),
      color: PanAfricanColors.primary.withOpacity(0.08),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.md,
          vertical: PanAfricanSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                sentence,
                style: PanAfricanTypography.bodyMedium(context).copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(width: PanAfricanSpacing.sm),
            Semantics(
              label: 'Dismiss tip',
              button: true,
              child: SizedBox(
                width: PanAfricanSpacing.xxl,
                height: PanAfricanSpacing.xxl,
                child: TextButton(
                  onPressed: () {
                    store.dismiss(tipId);
                    onDismiss?.call();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: PanAfricanColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: Size(PanAfricanSpacing.xxl, PanAfricanSpacing.xxl),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Dismiss'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
