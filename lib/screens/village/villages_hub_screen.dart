import 'package:flutter/widgets.dart';
import 'package:lingafriq/navigation/hub_village.dart';

/// Village place list. Unbuilt places stay on a typed not-available page.
class VillagesHubScreen extends StatelessWidget {
  const VillagesHubScreen({
    super.key,
    this.status = VillageHubStatus.ready,
    this.audience = VillageAudience.adult,
    this.initialRoute = VillageRoutes.root,
    this.onRetry,
  });

  final VillageHubStatus status;
  final VillageAudience audience;
  final String initialRoute;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final NavigatorState? navigator = Navigator.maybeOf(context);
    final bool canClose = navigator?.canPop() ?? false;
    return VillageHub(
      status: status,
      audience: audience,
      initialRoute: initialRoute,
      onRetry: onRetry,
      onClose: canClose ? () => navigator?.pop() : null,
    );
  }
}
