import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/screens/tabs_view/home/home_parts.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart'
    show ageTierStatusProvider, languagesProvider;
import 'package:lingafriq/screens/tabs_view/home/language_detail_screen.dart';
import 'package:lingafriq/services/connectivity_service.dart';
import 'package:lingafriq/widgets/bidi_text.dart';

/// Whether the device can reach the internet; drives the offline panel.
final languageSearchOnlineProvider = FutureProvider.autoDispose<bool>(
  (ref) => ConnectivityService.hasInternet(),
);

const _navy = Color(0xFF2E3A87);
const _ink = Color(0xFF1F2340);
const _muted = Color(0xFF5B607A);
const _line = Color(0xFFE3E5EF);
const _green = Color(0xFF1B7F4B);

double _progress(Language l) =>
    l.total_score > 0 ? (l.total_score / 100).clamp(0.0, 1.0) : 0.0;

/// Course search / picker (onboarding pack 04–05, language pick): a guide
/// bubble asks one question, a search field filters, and big tappable rows
/// are grouped into "Continue learning" and "All languages". Tapping opens
/// the course, exactly like Home does.
class SearchLanguagesPage extends HookConsumerWidget {
  const SearchLanguagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = l10nOf(context);
    final query = useState('');
    final controller = useTextEditingController();
    final async = ref.watch(languagesProvider);
    final online = ref.watch(languageSearchOnlineProvider).value ?? true;
    final tier = ref.watch(ageTierStatusProvider).value?.tier?.toLowerCase();
    final child = tier == 'child';

    Widget body;
    if (async.hasError && !async.isLoading) {
      body = _Panel(
        key: Key(online ? 'search-error' : 'search-offline'),
        icon: online ? Icons.cloud_off_rounded : Icons.wifi_off_rounded,
        title: online ? l.lsErrorTitle : l.lsOfflineTitle,
        body: online ? l.lsErrorBody : l.lsOfflineBody,
        action: l.lsRetry,
        actionKey: const Key('search-retry'),
        onAction: () {
          ref.invalidate(languageSearchOnlineProvider);
          ref.invalidate(languagesProvider);
        },
      );
    } else if (!async.hasValue) {
      body = _Skeleton(label: l.lsLoading);
    } else {
      final all = async.value!.results;
      if (all.isEmpty) {
        body = _Panel(
          key: const Key('search-empty-catalog'),
          icon: Icons.travel_explore_rounded,
          title: l.lsEmptyTitle,
          body: l.lsEmptyBody,
        );
      } else {
        body = _Results(
          all: all,
          query: query.value,
          onClear: () {
            controller.clear();
            query.value = '';
          },
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              ask: child ? l.lsAskChild : l.lsAsk,
              back: l.lsBack,
              title: l.lsTitle,
              // Large text: the question repeats the title, so drop the
              // bubble and give the rows the room.
              showAsk: MediaQuery.textScalerOf(context).scale(10) <= 15,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                key: const Key('search-field'),
                controller: controller,
                enabled: async.hasValue,
                onChanged: (v) => query.value = v,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l.lsHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF4F5FA),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _line, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _line, width: 2),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: _line),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.ask,
    required this.back,
    required this.title,
    required this.showAsk,
  });
  final String ask, back, title;
  final bool showAsk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('search-back'),
                tooltip: back,
                iconSize: 26,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const BackButtonIcon(),
                color: _muted,
                onPressed: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showAsk)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 12, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: _navy,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.public_rounded,
                        color: Color(0xFFFFC53D),
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      key: const Key('search-bubble'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _line, width: 2),
                      ),
                      child: Text(
                        ask,
                        style: const TextStyle(fontSize: 16, color: _ink),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.all,
    required this.query,
    required this.onClear,
  });
  final List<Language> all;
  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final q = query.trim().toLowerCase();
    final hits = all
        .where((x) => q.isEmpty || x.name.toLowerCase().contains(q))
        .toList();
    if (hits.isEmpty) {
      return _Panel(
        key: const Key('search-empty'),
        icon: Icons.search_off_rounded,
        title: l.lsNoMatch(query.trim()),
        body: l.lsNoMatchBody,
        action: l.lsClear,
        actionKey: const Key('search-clear'),
        onAction: onClear,
      );
    }
    final going = hits
        .where((x) => x.is_published && _progress(x) > 0 && _progress(x) < 1)
        .toList();
    final rest = hits.where((x) => !going.contains(x)).toList()
      ..sort((a, b) {
        if (a.is_published != b.is_published) return a.is_published ? -1 : 1;
        return a.name.compareTo(b.name);
      });
    return ListView(
      key: const Key('search-list'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (going.isNotEmpty) ...[
          _Section(l.lsContinue, const Key('search-section-continue')),
          for (final x in going) _Row(x, l),
          const SizedBox(height: 8),
        ],
        _Section(l.lsAll, const Key('search-section-all')),
        for (final x in rest) _Row(x, l),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text, Key k) : super(key: k);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: _ink,
        ),
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row(this.lang, this.l);
  final Language lang;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final p = _progress(lang);
    final open = lang.is_published;
    final sub = !open
        ? l.lsSoon
        : p > 0
        ? l.lsPercent((p * 100).round())
        : l.lsNew;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _line, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('search-row-${lang.id}'),
          onTap: open
              ? () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LanguageDetailScreen(language: lang),
                    ),
                  );
                }
              : null,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _line, width: 2)),
            ),
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Opacity(
                  opacity: open ? 1 : 0.5,
                  child: LanguageArt(name: lang.name, size: 44),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BidiText(
                        lang.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: open ? _ink : _muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        style: TextStyle(
                          fontSize: 13,
                          color: p > 0 && open ? _green : _muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (open && p > 0) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: p,
                            minHeight: 6,
                            color: _green,
                            backgroundColor: _line,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (open)
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: _muted,
                  )
                else
                  const Icon(Icons.lock_clock_rounded, color: _muted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.actionKey,
    this.onAction,
  });
  final IconData icon;
  final String title, body;
  final String? action;
  final Key? actionKey;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: Color(0xFFEDEFF8),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 44, color: _navy),
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: _muted),
          ),
          if (action != null) ...[
            const SizedBox(height: 20),
            FilledButton(
              key: actionKey,
              style: FilledButton.styleFrom(
                backgroundColor: _navy,
                minimumSize: const Size(200, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onAction,
              child: Text(action!),
            ),
          ],
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('search-loading'),
      label: label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          children: [
            _bar(140, 18),
            const SizedBox(height: 14),
            for (var i = 0; i < 6; i++)
              Container(
                height: 66,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _line, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _line,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _bar(120, 14),
                          const SizedBox(height: 8),
                          _bar(70, 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bar(double w, double h) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: _line,
        borderRadius: BorderRadius.circular(6),
      ),
    ),
  );
}
