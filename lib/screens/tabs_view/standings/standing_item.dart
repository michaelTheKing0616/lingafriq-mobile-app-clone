import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:lingafriq/utils/utils.dart';

class StandingItem extends ConsumerWidget {
  final ProfileModel profile;
  final int index;
  const StandingItem({
    Key? key,
    required this.profile,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMe =
        ref.watch(userProvider.select((value) => value?.id ?? 0)) == profile.id;
    return Card(
      color: context.isDarkMode ? context.cardColor : Colors.white,
      elevation: 12,
      shadowColor: Colors.black38,
      shape: isMe
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: context.primaryColor, width: 2),
            )
          : null,
      child: Row(
        children: [
          InkWell(
            onTap: isMe
                ? () {
                    ref.read(tabIndexProvider.notifier).setIndex(3);
                  }
                : null,
            child: () {
              if (profile.avater != null) {
                return CachedNetworkImage(imageUrl: profile.avatarUrl);
              }
              return Image.asset(kAvatarsList.values.first);
            }.call(),
          ).expand(flex: 2),

          // if (profile.avater != null)
          //   CachedNetworkImage(imageUrl: profile.avatarUrl).expand(flex: 2),
          16.widthBox,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              profile.username.firstLetterUpperCase().text.xl.medium.make(),
              4.heightBox,
              InkWell(
                onTap: () {
                  ref.read(tabIndexProvider.notifier).setIndex(1);
                },
                child: profile.completed_point.text.xl2
                    .color(context.adaptive54)
                    .make(),
              ),
            ],
          ).expand(flex: 6),
          12.widthBox,
          if ((index + 1) < 4) ...[
            Image.asset(
              "assets/images/position_${index + 1}.png",
              width: 42,
              height: 42,
            ),
          ],
          Column(
            children: [
              Chip(
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                label:

     Text(toOrdinal(index + 1)),
              ),
              4.heightBox,
              if (kCountries.containsKey(profile.nationality))
                kCountries[profile.nationality]!.text.xl3.make(),
            ],
          ).expand(flex: 3)
        ],
      ).p12(),
    ).pOnly(bottom: 12);
  }

  String toOrdinal(int number) {
    if (number < 0) throw Exception('Invalid Number');

    if (number >= 11 && number <= 13) {
      return '${number}th';
    }

    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }
}
