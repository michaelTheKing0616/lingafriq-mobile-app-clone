import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/error_widet.dart';
import 'package:lingafriq/widgets/info_widget.dart';
import 'package:lingafriq/widgets/language_type_header_builder.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';

import '../../widgets/loading_builder.dart';
import '../models/mannerism_response.dart';
import 'section_mannerisms_list.dart';

final mannerismsListProvider = FutureProvider.autoDispose.family<MannerismResponse, int>((ref, id) {
  return ref.read(apiProvider.notifier).getMannerisms(id);
});

class MannerismsListScreen extends ConsumerWidget {
  final Language language;
  const MannerismsListScreen({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mannerismAsync = ref.watch(mannerismsListProvider(language.id));
    return Scaffold(
      body: mannerismAsync.when(
        data: (mannerismResponse) {
          return Column(
            children: [
              TopGradientBox(
                borderRadius: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BackButton(color: Colors.white),
                    0.025.sh.heightBox,
                    LangguageTypeHeaderBuilder(
                      title: "Sections",
                      level: "",
                      count: mannerismResponse.results
                          .where((e) => e.mannerism_language == language.id)
                          .toList()
                          .length,
                      points: mannerismResponse.results
                          .where((e) => e.mannerism_language == language.id)
                          .sumBy((p0) => p0.score),
                      type: "Written & Oral",
                      completed: mannerismResponse.results
                          .where((e) => e.mannerism_language == language.id)
                          .where((e) => e.completed == e.count)
                          .toList()
                          .length,
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (context) {
                  final mannerisms = mannerismResponse.results
                      .where((e) => e.mannerism_language == language.id)
                      .toList();
                  if (mannerisms.isEmpty) {
                    return const InfoWidget(
                      text: "No Mannerism Sections",
                      subText: "We're working to add some mannerism sections for you.",
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () {
                      ref.invalidate(mannerismsListProvider(language.id));
                      return Future.value();
                    },
                    child: ListView.builder(
                      itemCount: mannerisms.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final mannerism = mannerisms[index];
                        final isEnabled = (() {
                          if (index == 0) {
                            return true;
                          }
                          return mannerisms[index - 1].count == mannerisms[index - 1].completed;
                        }).call();
                        return _MannerismItem(
                          mannerism: mannerism,
                          enabled: isEnabled,
                        );
                      },
                    ),
                  );
                },
              ).expand(),
            ],
          );
        },
        error: (e, s) {
          return StreamErrorWidget(
            error: e,
            onTryAgain: () {
              ref.invalidate(mannerismsListProvider(language.id));
            },
          );
        },
        loading: () => const LoadingBuilder(title: "Sections"),
      ),
    );
  }
}

class _MannerismItem extends ConsumerWidget {
  final Mannerism mannerism;
  final bool enabled;
  const _MannerismItem({
    Key? key,
    required this.mannerism,
    required this.enabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: context.isDarkMode ? context.cardColor : Colors.white,
      elevation: 12,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: enabled
            ? () {
                ref
                    .read(navigationProvider)
                    .naviateTo(MannerismSectionsListScreen(mannerism: mannerism));
              }
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    mannerism.name.text.xl
                        .color(enabled ? context.adaptive : context.adaptive26)
                        .medium
                        .make(),
                    4.heightBox,
                    "${mannerism.count} Lessons • ${mannerism.score}"
                        .text
                        .color(enabled ? context.adaptive54 : context.adaptive26)
                        .maxLines(1)
                        .make(),
                  ],
                ).expand(),
                12.widthBox,
                if (mannerism.count == mannerism.completed)
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
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                color: enabled ? null : context.adaptive12,
                backgroundColor: enabled ? null : context.adaptive12,
                value: mannerism.count == 0 ? 1 : mannerism.completed / mannerism.count,
                minHeight: 6,
              ),
            ),
          ],
        ).p12(),
      ),
    ).pOnly(bottom: 12);
  }
}
