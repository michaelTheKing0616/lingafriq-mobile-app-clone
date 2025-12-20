import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/primary_button.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';

import '../../widgets/audio_player_widget.dart';
import '../../widgets/top_gradient_box_builder.dart';
import '../widgets/points_and_profile_image_builder.dart';
import '../widgets/portrait_video_player.dart';

class TutorialDetailScreen extends ConsumerWidget {
  final String title;
  final String? text;
  final String? audio;
  final String? video;
  final String? image;
  final String endpointToHit;
  final bool isCompleted;
  const TutorialDetailScreen({
    Key? key,
    required this.title,
    required this.text,
    required this.audio,
    required this.video,
    required this.image,
    required this.endpointToHit,
    this.isCompleted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(apiProvider.select((value) => value.isLoading));
    return LoadingOverlayPro(
      isLoading: isLoading,
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TopGradientBox(
              borderRadius: 0,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BackButton(color: Colors.white),
                      title.text.xl2.semiBold.maxLines(2).ellipsis.color(Colors.white).make().p16(),
                    ],
                  ).expand(),
                  PointsAndProfileImageBuilder(
                    size: Size(0.07.sh, 0.07.sh),
                  ),
                  16.widthBox,
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((audio != null && audio!.isNotEmpty))
                  AudioPlayerWidget(audioUrl: audio!).pOnly(top: 8),
                if ((video != null && video!.isNotEmpty))
                  Card(
                    color: context.isDarkMode ? context.cardColor : Colors.white,
                    elevation: 12,
                    shadowColor: Colors.black38,
                    child: PortraitPlayerPage(videoUrl: video!),
                  ).px16().py8(),
                if ((image != null && image!.isNotEmpty))
                  Card(
                    color: context.isDarkMode ? context.cardColor : Colors.white,
                    elevation: 12,
                    shadowColor: Colors.black38,
                    child: CachedNetworkImage(
                      imageUrl: image!,
                      placeholder: kImagePlaceHolder,
                      errorWidget: kErrorWidget,
                    ).cornerRadius(kBorderRadius),
                  ).px16(),
                if ((text != null && text!.isNotEmpty))
                  Card(
                    color: context.isDarkMode ? context.cardColor : Colors.white,
                    elevation: 12,
                    shadowColor: Colors.black38,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        double.infinity.widthBox,
                        text!.text.xl.make(),
                      ],
                    ).p12(),
                  ).px16(),
              ],
            ).scrollVertical().expand(),
            4.heightBox,
            PrimaryButton(
              width: 0.6.sw,
              onTap: () async {
                if (video != null && video!.isNotEmpty) {
                  ref.read(betterPlayerController(video!)).pause();
                }

                bool result = true;
                if (!isCompleted) {
                  result = await ref.read(apiProvider.notifier).markAsComplete(endpointToHit);
                }
                if (result) {
                  Navigator.of(context).pop(true);
                }
              },
              text: "Continue",
            ).centered().safeArea(top: false),
            16.heightBox,
          ],
        ),
      ),
    );
  }
}
