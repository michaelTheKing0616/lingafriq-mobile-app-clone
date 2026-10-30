import 'package:flutter/material.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/guardian/consent_screen.dart';
import 'package:lingafriq/screens/guardian/family_tools_section.dart';
import 'package:lingafriq/services/guardian_link_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// Single source for every ~48dp tap target in this screen (buttons, the
/// mode-toggle segments). Delegates to the real shared design-system token
/// (`AdaptiveLayout.minTouchTarget`, `lib/utils/pan_african_design_system.dart`)
/// instead of inventing a new one, so this screen can't silently drift from
/// the app-wide minimum.
const double _minTouchTarget = AdaptiveLayout.minTouchTarget;

/// Inline button/segment spinners and icons scale with the text or chip next
/// to them, not with [_minTouchTarget], so they get their own named sizes
/// rather than reusing it or staying as unexplained literals.
const double _inlineSpinnerSizeSmall = 18; // invite-create button icon slot
const double _inlineSpinnerSizeLarge = 22; // link-learner submit button
const double _toggleIconSize = 20; // AppBar mode-toggle segment icon
const double _emptyStateIconSize = 40; // empty-hub panel icon

/// Shared duration for every state/visibility cross-fade in this screen
/// (hub sub-states, offline banner, guardian/invite mode switch) so they
/// all feel like one consistent motion language rather than three
/// independently-tuned animations. Zero'd out at every call site when
/// `MediaQuery.disableAnimationsOf(context)` is true.
const Duration _crossFadeDuration = Duration(milliseconds: 220);

/// Slightly longer than [_crossFadeDuration] on purpose: this is a one-shot
/// "panel has arrived" entrance for the empty-hub illustration, not a
/// state-to-state transition, so it's allowed its own pace.
const Duration _emptyPanelScaleInDuration = Duration(milliseconds: 280);

/// Body copy under a title reads better with slightly looser line height
/// than the design system's single-line defaults; used for both the
/// section subtitle and the empty-hub body text.
const double _bodyTextLineHeight = 1.45;

/// Extra breathing room between characters in the monospace invite code so
/// it reads like a code to copy, not a run-on word.
const double _inviteCodeLetterSpacing = 0.5;

/// Thinner than Material's 4.0 default so the spinner fits inline next to
/// button label text instead of dominating it.
const double _inlineSpinnerStrokeWidth = 2;

/// Starting scale for the empty-hub panel's one-shot entrance — subtle
/// enough to read as a settle-in, not a bounce.
const double _emptyPanelScaleInBegin = 0.92;

/// Copy keys: guardian.link.title, guardian.hub.empty (P9-913).
/// Reference: Apple Family / Google Family Link hub hierarchy.
class GuardianLinkScreen extends HookConsumerWidget {
  const GuardianLinkScreen({
    super.key,
    this.guardianLinkService,
    this.initialChildInviteMode = false,
  });

  final GuardianLinkService? guardianLinkService;
  final bool initialChildInviteMode;

  static const String guardianLinkTitle = 'Family hub';
  static const String guardianHubEmptyTitle = 'Link a learner you support';
  static const String guardianHubEmptyBody =
      'When a young learner needs approval, they share an invite code with you. '
      'You review consent here before chat, Village, or purchases turn on.';
  static const String guardianInviteSectionTitle = 'Learner waiting for you?';
  static const String guardianAcceptInviteHint =
      'Paste the invite code from their LingAfriq app.';
  static const String guardianYourNameHint = 'Your name (shown to the learner)';
  static const String childInviteTitle = 'Share with your guardian';
  static const String childInviteBody =
      'Copy this code and send it to a parent or guardian. It expires in seven days.';
  static const String offlineBanner =
      'You are offline. We will sync guardian actions when you are back online.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = guardianLinkService ?? GuardianLinkService();
    final colorScheme = Theme.of(context).colorScheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    final showChildInvite = useState(initialChildInviteMode);
    final hubState = useState(GuardianLinkUiState.loading);
    final links = useState<List<GuardianHubLink>>([]);
    final errorMessage = useState<String?>(null);
    final inviteToken = useState<String?>(null);
    final inviteExpires = useState<DateTime?>(null);
    final inviteLoading = useState(false);
    final inviteErrorMessage = useState<String?>(null);
    final acceptTokenController = useTextEditingController();
    final guardianNameController = useTextEditingController();
    final acceptSubmitting = useState(false);
    final acceptResult = useState<GuardianSubmitState?>(null);
    final isOffline = useState(false);

    // Rebuild on every keystroke in either field so "Link learner" only
    // enables once both are filled in — avoids a round-trip that can only
    // ever fail (AC: validate at the boundary, no silent/empty submits).
    useListenable(
      Listenable.merge([acceptTokenController, guardianNameController]),
    );
    final canSubmitAccept =
        acceptTokenController.text.trim().isNotEmpty &&
        guardianNameController.text.trim().isNotEmpty;

    Future<void> loadHub() async {
      hubState.value = GuardianLinkUiState.loading;
      errorMessage.value = null;
      isOffline.value = false;
      try {
        await service.flushPending();
        final fetched = await service.fetchHubLinks();
        links.value = fetched;
        hubState.value = fetched.isEmpty
            ? GuardianLinkUiState.empty
            : GuardianLinkUiState.loaded;
      } on GuardianOfflineException {
        isOffline.value = true;
        hubState.value = links.value.isEmpty
            ? GuardianLinkUiState.offline
            : GuardianLinkUiState.loaded;
      } on GuardianApiException catch (e) {
        errorMessage.value =
            e.message ?? 'We could not load your family hub. Try again.';
        hubState.value = GuardianLinkUiState.error;
      } catch (_) {
        errorMessage.value = 'We could not load your family hub. Try again.';
        hubState.value = GuardianLinkUiState.error;
      }
    }

    useEffect(() {
      loadHub();
      return null;
    }, const []);

    Future<void> createInvite() async {
      inviteLoading.value = true;
      inviteToken.value = null;
      inviteErrorMessage.value = null;
      try {
        final state = await service.createChildInvite(
          onSuccess: (token, expires) {
            inviteToken.value = token;
            inviteExpires.value = expires;
          },
        );
        if (state == GuardianSubmitState.error) {
          inviteErrorMessage.value = isOffline.value
              ? 'You are offline. Invite codes need a connection — try again once you are back online.'
              : 'We could not create an invite right now. Try again in a moment.';
        }
      } finally {
        inviteLoading.value = false;
      }
    }

    Future<void> acceptInvite() async {
      if (!canSubmitAccept) return;
      acceptSubmitting.value = true;
      acceptResult.value = null;
      try {
        final state = await service.acceptInvite(
          inviteToken: acceptTokenController.text,
          guardianDisplayName: guardianNameController.text,
        );
        acceptResult.value = state;
        if (state == GuardianSubmitState.sent) {
          acceptTokenController.clear();
          guardianNameController.clear();
          await loadHub();
        }
      } finally {
        acceptSubmitting.value = false;
      }
    }

    void openConsent(GuardianHubLink link) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => GuardianConsentScreen(
            childUserId: link.childUserId,
            initialStatus: link.status,
            regime: link.regime,
            guardianLinkService: service,
            onChanged: loadHub,
          ),
        ),
      );
    }

    final childInviteSection = Column(
      key: const ValueKey('guardian-link-invite-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: childInviteTitle,
          subtitle: childInviteBody,
        ),
        SizedBox(height: PanAfricanSpacing.md.h),
        if (inviteToken.value == null)
          SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: _minTouchTarget.h),
              child: FilledButton.icon(
                onPressed: inviteLoading.value ? null : createInvite,
                icon: inviteLoading.value
                    ? SizedBox(
                        width: _inlineSpinnerSizeSmall.w,
                        height: _inlineSpinnerSizeSmall.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: _inlineSpinnerStrokeWidth,
                        ),
                      )
                    : const Icon(Icons.qr_code_2_outlined),
                label: const Text('Create invite code'),
              ),
            ),
          )
        else
          _InviteCodeCard(
            token: inviteToken.value!,
            expiresAt: inviteExpires.value,
            colorScheme: colorScheme,
          ),
        if (inviteErrorMessage.value != null) ...[
          SizedBox(height: PanAfricanSpacing.sm.h),
          Semantics(
            liveRegion: true,
            child: Text(
              inviteErrorMessage.value!,
              style: PanAfricanTypography.bodyMedium(
                context,
              ).copyWith(color: colorScheme.error),
            ),
          ),
        ],
      ],
    );

    Widget buildHubContent() {
      if (hubState.value == GuardianLinkUiState.loading) {
        return Semantics(
          label: 'Loading your family hub',
          child: Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.lg.w),
            child: const Center(child: CircularProgressIndicator()),
          ),
        );
      }
      if (hubState.value == GuardianLinkUiState.error) {
        return _ErrorPanel(
          message: errorMessage.value ?? 'Something went wrong.',
          onRetry: loadHub,
        );
      }
      if (hubState.value == GuardianLinkUiState.empty ||
          (hubState.value == GuardianLinkUiState.offline &&
              links.value.isEmpty)) {
        return _EmptyHubPanel(
          title: guardianHubEmptyTitle,
          body: guardianHubEmptyBody,
          colorScheme: colorScheme,
          animate: !reducedMotion,
        );
      }
      if (links.value.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Linked learners',
              style: PanAfricanTypography.titleMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: PanAfricanSpacing.sm.h),
            ...links.value.map(
              (link) => _LearnerLinkTile(
                link: link,
                onTap: () => openConsent(link),
                colorScheme: colorScheme,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.xl.h),
          ],
        );
      }
      return const SizedBox.shrink();
    }

    final guardianSection = Column(
      key: const ValueKey('guardian-link-hub-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cross-fades between loading/error/empty/loaded sub-states instead
        // of popping in/out abruptly — matches `limits_progress_screen`'s
        // AnimatedSwitcher + KeyedSubtree treatment, reduced-motion aware.
        AnimatedSwitcher(
          duration: reducedMotion ? Duration.zero : _crossFadeDuration,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(
            key: ValueKey(hubState.value),
            child: buildHubContent(),
          ),
        ),
        const _SectionHeader(
          title: guardianInviteSectionTitle,
          subtitle: guardianAcceptInviteHint,
        ),
        SizedBox(height: PanAfricanSpacing.sm.h),
        TextField(
          controller: acceptTokenController,
          enabled: !acceptSubmitting.value,
          textCapitalization: TextCapitalization.characters,
          autofillHints: const [AutofillHints.oneTimeCode],
          decoration: InputDecoration(
            labelText: 'Invite code',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
            ),
          ),
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: PanAfricanSpacing.sm.h),
        TextField(
          controller: guardianNameController,
          enabled: !acceptSubmitting.value,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          decoration: InputDecoration(
            labelText: guardianYourNameHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
            ),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: canSubmitAccept ? (_) => acceptInvite() : null,
        ),
        SizedBox(height: PanAfricanSpacing.md.h),
        SizedBox(
          width: double.infinity,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: _minTouchTarget.h),
            child: FilledButton(
              onPressed: (!canSubmitAccept || acceptSubmitting.value)
                  ? null
                  : acceptInvite,
              child: acceptSubmitting.value
                  ? SizedBox(
                      width: _inlineSpinnerSizeLarge.w,
                      height: _inlineSpinnerSizeLarge.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: _inlineSpinnerStrokeWidth,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Link learner'),
            ),
          ),
        ),
        if (acceptResult.value == GuardianSubmitState.queuedOffline) ...[
          SizedBox(height: PanAfricanSpacing.sm.h),
          Semantics(
            liveRegion: true,
            child: Text(
              'Saved on this device. We will finish linking when you are online.',
              style: PanAfricanTypography.bodyMedium(
                context,
              ).copyWith(color: colorScheme.primary),
            ),
          ),
        ],
        if (acceptResult.value == GuardianSubmitState.error) ...[
          SizedBox(height: PanAfricanSpacing.sm.h),
          Semantics(
            liveRegion: true,
            child: Text(
              'Check the code and your name, then try again.',
              style: PanAfricanTypography.bodyMedium(
                context,
              ).copyWith(color: colorScheme.error),
            ),
          ),
        ],
      ],
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.gfamHubTitle ?? guardianLinkTitle,
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: PanAfricanSpacing.sm.w),
            child: _ModeToggle(
              showChildInvite: showChildInvite.value,
              onChanged: (value) => showChildInvite.value = value,
            ),
          ),
        ],
      ),
      body: ResponsiveSafeArea(
        child: RefreshIndicator(
          onRefresh: loadHub,
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.lg.w,
              vertical: PanAfricanSpacing.md.h,
            ),
            children: [
              // Cross-fades the offline banner in/out rather than having it
              // pop in abruptly on the next frame after a failed refresh.
              AnimatedSwitcher(
                duration: reducedMotion ? Duration.zero : _crossFadeDuration,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: isOffline.value
                    ? _BannerChip(
                        key: const ValueKey('offline-banner-visible'),
                        icon: Icons.cloud_off_outlined,
                        label: offlineBanner,
                        colorScheme: colorScheme,
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('offline-banner-hidden'),
                      ),
              ),
              AnimatedSwitcher(
                duration: reducedMotion ? Duration.zero : _crossFadeDuration,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: showChildInvite.value
                    ? childInviteSection
                    : guardianSection,
              ),
              if (!showChildInvite.value)
                FamilyToolsSection(
                  activeChildIds: [
                    for (final link in links.value)
                      if (link.status == 'active') link.childUserId,
                  ],
                  childNames: {
                    for (final link in links.value)
                      if (link.childName != null)
                        link.childUserId: link.childName!,
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact segmented control that replaces the AppBar's plain text toggle.
/// Each segment keeps a >=48dp tap target and announces its selected state.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.showChildInvite, required this.onChanged});

  final bool showChildInvite;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(PanAfricanRadius.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeToggleSegment(
            tooltip:
                AppLocalizations.of(context)?.gfamModeHub ?? 'Guardian hub',
            icon: Icons.family_restroom_outlined,
            selected: !showChildInvite,
            semanticsLabel:
                AppLocalizations.of(context)?.gfamModeHubLabel ??
                'Guardian hub, show linked learners',
            onTap: () => onChanged(false),
          ),
          _ModeToggleSegment(
            tooltip:
                AppLocalizations.of(context)?.gfamModeInvite ??
                'Learner invite',
            icon: Icons.qr_code_2_outlined,
            selected: showChildInvite,
            semanticsLabel:
                AppLocalizations.of(context)?.gfamModeInviteLabel ??
                'Learner invite',
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ModeToggleSegment extends StatelessWidget {
  const _ModeToggleSegment({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.semanticsLabel,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: selected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(PanAfricanRadius.pill),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(PanAfricanRadius.pill),
            child: SizedBox(
              width: _minTouchTarget.w,
              height: _minTouchTarget.h,
              child: Center(
                child: ExcludeSemantics(
                  child: Icon(
                    icon,
                    size: _toggleIconSize.sp,
                    color: foreground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          // `titleLarge` is already FontWeight.w700 — no override needed here.
          title,
          style: PanAfricanTypography.titleLarge(context),
        ),
        SizedBox(height: PanAfricanSpacing.xs.h),
        Text(
          subtitle,
          style: PanAfricanTypography.bodyMedium(context).copyWith(
            color: colorScheme.onSurfaceVariant,
            height: _bodyTextLineHeight,
          ),
        ),
      ],
    );
  }
}

class _EmptyHubPanel extends StatelessWidget {
  const _EmptyHubPanel({
    required this.title,
    required this.body,
    required this.colorScheme,
    required this.animate,
  });

  final String title;
  final String body;
  final ColorScheme colorScheme;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: EdgeInsets.all(PanAfricanSpacing.lg.w),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.shield_outlined,
              size: _emptyStateIconSize.sp,
              color: colorScheme.primary,
            ),
          ),
          SizedBox(height: PanAfricanSpacing.md.h),
          Text(title, style: PanAfricanTypography.titleMedium(context)),
          SizedBox(height: PanAfricanSpacing.sm.h),
          Text(
            body,
            style: PanAfricanTypography.bodyMedium(context).copyWith(
              color: colorScheme.onSurfaceVariant,
              height: _bodyTextLineHeight,
            ),
          ),
        ],
      ),
    );

    final presented = !animate
        ? content
        : TweenAnimationBuilder<double>(
            tween: Tween(begin: _emptyPanelScaleInBegin, end: 1),
            duration: _emptyPanelScaleInDuration,
            curve: Curves.easeOutCubic,
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: content,
          );

    return Semantics(container: true, label: '$title. $body', child: presented);
  }
}

class _LearnerLinkTile extends StatelessWidget {
  const _LearnerLinkTile({
    required this.link,
    required this.onTap,
    required this.colorScheme,
  });

  final GuardianHubLink link;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final statusLabel = switch (link.status) {
      'active' => l.gfamStatusActive,
      'verifying' => l.gfamStatusVerifying,
      'withdrawn' => l.gfamStatusWithdrawn,
      _ => link.status,
    };
    final name = link.childName ?? l.gapLearnerFallback;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      // `container: true` + an explicit `onTap` give this node its own
      // boundary with our descriptive label and the tap action, instead of
      // the label floating off into an unrelated scroll-view ancestor while
      // the tappable ListTile announces its own (less clear) auto label.
      container: true,
      button: true,
      label: '$name, $statusLabel',
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm.h),
        child: ExcludeSemantics(
          child: ListTile(
            minVerticalPadding: PanAfricanSpacing.sm,
            contentPadding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.md.w,
              vertical: PanAfricanSpacing.xs.h,
            ),
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.person_outline,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(name),
            subtitle: Text('$statusLabel · ${link.regime ?? 'Policy'}'),
            trailing: Icon(isRtl ? Icons.chevron_left : Icons.chevron_right),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({
    required this.token,
    required this.expiresAt,
    required this.colorScheme,
  });

  final String token;
  final DateTime? expiresAt;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final expiryLabel = expiresAt == null
        ? null
        : MaterialLocalizations.of(
            context,
          ).formatShortDate(expiresAt!.toLocal());
    return Semantics(
      container: true,
      label: expiryLabel == null
          ? 'Invite code $token'
          : 'Invite code $token. Expires $expiryLabel.',
      child: Container(
        padding: EdgeInsets.all(PanAfricanSpacing.lg.w),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Horizontal scroll keeps the full code selectable/copyable
            // without clipping on narrow screens or at large text scales.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ExcludeSemantics(
                child: SelectableText(
                  token,
                  style: PanAfricanTypography.titleMedium(context).copyWith(
                    fontFamily: 'monospace',
                    letterSpacing: _inviteCodeLetterSpacing,
                  ),
                ),
              ),
            ),
            if (expiryLabel != null) ...[
              SizedBox(height: PanAfricanSpacing.xs.h),
              ExcludeSemantics(
                child: Text(
                  'Expires $expiryLabel',
                  style: PanAfricanTypography.bodySmall(
                    context,
                  ).copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
            SizedBox(height: PanAfricanSpacing.md.h),
            SizedBox(
              width: double.infinity,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: _minTouchTarget.h),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: token));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite code copied')),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copy code'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerChip extends StatelessWidget {
  const _BannerChip({
    super.key,
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    // `liveRegion: true` so a screen reader announces connectivity changes as
    // they happen, instead of a guardian only discovering they're offline by
    // noticing an invite/accept action silently failed later. Matches the
    // same pattern already used by `_OfflineBanner` in the sibling
    // `limits_progress_screen.dart`.
    return Semantics(
      liveRegion: true,
      label: label,
      child: Padding(
        padding: EdgeInsets.only(bottom: PanAfricanSpacing.md.h),
        child: Material(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          child: Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.md.w),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(icon, color: colorScheme.onErrorContainer),
                ),
                SizedBox(width: PanAfricanSpacing.sm.w),
                Expanded(
                  child: ExcludeSemantics(
                    child: Text(
                      label,
                      style: PanAfricanTypography.bodySmall(
                        context,
                      ).copyWith(color: colorScheme.onErrorContainer),
                    ),
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

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message, style: PanAfricanTypography.bodyLarge(context)),
        SizedBox(height: PanAfricanSpacing.md.h),
        SizedBox(
          width: double.infinity,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: _minTouchTarget.h),
            child: FilledButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ),
        ),
      ],
    );
  }
}
