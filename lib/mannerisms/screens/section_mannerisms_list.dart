import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/mannerisms/models/mannerism_response.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/error_widet.dart';
import 'package:lingafriq/widgets/language_type_header_builder.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';

import '../../detail_types/tutorial_detail_screen.dart';
import '../../providers/navigation_provider.dart';
import '../../utils/api.dart';
import '../../widgets/info_widget.dart';
import '../../widgets/loading_builder.dart';
import '../models/mannerism_tutorial_model.dart';

final mannerismTutorialsProvider =
    FutureProvider.autoDispose.family<List<MannerismTutorialModel>, int>((ref, id) {
  return ref.read(apiProvider.notifier).getMannerismTutorials(id);
});

class MannerismSectionsListScreen extends ConsumerWidget {
  final Mannerism mannerism;
  const MannerismSectionsListScreen({
    Key? key,
    required this.mannerism,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mannerismTutorialsAsync = ref.watch(mannerismTutorialsProvider(mannerism.id));
    return Scaffold(
      body: mannerismTutorialsAsync.when(
        data: (mannerismTutorials) {
          return Column(
            children: [
              TopGradientBox(
                borderRadius: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BackButton(color: Colors.white),
                    // PointsAndProfileImageBuilder(size: Size(0.1.sh, 0.1.sh)),
                    LangguageTypeHeaderBuilder(
                      title: "Mannerisms",
                      level: '',
                      count: mannerismTutorials.length,
                      points: mannerismTutorials.sum((p0) => p0.score).toInt(),
                      allCount: mannerismTutorials.length,
                      type: "",
                      completed: mannerismTutorials.where((e) => e.isCompleted(ref)).length,
                    ),
                  ],
                ),
              ),
              if (mannerismTutorials.isEmpty)
                const InfoWidget(
                  text: "No Mannerism Found :(",
                  subText: "We're working to add some mannerisms for you.",
                ).expand(),
              if (mannerismTutorials.isNotEmpty)
                _MannerismTutorials(
                  mannerism: mannerism,
                  mannerismTutorials: mannerismTutorials,
                ).expand(),
            ],
          );
        },
        error: (e, s) {
          return StreamErrorWidget(
            error: e,
            onTryAgain: () {
              ref.invalidate(mannerismTutorialsProvider(mannerism.id));
            },
          );
        },
        loading: () => const LoadingBuilder(title: "Mannerisms"),
      ),
    );
  }
}

class _MannerismTutorials extends ConsumerWidget {
  final Mannerism mannerism;
  final List<MannerismTutorialModel> mannerismTutorials;

  const _MannerismTutorials({
    Key? key,
    required this.mannerism,
    required this.mannerismTutorials,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () {
        ref.invalidate(mannerismTutorialsProvider(mannerism.id));
        return Future.value();
      },
      child: ListView.builder(
        itemCount: mannerismTutorials.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final mannerismTutorial = mannerismTutorials[index];

          final isEnabled = (() {
            if (index == 0) {
              return true;
            }
            return mannerismTutorials[index - 1].completed ?? true;
          }).call();
          return _SectionMannerismItem(
            mannerismId: mannerism.id,
            mannerismTutorial: mannerismTutorial,
            enabled: isEnabled,
            onOpen: () async {
              int indexToOpen = index;
              do {
                final tutorial = mannerismTutorials[indexToOpen];
                final result = await openTutorialDetail(tutorial, ref);
                if (result != true) break;
                indexToOpen++;
              } while (indexToOpen != mannerismTutorials.length);
              ref.invalidate(mannerismTutorialsProvider(mannerism.id));
              if (indexToOpen == mannerismTutorials.length) {
                ref.read(navigationProvider).pop();
              }
            },
          );
        },
      ),
    );
  }

  Future<bool?> openTutorialDetail(MannerismTutorialModel mannerismTutorial, WidgetRef ref) async {
    return openTutorialScreen(mannerismTutorial, ref);
  }

  Future<bool?> openTutorialScreen(MannerismTutorialModel mannerismTutorial, WidgetRef ref) async {
    final tutorialScreen = TutorialDetailScreen(
      title: mannerismTutorial.title,
      text: mannerismTutorial.text,
      audio: mannerismTutorial.audio,
      video: mannerismTutorial.video,
      image: mannerismTutorial.image,
      endpointToHit: Api.completeMannerismLessons(mannerism.id, mannerismTutorial.id),
      isCompleted: mannerismTutorial.isCompleted(ref),
    );
    return await ref.read(navigationProvider).naviateTo(tutorialScreen);
  }
}

class _SectionMannerismItem extends ConsumerWidget {
  final int mannerismId;
  final MannerismTutorialModel mannerismTutorial;
  final bool enabled;
  final VoidCallback onOpen;
  const _SectionMannerismItem({
    Key? key,
    required this.mannerismId,
    required this.mannerismTutorial,
    required this.enabled,
    required this.onOpen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: context.isDarkMode ? context.cardColor : Colors.white,
      elevation: 12,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: enabled ? onOpen : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    mannerismTutorial.title.text.xl
                        .color(enabled ? context.adaptive : context.adaptive26)
                        .medium
                        .make(),
                    4.heightBox,
                    "Points • ${mannerismTutorial.score}"
                        .text
                        .color(enabled ? context.adaptive54 : context.adaptive26)
                        .maxLines(1)
                        .make(),
                  ],
                ).expand(),
                12.widthBox,
                if (mannerismTutorial.isCompleted(ref))
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: context.adaptive8),
                    child: Icon(
                      Icons.check,
                      color: context.primaryColor,
                    ),
                  )
              ],
            ),
            12.heightBox,
          ],
        ).p12(),
      ),
    ).pOnly(bottom: 12);
  }
}
