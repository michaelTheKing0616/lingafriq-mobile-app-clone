import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/guardian/consent_screen.dart';
import 'package:lingafriq/services/guardian_link_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    final showChildInvite = useState(initialChildInviteMode);
    final hubState = useState(GuardianLinkUiState.loading);
    final links = useState<List<GuardianHubLink>>([]);
    final errorMessage = useState<String?>(null);
    final inviteToken = useState<String?>(null);
    final inviteExpires = useState<DateTime?>(null);
    final inviteLoading = useState(false);
    final acceptTokenController = useTextEditingController();
    final guardianNameController = useTextEditingController();
    final acceptSubmitting = useState(false);
    final acceptResult = useState<GuardianSubmitState?>(null);
    final isOffline = useState(false);

    Future<void> loadHub() async {
      hubState.value = GuardianLinkUiState.loading;
      errorMessage.value = null;
      isOffline.value = false;
      try {
        await service.flushPending();
        final fetched = await service.fetchHubLinks();
        links.value = fetched;
        hubState.value = fetched.isEmpty ? GuardianLinkUiState.empty : GuardianLinkUiState.loaded;
      } on GuardianOfflineException {
        isOffline.value = true;
        hubState.value = links.value.isEmpty ? GuardianLinkUiState.offline : GuardianLinkUiState.loaded;
      } on GuardianApiException catch (e) {
        errorMessage.value = e.message ?? 'We could not load your family hub. Try again.';
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
      try {
        final state = await service.createChildInvite(
          onSuccess: (token, expires) {
            inviteToken.value = token;
            inviteExpires.value = expires;
          },
        );
        if (state == GuardianSubmitState.error) {
          errorMessage.value = 'We could not create an invite right now.';
        }
      } finally {
        inviteLoading.value = false;
      }
    }

    Future<void> acceptInvite() async {
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

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: Text(guardianLinkTitle),
        centerTitle: false,
        actions: [
          if (!showChildInvite.value)
            TextButton(
              onPressed: () => showChildInvite.value = true,
              child: const Text('Learner invite'),
            ),
          if (showChildInvite.value)
            TextButton(
              onPressed: () => showChildInvite.value = false,
              child: const Text('Guardian view'),
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
              if (isOffline.value)
                _BannerChip(
                  icon: Icons.cloud_off_outlined,
                  label: offlineBanner,
                  colorScheme: colorScheme,
                ),
              if (showChildInvite.value) ...[
                _SectionHeader(title: childInviteTitle, subtitle: childInviteBody),
                SizedBox(height: PanAfricanSpacing.md.h),
                if (inviteToken.value == null)
                  SizedBox(
                    height: 48.h,
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: inviteLoading.value ? null : createInvite,
                      icon: inviteLoading.value
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.qr_code_2_outlined),
                      label: const Text('Create invite code'),
                    ),
                  )
                else ...[
                  _InviteCodeCard(
                    token: inviteToken.value!,
                    expiresAt: inviteExpires.value,
                    colorScheme: colorScheme,
                  ),
                ],
              ] else ...[
                if (hubState.value == GuardianLinkUiState.loading)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                else if (hubState.value == GuardianLinkUiState.error)
                  _ErrorPanel(message: errorMessage.value ?? 'Something went wrong.', onRetry: loadHub)
                else if (hubState.value == GuardianLinkUiState.empty ||
                    (hubState.value == GuardianLinkUiState.offline && links.value.isEmpty))
                  _EmptyHubPanel(
                    title: guardianHubEmptyTitle,
                    body: guardianHubEmptyBody,
                    colorScheme: colorScheme,
                    animate: !reducedMotion,
                  )
                else if (links.value.isNotEmpty) ...[
                  Text(
                    'Linked learners',
                    style: PanAfricanTypography.titleMedium(context).copyWith(fontWeight: FontWeight.w700),
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
                _SectionHeader(
                  title: guardianInviteSectionTitle,
                  subtitle: guardianAcceptInviteHint,
                ),
                SizedBox(height: PanAfricanSpacing.sm.h),
                TextField(
                  controller: acceptTokenController,
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
                  decoration: InputDecoration(
                    labelText: guardianYourNameHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                ),
                SizedBox(height: PanAfricanSpacing.md.h),
                SizedBox(
                  height: 48.h,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: acceptSubmitting.value ? null : acceptInvite,
                    child: acceptSubmitting.value
                        ? SizedBox(
                            width: 22.w,
                            height: 22.w,
                            child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Link learner'),
                  ),
                ),
                if (acceptResult.value == GuardianSubmitState.queuedOffline) ...[
                  SizedBox(height: PanAfricanSpacing.sm.h),
                  Text(
                    'Saved on this device. We will finish linking when you are online.',
                    style: PanAfricanTypography.bodyMedium(context).copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
                if (acceptResult.value == GuardianSubmitState.error) ...[
                  SizedBox(height: PanAfricanSpacing.sm.h),
                  Text(
                    'Check the code and your name, then try again.',
                    style: PanAfricanTypography.bodyMedium(context).copyWith(color: colorScheme.error),
                  ),
                ],
              ],
            ],
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
          title,
          style: PanAfricanTypography.titleLarge(context).copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: PanAfricanSpacing.xs.h),
        Text(
          subtitle,
          style: PanAfricanTypography.bodyMedium(context).copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.45,
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
    return Semantics(
      container: true,
      label: '$title. $body',
      child: Container(
        padding: EdgeInsets.all(PanAfricanSpacing.lg.w),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, size: 40.sp, color: colorScheme.primary),
            SizedBox(height: PanAfricanSpacing.md.h),
            Text(title, style: PanAfricanTypography.titleMedium(context)),
            SizedBox(height: PanAfricanSpacing.sm.h),
            Text(
              body,
              style: PanAfricanTypography.bodyMedium(context).copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
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
    final statusLabel = switch (link.status) {
      'active' => 'Approved',
      'verifying' => 'Needs your consent',
      'withdrawn' => 'Consent withdrawn',
      _ => link.status,
    };
    return Semantics(
      button: true,
      label: 'Learner ${link.childUserId}, $statusLabel',
      child: Card(
        margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm.h),
        child: ListTile(
          minVerticalPadding: 12,
          contentPadding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.md.w,
            vertical: PanAfricanSpacing.xs.h,
          ),
          leading: CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.person_outline, color: colorScheme.onPrimaryContainer),
          ),
          title: Text('Learner #${link.childUserId}'),
          subtitle: Text('$statusLabel · ${link.regime ?? 'Policy'}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
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
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.lg.w),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectableText(
            token,
            style: PanAfricanTypography.titleMedium(context).copyWith(
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
          ),
          if (expiresAt != null) ...[
            SizedBox(height: PanAfricanSpacing.xs.h),
            Text(
              'Expires ${expiresAt!.toLocal()}',
              style: PanAfricanTypography.bodySmall(context).copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          SizedBox(height: PanAfricanSpacing.md.h),
          SizedBox(
            height: 48.h,
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
        ],
      ),
    );
  }
}

class _BannerChip extends StatelessWidget {
  const _BannerChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: PanAfricanSpacing.md.h),
      child: Material(
        color: colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.md.w),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.onErrorContainer),
              SizedBox(width: PanAfricanSpacing.sm.w),
              Expanded(
                child: Text(
                  label,
                  style: PanAfricanTypography.bodySmall(context),
                ),
              ),
            ],
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
      children: [
        Text(message),
        SizedBox(height: PanAfricanSpacing.sm.h),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}
