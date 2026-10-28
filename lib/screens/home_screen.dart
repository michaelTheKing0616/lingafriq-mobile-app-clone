import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/age_policy_provider.dart';
import 'package:lingafriq/providers/tab_scaffold_provider.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view_material3.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Root shell after sign-in (P1-022). Redirects restricted learners off social tab.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<AgePolicyState>>(agePolicyProvider, (previous, next) {
      next.whenData((policy) {
        if (!policy.socialSurfacesBlocked) return;
        final index = ref.read(tabIndexProvider);
        if (index == kSocialTabIndex) {
          ref.read(tabIndexProvider.notifier).setIndex(0);
        }
      });
    });
    return const TabsViewMaterial3();
  }
}

/// Tab index for bottom-nav Social (Language Villages) — hidden when restricted.
const int kSocialTabIndex = 3;

class AgeRestrictedSurfaceScreen extends StatelessWidget {
  const AgeRestrictedSurfaceScreen({
    super.key,
    this.showBack = false,
    this.serverMessage,
  });

  static const String title = 'Learning comes first';
  static const String body =
      'Private messages, calls, snaps, and the public feed unlock when you are 18 '
      'and your age is verified. Until then, keep going on lessons, games, and Polie.';

  final bool showBack;
  final String? serverMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: showBack
          ? AppBar(
              title: const Text('Not available yet'),
              leading: Semantics(
                label: 'Back to learning home',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                serverMessage ?? body,
                style: theme.textTheme.bodyLarge,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  if (showBack) {
                    Navigator.of(context).pop();
                    return;
                  }
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
                    (_) => false,
                  );
                },
                child: const Text('Back to learning'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Deep-link and named-route guard (AC2).
class AgePolicyRouteShell extends ConsumerWidget {
  const AgePolicyRouteShell({
    super.key,
    required this.child,
    this.showBack = true,
  });

  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(agePolicyProvider);
    return policy.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => AgeRestrictedSurfaceScreen(showBack: showBack),
      data: (state) {
        if (state.socialSurfacesBlocked) {
          return AgeRestrictedSurfaceScreen(
            showBack: showBack,
            serverMessage: state.serverMessage,
          );
        }
        return child;
      },
    );
  }
}

/// AC3 — map 403 age_restricted to the same explainer (never a generic crash).
void navigateAgeRestrictedExplainer(
  BuildContext context, {
  String? serverMessage,
  bool replace = false,
}) {
  final page = AgeRestrictedSurfaceScreen(
    showBack: true,
    serverMessage: serverMessage,
  );
  if (replace) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => page),
    );
    return;
  }
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

bool handleAgeRestrictedDioError(DioException error, BuildContext context) {
  final data = error.response?.data;
  if (error.response?.statusCode == 403 && isAgeRestrictedResponseBody(data)) {
    final message = data is Map ? data['message']?.toString() : null;
    navigateAgeRestrictedExplainer(context, serverMessage: message);
    return true;
  }
  return false;
}
