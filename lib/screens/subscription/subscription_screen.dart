import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/providers/subscription_provider.dart';
import 'package:lingafriq/screens/subscription/subscription_terms_disclosure.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart'
    show ageTierStatusProvider;
import 'package:lingafriq/services/connectivity_service.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';

/// Connectivity for the paywall (purchases need a connection; learning never).
final subscriptionOnlineProvider = FutureProvider.autoDispose<bool>(
  (ref) => ConnectivityService.hasInternet(),
);

/// Keeps Latin prices like "\$4.99" in one LTR run inside RTL sentences.
String _ltr(String s) => '\u2066$s\u2069';

const _navy = Color(0xFF2E3A87);
const _gold = Color(0xFFFFC53D);
const _goldText = Color(0xFF8C5A00);

/// LingAfriq Plus (paywall pack recipe): visible close, value first with a
/// "free forever" promise, plan cards with full store prices, a trial
/// timeline, the CTA with its fine print, then the auto-renewal disclosure
/// and Restore. Nothing in the app is locked behind Plus. Kids and teens see
/// a parent gate instead of prices.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  SubscriptionTier _plan = SubscriptionTier.premium;
  bool _parentOk = false;

  void _close() {
    HapticFeedback.lightImpact();
    Navigator.of(context).maybePop();
  }

  Future<void> _buy() async {
    HapticFeedback.mediumImpact();
    await ref.read(subscriptionProvider.notifier).subscribe(_plan);
  }

  Future<void> _restore() async {
    final l = l10nOf(context);
    final ok = await ref.read(subscriptionProvider.notifier).restorePurchases();
    if (!mounted) return;
    ok
        ? ErrorHandler.showSuccess(context, l.subRestored)
        : ErrorHandler.showError(context, l.subRestoreNone);
  }

  Future<void> _askParent() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _ParentGate(),
    );
    if (ok == true && mounted) setState(() => _parentOk = true);
  }

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final scheme = Theme.of(context).colorScheme;
    final sub = ref.watch(subscriptionProvider);
    final pricesAsync = ref.watch(storePricesProvider);
    // Riverpod retries failed providers; an error already seen wins.
    final pricesLoading = pricesAsync.isLoading && !pricesAsync.hasError;
    final prices = pricesAsync.value ?? StorePrices.fallback;
    final online = ref.watch(subscriptionOnlineProvider).value ?? true;
    final tier = ref.watch(ageTierStatusProvider).value?.tier?.toLowerCase();
    final minor = tier == 'child' || tier == 'teen';
    final hasPlus = sub.isActive && sub.tier != SubscriptionTier.free;
    final gated = minor && !_parentOk;
    final g = PanAfricanSpacing.md;

    final children = <Widget>[
      const _Hero(),
      SizedBox(height: g),
      _FreePromise(text: l.subFreeForever),
      if (!online) ...[
        SizedBox(height: PanAfricanSpacing.sm),
        _Note(
          key: const Key('sub-offline'),
          icon: Icons.cloud_off_rounded,
          text: l.subOffline,
        ),
      ],
      _Section(l.subWhatYouGet),
      _Benefits(
        items: [
          (Icons.download_for_offline_rounded, l.subBenefitOffline),
          (Icons.forum_rounded, l.subBenefitChat),
          (Icons.record_voice_over_rounded, l.subBenefitSpeaking),
          (Icons.block_rounded, l.subBenefitNoAds),
        ],
      ),
      if (hasPlus) ...[
        SizedBox(height: g),
        _Note(
          key: const Key('sub-current'),
          icon: Icons.verified_rounded,
          text: l.subYouHavePlus(_planName(l, sub.tier)),
        ),
      ] else if (gated) ...[
        SizedBox(height: g),
        _ParentCard(onAsk: _askParent),
      ] else ...[
        _Section(l.subChoosePlan),
        if (pricesLoading)
          const _PlanSkeleton()
        else ...[
          if (pricesAsync.hasError)
            Padding(
              padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
              child: _Note(
                key: const Key('sub-price-error'),
                icon: Icons.info_outline_rounded,
                text: l.subPriceError,
              ),
            ),
          _PlanCard(
            key: const Key('plan-premium'),
            title: l.subPlanMonthly,
            price: l.subPerMonth(_ltr(prices.premium)),
            detail: l.subPlanMonthlyDetail,
            tag: l.subMostPopular,
            selected: _plan == SubscriptionTier.premium,
            onTap: () => setState(() => _plan = SubscriptionTier.premium),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          _PlanCard(
            key: const Key('plan-family'),
            title: l.subPlanFamily,
            price: l.subPerMonth(_ltr(prices.family)),
            detail: l.subPlanFamilyDetail,
            selected: _plan == SubscriptionTier.family,
            onTap: () => setState(() => _plan = SubscriptionTier.family),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          _PlanCard(
            key: const Key('plan-lifetime'),
            title: l.subPlanLifetime,
            price: l.subOnce(_ltr(prices.lifetime)),
            detail: l.subPlanLifetimeDetail,
            selected: _plan == SubscriptionTier.lifetime,
            onTap: () => setState(() => _plan = SubscriptionTier.lifetime),
          ),
          if (prices.trialDays != null &&
              _plan == SubscriptionTier.premium) ...[
            _Section(l.subHowTrialWorks),
            _Timeline(days: prices.trialDays!, price: prices.premium),
          ],
        ],
      ],
      SizedBox(height: PanAfricanSpacing.lg),
      SubscriptionTermsDisclosure(
        renewsOn: sub.isActive && sub.tier != SubscriptionTier.lifetime
            ? sub.expiresAt
            : null,
      ),
      SizedBox(height: PanAfricanSpacing.xs),
      Center(
        child: TextButton(
          key: const Key('sub-restore'),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: online ? _restore : null,
          child: Text(l.subRestore),
        ),
      ),
    ];

    final showCta = !hasPlus && !gated && !pricesLoading;
    final fine = switch (_plan) {
      SubscriptionTier.lifetime => l.subFineOnce(_ltr(prices.lifetime)),
      SubscriptionTier.family => l.subFineMonthly(_ltr(prices.family)),
      _ =>
        prices.trialDays != null
            ? l.subFineTrial(prices.trialDays!, _ltr(prices.premium))
            : l.subFineMonthly(_ltr(prices.premium)),
    };
    final cta = switch (_plan) {
      SubscriptionTier.premium when prices.trialDays != null => l.subStartTrial(
        prices.trialDays!,
      ),
      SubscriptionTier.family => l.subGetFamily,
      SubscriptionTier.lifetime => l.subGetLifetime,
      _ => l.subGetPlus,
    };

    // Pinned on roomy screens; inline on short screens or large text so
    // it never covers half the page.
    final inlineCta =
        MediaQuery.textScalerOf(context).scale(10) > 13 ||
        MediaQuery.sizeOf(context).height < 640;
    final Widget ctaBar = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(g, PanAfricanSpacing.sm, g, g),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PanAfricanButton(
                  key: const Key('sub-cta'),
                  label: cta,
                  onPressed: online ? _buy : null,
                  backgroundColor: PanAfricanColors.primary,
                  foregroundColor: Colors.white,
                ),
                SizedBox(height: PanAfricanSpacing.xs),
                Text(
                  fine,
                  key: const Key('sub-fine'),
                  textAlign: TextAlign.center,
                  style: PanAfricanTypography.bodySmall(
                    context,
                  ).copyWith(color: scheme.onSurfaceVariant),
                ),
                TextButton(
                  key: const Key('sub-keep-free'),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
                  onPressed: _close,
                  child: Text(l.subKeepFree),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (showCta && inlineCta) {
      children.insert(
        children.length - 3,
        Padding(
          padding: EdgeInsets.only(top: PanAfricanSpacing.lg),
          child: ctaBar,
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const Key('sub-close'),
          tooltip: l.subClose,
          iconSize: 28,
          icon: const Icon(Icons.close_rounded),
          onPressed: _close,
        ),
        title: Text(
          l.subTitle,
          style: PanAfricanTypography.titleLarge(
            context,
          ).copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(g, 0, g, g),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showCta && !inlineCta) ctaBar,
          ],
        ),
      ),
    );
  }
}

String _planName(AppLocalizations l, SubscriptionTier t) => switch (t) {
  SubscriptionTier.family => l.subPlanFamily,
  SubscriptionTier.lifetime => l.subPlanLifetime,
  _ => l.subPlanMonthly,
};

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      top: PanAfricanSpacing.lg,
      bottom: PanAfricanSpacing.xs,
    ),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: PanAfricanTypography.titleMedium(context).copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ),
  );
}

/// Navy value card: cast character over a gold sunburst and the headline.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final big = MediaQuery.textScalerOf(context).scale(10) > 13;
    final art = SizedBox(
      width: 96,
      height: 112,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          const Positioned.fill(child: CustomPaint(painter: _Burst())),
          Image.asset(
            'assets/images/cast_still_Amara.png',
            height: 108,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => const SizedBox(),
          ),
        ],
      ),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.xs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: _gold,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            l.subPlusBadge,
            style: PanAfricanTypography.labelLarge(context).copyWith(
              color: const Color(0xFF3A2600),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(height: PanAfricanSpacing.xs),
        Semantics(
          header: true,
          child: Text(
            l.subHeadline,
            key: const Key('sub-headline'),
            style: PanAfricanTypography.headlineSmall(
              context,
            ).copyWith(color: Colors.white, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: big
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                art,
                SizedBox(height: PanAfricanSpacing.sm),
                text,
              ],
            )
          : Row(
              children: [
                art,
                SizedBox(width: PanAfricanSpacing.md),
                Expanded(child: text),
              ],
            ),
    );
  }
}

class _Burst extends CustomPainter {
  const _Burst();

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height * 0.45);
    final p = Paint()
      ..color = _gold.withValues(alpha: 0.35)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * 18,
        c + Offset(math.cos(a), math.sin(a)) * (s.width / 2),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FreePromise extends StatelessWidget {
  const _FreePromise({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('sub-free-forever'),
    padding: EdgeInsets.all(PanAfricanSpacing.sm),
    decoration: BoxDecoration(
      color: const Color(0xFFE6F4EA),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: PanAfricanColors.primary, width: 2),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.favorite_border_rounded,
          color: PanAfricanColors.primary,
        ),
        SizedBox(width: PanAfricanSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: PanAfricanTypography.bodyMedium(context).copyWith(
              color: const Color(0xFF0F3D22),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Benefits extends StatelessWidget {
  const _Benefits({required this.items});
  final List<(IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      key: const Key('sub-benefits'),
      children: [
        for (final (icon, text) in items)
          Padding(
            padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.xxs),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF1CC),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: _goldText, size: 22),
                ),
                SizedBox(width: PanAfricanSpacing.sm),
                Expanded(
                  child: Text(
                    text,
                    style: PanAfricanTypography.bodyMedium(
                      context,
                    ).copyWith(color: scheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.detail,
    required this.selected,
    required this.onTap,
    this.tag,
  });
  final String title, price, detail;
  final String? tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = selected ? PanAfricanColors.primary : scheme.outlineVariant;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: [title, price, detail, if (tag != null) tag!].join('. '),
      excludeSemantics: true,
      child: Material(
        color: selected ? const Color(0xFFEFF8F1) : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: selected ? 3 : 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.sm),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? PanAfricanColors.primary
                      : scheme.onSurfaceVariant,
                ),
                SizedBox(width: PanAfricanSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: PanAfricanSpacing.xs,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            title,
                            style: PanAfricanTypography.titleMedium(context)
                                .copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                ),
                          ),
                          if (tag != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _gold,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                tag!,
                                style: PanAfricanTypography.labelSmall(context)
                                    .copyWith(
                                      color: const Color(0xFF3A2600),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        price,
                        style: PanAfricanTypography.bodyLarge(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        detail,
                        style: PanAfricanTypography.bodySmall(
                          context,
                        ).copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Trial timeline: Today → reminder 2 days before → first charge.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.days, required this.price});
  final int days;
  final String price;

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final scheme = Theme.of(context).colorScheme;
    final remind = math.max(1, days - 2);
    final steps = [
      (Icons.lock_open_rounded, l.subStepToday, l.subStepTodayBody),
      (
        Icons.notifications_active_rounded,
        l.subStepDay(remind),
        l.subStepRemindBody,
      ),
      (
        Icons.event_rounded,
        l.subStepDay(days),
        l.subStepChargeBody(_ltr(price)),
      ),
    ];
    return Column(
      key: const Key('sub-timeline'),
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 40,
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == 0 ? _gold : const Color(0xFFFFF1CC),
                        ),
                        child: Icon(steps[i].$1, size: 20, color: _goldText),
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 4,
                            color: const Color(0xFFFFE08A),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: PanAfricanSpacing.sm),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].$2,
                          style: PanAfricanTypography.titleSmall(context)
                              .copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                        ),
                        Text(
                          steps[i].$3,
                          style: PanAfricanTypography.bodySmall(
                            context,
                          ).copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlanSkeleton extends StatelessWidget {
  const _PlanSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.surfaceContainerHighest;
    final l = l10nOf(context);
    return Semantics(
      key: const Key('sub-loading'),
      label: l.subLoading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Column(
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                height: 84,
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ParentCard extends StatelessWidget {
  const _ParentCard({required this.onAsk});
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('sub-parent'),
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFE9ECFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _navy.withValues(alpha: 0.35), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.family_restroom_rounded, color: _navy),
              SizedBox(width: PanAfricanSpacing.xs),
              Expanded(
                child: Text(
                  l.subParentTitle,
                  style: PanAfricanTypography.titleMedium(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.xs),
          Text(
            l.subParentBody,
            style: PanAfricanTypography.bodyMedium(
              context,
            ).copyWith(color: scheme.onSurface),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          OutlinedButton(
            key: const Key('sub-ask-parent'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: onAsk,
            child: Text(l.subAskParent),
          ),
        ],
      ),
    );
  }
}

/// Adult check before showing prices to a minor (pack rule 6).
class _ParentGate extends StatefulWidget {
  const _ParentGate();

  @override
  State<_ParentGate> createState() => _ParentGateState();
}

class _ParentGateState extends State<_ParentGate> {
  final _c = TextEditingController();
  bool _wrong = false;
  static const _a = 17, _b = 6;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _check() {
    if (int.tryParse(_c.text.trim()) == _a * _b) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _wrong = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    return AlertDialog(
      title: Text(l.subGateTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.subGateQuestion(_a, _b)),
          TextField(
            key: const Key('sub-gate-answer'),
            controller: _c,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              errorText: _wrong ? l.subGateWrong : null,
            ),
            onSubmitted: (_) => _check(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.subCancel),
        ),
        FilledButton(
          key: const Key('sub-gate-ok'),
          onPressed: _check,
          child: Text(l.subGateContinue),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          SizedBox(width: PanAfricanSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: PanAfricanTypography.bodySmall(
                context,
              ).copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
