import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/features/global_chat/global_chat_policy.dart';
import 'package:lingafriq/providers/age_policy_provider.dart';

class _Age extends AgePolicyNotifier {
  _Age(this.s);
  final AgePolicyState? s;
  @override
  Future<AgePolicyState> build() async {
    if (s == null) throw StateError('no policy');
    return s!;
  }
}

class _Pending extends AgePolicyNotifier {
  @override
  Future<AgePolicyState> build() => Completer<AgePolicyState>().future;
}

Future<GlobalChatAccess> _access(AgePolicyNotifier Function() n) async {
  final c = ProviderContainer(overrides: [agePolicyProvider.overrideWith(n)]);
  addTearDown(c.dispose);
  c.listen(globalChatAccessProvider, (_, _) {});
  await c
      .read(agePolicyProvider.future)
      .catchError(
        (_) => const AgePolicyState(ageBand: null, socialSurfacesBlocked: true),
      );
  return c.read(globalChatAccessProvider);
}

void main() {
  test('the single policy constant admits adults only', () {
    expect(kGlobalChatAllowedBands, {ChatAgeBand.adult});
  });

  test('bands map to access with the default policy', () {
    expect(globalChatAccessFor('adult'), GlobalChatAccess.allowed);
    expect(globalChatAccessFor(' Adult '), GlobalChatAccess.allowed);
    expect(globalChatAccessFor('teen'), GlobalChatAccess.deniedTeen);
    expect(globalChatAccessFor('child'), GlobalChatAccess.deniedChild);
    expect(globalChatAccessFor(null), GlobalChatAccess.deniedUnknown);
    expect(globalChatAccessFor('unknown'), GlobalChatAccess.deniedUnknown);
    expect(
      globalChatAccessFor('adult', serverBlocksSocial: true),
      GlobalChatAccess.deniedUnknown,
    );
  });

  test('changing the constant is the only switch needed', () {
    expect(
      globalChatAccessFor(
        'teen',
        allowed: {ChatAgeBand.adult, ChatAgeBand.teen},
      ),
      GlobalChatAccess.allowed,
    );
    expect(
      globalChatAccessFor(
        'child',
        allowed: {ChatAgeBand.adult, ChatAgeBand.teen},
      ),
      GlobalChatAccess.deniedChild,
    );
  });

  test('provider: adult allowed, entry visible', () async {
    final c = ProviderContainer(
      overrides: [
        agePolicyProvider.overrideWith(
          () => _Age(
            const AgePolicyState(
              ageBand: 'adult',
              socialSurfacesBlocked: false,
            ),
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    await c.read(agePolicyProvider.future);
    expect(c.read(globalChatAccessProvider), GlobalChatAccess.allowed);
    expect(c.read(globalChatEntryVisibleProvider), isTrue);
  });

  test('provider: teen and child are denied and the entry is hidden', () async {
    for (final (band, want) in [
      ('teen', GlobalChatAccess.deniedTeen),
      ('child', GlobalChatAccess.deniedChild),
    ]) {
      final got = await _access(
        () => _Age(AgePolicyState(ageBand: band, socialSurfacesBlocked: true)),
      );
      expect(got, want, reason: band);
    }
  });

  test('provider fails closed while loading and on error', () async {
    final c = ProviderContainer(
      overrides: [agePolicyProvider.overrideWith(_Pending.new)],
    );
    addTearDown(c.dispose);
    expect(c.read(globalChatAccessProvider), GlobalChatAccess.checking);
    expect(c.read(globalChatEntryVisibleProvider), isFalse);

    expect(await _access(() => _Age(null)), GlobalChatAccess.deniedUnknown);
  });
}
