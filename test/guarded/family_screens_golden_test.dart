import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/guardian/approvals_screen.dart';
import 'package:lingafriq/screens/guardian/family_tools_section.dart';
import 'package:lingafriq/screens/guardian/guardian_link_screen.dart';
import 'package:lingafriq/screens/guardian/messaging_explainer_screen.dart';
import 'package:lingafriq/screens/village/circles_screen.dart';
import 'package:lingafriq/services/guardian_link_service.dart';

import '../compliance/golden_kit.dart';

/// Readable (real-font) goldens for the Family hub and the screens it opens.
class _HubService extends GuardianLinkService {
  @override
  Future<void> flushPending() async {}

  @override
  Future<List<GuardianHubLink>> fetchHubLinks() async => [
    GuardianHubLink(childUserId: 42, status: 'active', regime: 'NDPA_2023'),
  ];
}

class _Approvals extends GuardianApprovalService {
  @override
  Future<List<GuardianGroupJoinRequestRow>> fetchApprovals() async => [
    GuardianGroupJoinRequestRow(
      requestId: 'r1',
      childUserId: 42,
      groupKind: 'classroom',
      groupName: 'Yoruba 201',
      memberCount: 12,
      adultMemberCount: 2,
      moderationStatus: 'moderated',
      status: 'pending',
      expiresAt: DateTime.utc(2026, 12, 1),
    ),
    GuardianGroupJoinRequestRow(
      requestId: 'r2',
      childUserId: 42,
      groupKind: 'circle',
      groupName: 'Study circle',
      memberCount: 5,
      adultMemberCount: 1,
      moderationStatus: 'open',
      status: 'approved',
    ),
  ];
}

class _ExplainerState extends GuardianMessagingExplainerService {
  _ExplainerState(this.mode);
  final String mode;
  @override
  Future<GuardianMessagingExplainer> fetchExplainer() {
    if (mode == 'loading')
      return Completer<GuardianMessagingExplainer>().future;
    if (mode == 'offline') throw const GuardianOfflineException();
    throw GuardianApiException(message: null);
  }
}

class _Explainer extends GuardianMessagingExplainerService {
  @override
  Future<GuardianMessagingExplainer> fetchExplainer() async =>
      GuardianMessagingExplainer(
        title: 'How messaging works',
        body:
            'Messages with learners under 18 are checked by safety filters '
            'before they are delivered.',
        moderatorsSee: const [
          'Reported messages',
          'Messages stopped by safety checks',
        ],
        e2eeTradeoff:
            'Chats with minors are not end-to-end encrypted so they can be '
            'checked for safety.',
      );
}

Future<Object?> _circles() async => {
  'ok': true,
  'circles': [
    {
      'id': 'c1',
      'name': 'Yoruba beginners',
      'status': 'open',
      'member_count': 12,
      'max_members': 50,
    },
    {
      'id': 'c2',
      'name': 'Swahili stories',
      'status': 'draft',
      'member_count': 3,
      'max_members': 50,
      'min_open': 5,
    },
  ],
};

void main() {
  setUpAll(
    () => loadComplianceFonts('test/guarded/family_screens_golden_test.dart'),
  );

  testWidgets('messaging guide and circles show Arabic copy, no English', (
    t,
  ) async {
    final ar = goldenVariants[1];
    await pumpVariant(
      t,
      ar,
      GuardianMessagingExplainerScreen(explainerService: _Explainer()),
    );
    expect(find.text('كيف تعمل الرسائل للمتعلمين الصغار'), findsOneWidget);
    expect(find.text('ما قد يراجعه المشرفون'), findsOneWidget);
    expect(find.text('Reported messages'), findsNothing);
    await pumpVariant(t, ar, const CirclesScreen(fetchCircles: _circles));
    expect(find.text('حلقاتك'), findsOneWidget);
    expect(find.text('12 من 50 أعضاء · مفتوحة'), findsOneWidget);
    expect(find.textContaining('members'), findsNothing);
  });

  testWidgets('messaging guide title wraps at 320 + 200% + Arabic', (t) async {
    await pumpVariant(
      t,
      goldenVariants.last,
      GuardianMessagingExplainerScreen(explainerService: _Explainer()),
    );
    final title = find.text('كيف تعمل الرسائل للمتعلمين الصغار');
    expect(t.renderObject<RenderParagraph>(title).didExceedMaxLines, isFalse);
    expect(
      find.descendant(of: find.byType(AppBar), matching: title),
      findsNothing,
    );
    expectNoLayoutErrors(t);
  });

  for (final v in [goldenVariants.first, goldenVariants.last]) {
    for (final mode in ['loading', 'error', 'offline']) {
      testWidgets('messaging guide $mode ${v.name}', (t) async {
        await pumpVariant(
          t,
          v,
          GuardianMessagingExplainerScreen(
            explainerService: _ExplainerState(mode),
          ),
          settle: mode != 'loading',
        );
        if (mode == 'loading') await t.pump(const Duration(milliseconds: 100));
        expectNoLayoutErrors(t);
        await expectLater(
          find.byType(GuardianMessagingExplainerScreen),
          matchesGoldenFile('goldens/messaging_guide_${mode}_${v.name}.png'),
        );
      });
    }
    final circleStates = <String, Future<Object?> Function()>{
      'loading': () => Completer<Object?>().future,
      'error': () async => {'ok': false},
      'offline': () async => throw Exception('offline'),
      'empty': () async => {'ok': true, 'circles': []},
    };
    circleStates.forEach((mode, fetch) {
      testWidgets('circles $mode ${v.name}', (t) async {
        await pumpVariant(
          t,
          v,
          CirclesScreen(fetchCircles: fetch),
          settle: mode != 'loading',
        );
        if (mode == 'loading') await t.pump(const Duration(milliseconds: 100));
        expectNoLayoutErrors(t);
        await expectLater(
          find.byType(CirclesScreen),
          matchesGoldenFile('goldens/circles_${mode}_${v.name}.png'),
        );
      });
    });
  }

  for (final v in goldenVariants) {
    testWidgets('family hub shows Family tools ${v.name}', (t) async {
      await pumpVariant(
        t,
        v,
        GuardianLinkScreen(guardianLinkService: _HubService()),
      );
      await t.scrollUntilVisible(
        find.byKey(const ValueKey('family-tools-circles')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await t.pumpAndSettle();
      expect(find.byType(FamilyToolsSection), findsOneWidget);
      expectNoLayoutErrors(t);
      await expectLater(
        find.byType(GuardianLinkScreen),
        matchesGoldenFile('goldens/family_hub_tools_${v.name}.png'),
      );
    });

    testWidgets('guardian approvals ${v.name}', (t) async {
      await pumpVariant(
        t,
        v,
        GuardianApprovalsScreen(approvalService: _Approvals()),
      );
      expect(find.text('Yoruba 201'), findsWidgets);
      expectNoLayoutErrors(t);
      await expectLater(
        find.byType(GuardianApprovalsScreen),
        matchesGoldenFile('goldens/guardian_approvals_${v.name}.png'),
      );
    });

    testWidgets('messaging guide ${v.name}', (t) async {
      await pumpVariant(
        t,
        v,
        GuardianMessagingExplainerScreen(explainerService: _Explainer()),
      );
      expect(
        find.text(
          v.locale.languageCode == 'ar'
              ? 'كيف تعمل الرسائل للمتعلمين الصغار'
              : 'Reported messages',
        ),
        findsOneWidget,
      );
      expectNoLayoutErrors(t);
      await expectLater(
        find.byType(GuardianMessagingExplainerScreen),
        matchesGoldenFile('goldens/messaging_guide_${v.name}.png'),
      );
    });

    testWidgets('circles ${v.name}', (t) async {
      await pumpVariant(t, v, const CirclesScreen(fetchCircles: _circles));
      expect(find.text('Yoruba beginners'), findsOneWidget);
      expectNoLayoutErrors(t);
      await expectLater(
        find.byType(CirclesScreen),
        matchesGoldenFile('goldens/circles_${v.name}.png'),
      );
    });
  }
}
