import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/utils/utils.dart';

import '../providers/navigation_provider.dart';
import '../screens/tabs_view/profile/profile_tab.dart';
import '../screens/tabs_view/tabs_view.dart';

/// Opaque backdrop behind the header avatar.
const kHeaderAvatarDisc = Color(0xFFFFF4E0);

class PointsAndProfileImageBuilder extends ConsumerWidget {
  final Size? size;
  const PointsAndProfileImageBuilder({this.size, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(
      userProvider.select((value) => value?.completed_point ?? 0),
    );
    return SizedBox(
      key: ValueKey(points),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              ref.read(navigationProvider).popToFirstRoute();
              ref.read(tabIndexProvider.notifier).setIndex(3);
            },
            // A solid cream disc with a white ring keeps the avatar art
            // crisp on the saturated header gradient (the shared builder's
            // translucent fill made it look faded/placeholder-like).
            child: DecoratedBox(
              key: const Key('header-avatar-disc'),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kHeaderAvatarDisc,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ProfileImageBuilder(
                size: size ?? Size(0.1.sh, 0.1.sh),
                showEditIcon: false,
              ),
            ),
          ),
          8.heightBox,
          GestureDetector(
            onTap: () {
              ref.read(navigationProvider).popToFirstRoute();
              ref.read(tabIndexProvider.notifier).setIndex(2);
            },
            child: l10nOf(context)
                .pointsCount(points)
                .text
                .size(16.sp)
                .color(Colors.white)
                .semiBold
                .makeCentered(),
          ),
        ],
      ),
    );
  }
}
