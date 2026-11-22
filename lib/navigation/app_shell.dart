import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/icons/lingafriq_icons.dart';
import 'package:lingafriq/design/motion/motion_scope.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/navigation/tab_routes.dart';

/// Global controls that sit on the shell and are not tabs.
enum ShellTool { me, search, lens }

/// Five-tab shell. Each tab owns one [Navigator] created once.
///
/// Switching tabs keeps that navigator mounted, so its stack and scroll
/// position stay. Me, Search, and Lens are controls. Word Card is not a tab.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.index,
    this.onIndexChanged,
    this.initialLink,
    this.offline = false,
    this.onRetry,
    this.onMe,
    this.onSearch,
    this.onLens,
    this.drawer,
    this.scaffoldKey,
  });

  /// Finder for one tab control.
  static Key tabKey(ShellTab tab) => ValueKey<String>('shell-tab-${tab.name}');

  /// Finder for Me, Search, or Lens.
  static Key toolKey(ShellTool tool) =>
      ValueKey<String>('shell-tool-${tool.name}');

  /// Finder for the fade that plays on a tab change.
  static const Key fadeKey = ValueKey<String>('shell-tab-fade');

  /// Controlled tab index. Null uses the shell's own index.
  final int? index;

  final ValueChanged<int>? onIndexChanged;

  /// Link read once when the shell loads.
  final String? initialLink;

  final bool offline;

  final VoidCallback? onRetry;

  final VoidCallback? onMe;

  final VoidCallback? onSearch;

  final VoidCallback? onLens;

  final Widget? drawer;

  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  late final List<GlobalKey<NavigatorState>> _navigatorKeys;
  late final List<GlobalKey<ShellTabRootState>> _rootKeys;
  late final List<ShellRouteLog> _logs;
  late final List<Widget> _navigators;

  int _localIndex = 0;
  TabLink? _issue;

  @override
  void initState() {
    super.initState();
    _navigatorKeys = List<GlobalKey<NavigatorState>>.generate(
      ShellTab.values.length,
      (_) => GlobalKey<NavigatorState>(),
    );
    _rootKeys = List<GlobalKey<ShellTabRootState>>.generate(
      ShellTab.values.length,
      (_) => GlobalKey<ShellTabRootState>(),
    );
    _logs = List<ShellRouteLog>.generate(
      ShellTab.values.length,
      (_) => ShellRouteLog(),
    );
    _navigators = <Widget>[
      for (final ShellTab tab in ShellTab.values) _navigatorFor(tab),
    ];
    final String? link = widget.initialLink;
    if (link != null) {
      _apply(TabRoutes.resolve(link), notify: false);
    }
  }

  /// Navigator created for [tab]. The same instance stays for the shell's life.
  NavigatorState navigatorOf(ShellTab tab) {
    final NavigatorState? state = _navigatorKeys[tab.index].currentState;
    if (state == null) {
      throw StateError('The ${tab.name} navigator is not mounted.');
    }
    return state;
  }

  /// Scroll position for [tab]. The controller is not replaced on a tab change.
  ScrollController scrollOf(ShellTab tab) {
    final ShellTabRootState? root = _rootKeys[tab.index].currentState;
    if (root == null) {
      throw StateError('The ${tab.name} tab is not mounted.');
    }
    return root.scroll;
  }

  /// How many times [tab]'s root has built. A tab change does not add one.
  int rootBuilds(ShellTab tab) {
    final ShellTabRootState? root = _rootKeys[tab.index].currentState;
    if (root == null) {
      throw StateError('The ${tab.name} tab is not mounted.');
    }
    return root.builds;
  }

  /// Top route name inside [tab].
  String routeNameOf(ShellTab tab) => _logs[tab.index].top;

  /// Opens [raw]. A known tab is selected. An unknown link shows the error.
  void openLink(String raw) {
    setState(() {
      _apply(TabRoutes.resolve(raw), notify: true);
    });
  }

  void _apply(TabLink link, {required bool notify}) {
    final ShellTab? tab = link.tab;
    if (tab != null) {
      _issue = null;
      _select(tab.index, notify: notify);
      return;
    }
    _issue = link;
  }

  void _select(int index, {required bool notify}) {
    final int next = _visible(index);
    _localIndex = next;
    if (notify) {
      widget.onIndexChanged?.call(next);
    }
  }

  int _visible(int index) {
    if (index < 0 || index >= ShellTab.values.length) return 0;
    return index;
  }

  int get _index {
    final int? controlled = widget.index;
    if (controlled == null) return _localIndex;
    return _visible(controlled);
  }

  void _keepOffline() {
    setState(() {});
  }

  void _goToday() {
    setState(() {
      _issue = null;
      _select(ShellTab.today.index, notify: true);
    });
  }

  void _openTool(ShellTool tool) {
    final VoidCallback? custom = switch (tool) {
      ShellTool.me => widget.onMe,
      ShellTool.search => widget.onSearch,
      ShellTool.lens => widget.onLens,
    };
    if (custom != null) {
      custom();
      return;
    }
    navigatorOf(
      ShellTab.values[_index],
    ).pushNamed(ShellRoutes.tool, arguments: tool);
  }

  Widget _navigatorFor(ShellTab tab) {
    return Navigator(
      key: _navigatorKeys[tab.index],
      observers: <NavigatorObserver>[_logs[tab.index]],
      initialRoute: ShellRoutes.root,
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) {
            if (settings.name == ShellRoutes.section) {
              return ShellSectionPage(tab: tab);
            }
            if (settings.name == ShellRoutes.tool) {
              final Object? args = settings.arguments;
              final ShellTool tool = args is ShellTool ? args : ShellTool.me;
              return ShellToolPage(tool: tool);
            }
            return ShellTabRoot(key: _rootKeys[tab.index], tab: tab);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final int index = _index;
    final TabLink? issue = _issue;
    final double topGap =
        MediaQuery.paddingOf(context).top +
        LingAfriqTokens.spacing48 +
        LingAfriqTokens.spacing16;
    final Widget tabs = Material(
      color: palette.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LingAfriqTokens.spacing8,
            vertical: LingAfriqTokens.spacing8,
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: LingAfriqTokens.spacing4,
            runSpacing: LingAfriqTokens.spacing4,
            children: <Widget>[
              for (final ShellTab tab in ShellTab.values)
                _TabButton(
                  tab: tab,
                  selected: tab.index == index,
                  palette: palette,
                  onTap: () => setState(() {
                    _issue = null;
                    _select(tab.index, notify: true);
                  }),
                ),
            ],
          ),
        ),
      ),
    );
    return Scaffold(
      key: widget.scaffoldKey,
      drawer: widget.drawer,
      backgroundColor: palette.surface,
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              SizedBox(height: topGap),
              Expanded(
                child: Stack(
                  children: <Widget>[
                    _TabFade(
                      index: index,
                      child: IndexedStack(
                        index: index,
                        sizing: StackFit.expand,
                        children: _navigators,
                      ),
                    ),
                    if (issue != null)
                      Positioned.fill(
                        child: ColoredBox(
                          color: palette.surface,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(
                              LingAfriqTokens.spacing16,
                            ),
                            child: ShellLinkIssue(
                              link: issue,
                              onToday: _goToday,
                            ),
                          ),
                        ),
                      )
                    else if (widget.offline)
                      Positioned.fill(
                        child: ColoredBox(
                          color: palette.surface,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(
                              LingAfriqTokens.spacing16,
                            ),
                            child: LingOfflineState(
                              whatHappened: l10n.shellOfflineWhat,
                              why: l10n.shellOfflineWhy,
                              whatToDo: l10n.shellOfflineNext,
                              queuedActions: 0,
                              actionLabel: l10n.commonActionTryAgain,
                              unavailableLabel: l10n.commonStateUnavailable,
                              onAction: widget.onRetry ?? _keepOffline,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              tabs,
            ],
          ),
          // Painted after the tab navigators so a route cannot block these labels.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(
              palette: palette,
              onMe: () => _openTool(ShellTool.me),
              onSearch: () => _openTool(ShellTool.search),
              onLens: () => _openTool(ShellTool.lens),
            ),
          ),
        ],
      ),
    );
  }
}

/// Remembers the top route without rebuilding the navigator.
class ShellRouteLog extends NavigatorObserver {
  String top = ShellRoutes.root;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    top = route.settings.name ?? top;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    top = previousRoute?.settings.name ?? ShellRoutes.root;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    top = newRoute?.settings.name ?? top;
  }
}

/// Fade used when the selected tab changes.
///
/// Opacity starts at a quarter, including when reduced motion is on, so the
/// move is never a blank frame. The child navigator stack is not replaced.
class _TabFade extends StatefulWidget {
  const _TabFade({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<_TabFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, value: 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduced = MediaQuery.disableAnimationsOf(context);
    final LingMotionPlan plan = LingMotionPlan.resolve(reduced: reduced);
    _controller.duration = plan.duration;
  }

  @override
  void didUpdateWidget(_TabFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double opacity = 0.25 + (0.75 * _controller.value);
        return Opacity(key: AppShell.fadeKey, opacity: opacity, child: child);
      },
      child: widget.child,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.palette,
    required this.onMe,
    required this.onSearch,
    required this.onLens,
  });

  final LingPalette palette;
  final VoidCallback onMe;
  final VoidCallback onSearch;
  final VoidCallback onLens;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    return Material(
      color: palette.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LingAfriqTokens.spacing8,
            vertical: LingAfriqTokens.spacing8,
          ),
          child: Row(
            children: <Widget>[
              _ToolButton(
                tool: ShellTool.me,
                icon: LingIconName.me,
                label: l10n.shellMe,
                palette: palette,
                onPressed: onMe,
              ),
              const Spacer(),
              _ToolButton(
                tool: ShellTool.search,
                icon: LingIconName.search,
                label: l10n.shellSearch,
                palette: palette,
                onPressed: onSearch,
              ),
              const SizedBox(width: LingAfriqTokens.spacing8),
              _ToolButton(
                tool: ShellTool.lens,
                icon: LingIconName.lens,
                label: l10n.shellLens,
                palette: palette,
                onPressed: onLens,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.tool,
    required this.icon,
    required this.label,
    required this.palette,
    required this.onPressed,
  });

  final ShellTool tool;
  final LingIconName icon;
  final String label;
  final LingPalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: AppShell.toolKey(tool),
      container: true,
      button: true,
      label: label,
      onTap: onPressed,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: LingAfriqTokens.spacing48,
          minHeight: LingAfriqTokens.spacing48,
        ),
        child: Material(
          color: palette.surfaceContainer,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            excludeFromSemantics: true,
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(LingAfriqTokens.spacing12),
              child: ExcludeSemantics(
                child: LingIcon(
                  name: icon,
                  color: palette.onSurface,
                  accent: palette.accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final ShellTab tab;
  final bool selected;
  final LingPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final String label = shellTabLabel(l10n, tab);
    final Color ink = selected ? palette.accent : palette.onSurface;
    return Semantics(
      key: AppShell.tabKey(tab),
      container: true,
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: LingAfriqTokens.spacing48,
          minHeight: LingAfriqTokens.spacing48,
        ),
        child: InkWell(
          excludeFromSemantics: true,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LingAfriqTokens.spacing8,
              vertical: LingAfriqTokens.spacing4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ExcludeSemantics(
                  child: LingIcon(
                    name: _iconFor(tab),
                    color: ink,
                    accent: palette.accent,
                    selected: selected,
                  ),
                ),
                const SizedBox(height: LingAfriqTokens.spacing4),
                ExcludeSemantics(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: lingBody(ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Spoken and painted name for [tab].
String shellTabLabel(AppLocalizations l10n, ShellTab tab) {
  return switch (tab) {
    ShellTab.today => l10n.shellTabToday,
    ShellTab.learn => l10n.shellTabLearn,
    ShellTab.speak => l10n.shellTabSpeak,
    ShellTab.play => l10n.shellTabPlay,
    ShellTab.village => l10n.shellTabVillage,
  };
}

LingIconName _iconFor(ShellTab tab) {
  return switch (tab) {
    ShellTab.today => LingIconName.today,
    ShellTab.learn => LingIconName.learn,
    ShellTab.speak => LingIconName.speak,
    ShellTab.play => LingIconName.play,
    ShellTab.village => LingIconName.village,
  };
}

String _toolLabel(AppLocalizations l10n, ShellTool tool) {
  return switch (tool) {
    ShellTool.me => l10n.shellMe,
    ShellTool.search => l10n.shellSearch,
    ShellTool.lens => l10n.shellLens,
  };
}

/// Scrollable home of one tab. Its [State] stays while other tabs are shown.
class ShellTabRoot extends StatefulWidget {
  const ShellTabRoot({required this.tab, super.key});

  final ShellTab tab;

  @override
  State<ShellTabRoot> createState() => ShellTabRootState();
}

class ShellTabRootState extends State<ShellTabRoot> {
  final ScrollController scroll = ScrollController();
  int builds = 0;

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    builds += 1;
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final String label = shellTabLabel(l10n, widget.tab);
    return ColoredBox(
      color: palette.surface,
      child: ListView.builder(
        controller: scroll,
        padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
        itemCount: 32,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(ShellRoutes.section);
              },
              child: Text(
                l10n.shellOpenSection(label),
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: LingAfriqTokens.spacing12,
            ),
            child: Text(
              l10n.shellSectionLine(index, label),
              style: lingBody(palette.onSurface),
              overflow: TextOverflow.visible,
              softWrap: true,
            ),
          );
        },
      ),
    );
  }
}

/// Page pushed on a tab's own stack.
class ShellSectionPage extends StatelessWidget {
  const ShellSectionPage({required this.tab, super.key});

  final ShellTab tab;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final String label = shellTabLabel(l10n, tab);
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.shellSectionOpen(label),
                style: lingBody(palette.onSurface),
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(l10n.shellBackToLearning),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Me, Search, or Lens. This page is pushed on the current tab. It is not a tab.
class ShellToolPage extends StatelessWidget {
  const ShellToolPage({required this.tool, super.key});

  final ShellTool tool;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(_toolLabel(l10n, tool), style: lingBody(palette.onSurface)),
              const SizedBox(height: LingAfriqTokens.spacing16),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(l10n.shellBackToLearning),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What happened, why, and what to do for a link that matches no tab.
class ShellLinkIssue extends StatelessWidget {
  const ShellLinkIssue({required this.link, required this.onToday, super.key});

  final TabLink link;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final String shown = link.raw.trim().isEmpty
        ? l10n.shellLinkWasEmpty
        : link.raw;
    final String why = link.detail.isEmpty
        ? l10n.shellLinkMissedWhy(shown)
        : l10n.shellLinkMissedWhyWithDetail(shown, link.detail);
    return LingErrorState(
      whatHappened: l10n.shellLinkMissedWhat,
      why: why,
      whatToDo: l10n.shellLinkMissedNext,
      actionLabel: l10n.shellLinkMissedAction,
      unavailableLabel: l10n.commonStateUnavailable,
      onAction: onToday,
    );
  }
}

/// Full-screen missed link. The action is supplied by the route host.
class ShellLinkIssuePage extends StatelessWidget {
  const ShellLinkIssuePage({
    required this.link,
    required this.onToday,
    super.key,
  });

  final TabLink link;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          child: ShellLinkIssue(link: link, onToday: onToday),
        ),
      ),
    );
  }
}
