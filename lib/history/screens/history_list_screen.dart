import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/error_widet.dart';
import 'package:lingafriq/widgets/info_widget.dart';
import 'package:lingafriq/widgets/language_type_header_builder.dart';
import 'package:lingafriq/widgets/loading_builder.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';

import '../../providers/navigation_provider.dart';
import '../models/history_response.dart';
import 'section_history_list.dart';

final historyListProvider = FutureProvider.autoDispose.family<HistoryResponse, int>((ref, id) {
  return ref.read(apiProvider.notifier).getHistory(id);
});

class HistoryListScreen extends ConsumerWidget {
  final Language language;
  const HistoryListScreen({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historiesAsync = ref.watch(historyListProvider(language.id));
    return Scaffold(
      body: historiesAsync.when(
        data: (historyResponse) {
          return Column(
            children: [
              TopGradientBox(
                borderRadius: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BackButton(color: Colors.white),
                    // 0.025.sh.heightBox,
                    // PointsAndProfileImageBuilder(size: Size(0.1.sh, 0.1.sh)),
                    LangguageTypeHeaderBuilder(
                      title: "Sections",
                      level: '',
                      count: historyResponse.results
                          .where((e) => e.history_language == language.id)
                          .toList()
                          .length,
                      points: historyResponse.results
                          .where((e) => e.history_language == language.id)
                          .sumBy((p0) => p0.score),
                      type: "Written & Oral",
                      completed: historyResponse.results
                          .where((e) => e.history_language == language.id)
                          .where((e) => e.completed == e.count)
                          .toList()
                          .length,
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (context) {
                  final histories = historyResponse.results
                      .where((e) => e.history_language == language.id)
                      .toList();
                  if (histories.isEmpty) {
                    return const InfoWidget(
                      text: "No History Sections",
                      subText: "We're working to add some history sections for you.",
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () {
                      ref.invalidate(historyListProvider(language.id));
                      return Future.value();
                    },
                    child: ListView.builder(
                      itemCount: histories.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final history = histories[index];
                        final isEnabled = (() {
                          if (index == 0) {
                            return true;
                          }
                          return histories[index - 1].count == histories[index - 1].completed;
                        }).call();
                        return _HistoryItem(
                          history: history,
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
              ref.invalidate(historyListProvider(language.id));
            },
          );
        },
        loading: () => const LoadingBuilder(title: "Sections"),
      ),
    );
  }
}

class _HistoryItem extends ConsumerWidget {
  final History history;
  final bool enabled;
  const _HistoryItem({
    Key? key,
    required this.history,
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
                ref.read(navigationProvider).naviateTo(HistorySectionsListScreen(history: history));
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
                    history.name.text.xl
                        .color(enabled ? context.adaptive : context.adaptive26)
                        .medium
                        .make(),
                    4.heightBox,
                    "${history.count} History • ${history.score}"
                        .text
                        .color(enabled ? context.adaptive54 : context.adaptive26)
                        .maxLines(1)
                        .make(),
                  ],
                ).expand(),
                12.widthBox,
                if (history.count == history.completed)
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
                value: history.count == 0 ? 1 : history.completed / history.count,
                minHeight: 6,
              ),
            ),
          ],
        ).p12(),
      ),
    ).pOnly(bottom: 12);
  }
}
