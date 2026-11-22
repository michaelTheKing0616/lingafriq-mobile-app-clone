import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/services/revenuecat_service.dart';
import 'package:lingafriq/services/social/revived_social.dart';
import 'package:lingafriq/utils/api_service.dart';

/// Production client. A transport failure throws, so the screen shows an error
/// and does not treat the action as accepted.
RevivedSocialClient liveRevivedSocialClient() {
  Future<Map<String, dynamic>> asMap(Object? data) async {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const SocialRequestException(
      'The server did not return a result.',
    );
  }

  return RevivedSocialClient(
    get: (String path) async {
      final response = await ApiService.get(path);
      return asMap(response.data);
    },
    post: (String path, Map<String, dynamic> body) async {
      final response = await ApiService.post(path, data: body);
      return asMap(response.data);
    },
  );
}

/// Adult chat tools. A minor or unknown age never reaches the tools.
class VillageChatToolsScreen extends StatefulWidget {
  const VillageChatToolsScreen({
    required this.client,
    required this.onOpen,
    this.welcomeStore,
    super.key,
  });

  final RevivedSocialClient client;
  final void Function(String path) onOpen;
  final ChatWelcomeStore? welcomeStore;

  static const String searchPath = '/village/chat-search';
  static const String contactPath = '/village/contact-info';
  static const String moderationPath = '/village/moderation';
  static const String welcomePath = '/village/chat-welcome';

  static const Key lockedKey = ValueKey<String>('chat-tools-locked');

  @override
  State<VillageChatToolsScreen> createState() => _VillageChatToolsScreenState();
}

class _VillageChatToolsScreenState extends State<VillageChatToolsScreen> {
  SocialAgeGate? _gate;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final SocialAgeGate gate = await widget.client.readAgeGate();
      if (!mounted) return;
      setState(() {
        _gate = gate;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _gate = null;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    if (_error != null) {
      return LingErrorState(
        whatHappened: l10n.revChatErrorWhat,
        why: l10n.revChatErrorWhy,
        whatToDo: l10n.revChatErrorDo,
        actionLabel: l10n.revChatErrorAction,
        onAction: _load,
      );
    }
    final SocialAgeGate? gate = _gate;
    if (gate == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!gate.allowsChat) {
      return ListView(
        key: VillageChatToolsScreen.lockedKey,
        children: <Widget>[
          Text(l10n.revChatLockedTitle),
          Text(gate.message ?? l10n.revChatLockedBody),
        ],
      );
    }
    return ListView(
      children: <Widget>[
        Text(l10n.revChatToolsTitle),
        LingButton(
          label: l10n.revChatSearchTitle,
          unavailableLabel: l10n.commonStateUnavailable,
          onPressed: () => widget.onOpen(VillageChatToolsScreen.searchPath),
        ),
        LingButton(
          label: l10n.revChatModerationTitle,
          unavailableLabel: l10n.commonStateUnavailable,
          onPressed: () =>
              widget.onOpen(VillageChatToolsScreen.moderationPath),
        ),
        LingButton(
          label: l10n.revChatWelcomeTitle,
          unavailableLabel: l10n.commonStateUnavailable,
          onPressed: () => widget.onOpen(VillageChatToolsScreen.welcomePath),
        ),
        LingButton(
          label: l10n.revChatBlock,
          unavailableLabel: l10n.commonStateUnavailable,
          onPressed: () => widget.onOpen(VillageChatToolsScreen.contactPath),
        ),
      ],
    );
  }
}

class RevivedChatSearchScreen extends StatefulWidget {
  const RevivedChatSearchScreen({required this.client, super.key});

  final RevivedSocialClient client;

  static const Key emptyKey = ValueKey<String>('chat-search-empty');
  static const Key errorKey = ValueKey<String>('chat-search-error');

  @override
  State<RevivedChatSearchScreen> createState() =>
      _RevivedChatSearchScreenState();
}

class _RevivedChatSearchScreenState extends State<RevivedChatSearchScreen> {
  List<String> _results = const <String>[];
  Object? _error;
  bool _searched = false;

  Future<void> _search(String query) async {
    try {
      final List<String> rows = await widget.client.searchChats(query);
      if (!mounted) return;
      setState(() {
        _results = rows;
        _error = null;
        _searched = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _results = const <String>[];
        _error = error;
        _searched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    return Column(
      children: <Widget>[
        TextField(
          key: const ValueKey<String>('chat-search-field'),
          onSubmitted: _search,
        ),
        if (_error != null)
          LingErrorState(
            key: RevivedChatSearchScreen.errorKey,
            whatHappened: l10n.revChatErrorWhat,
            why: l10n.revChatErrorWhy,
            whatToDo: l10n.revChatErrorDo,
            actionLabel: l10n.revChatErrorAction,
            onAction: () => _search(''),
          )
        else if (_searched && _results.isEmpty)
          LingEmptyState(
            key: RevivedChatSearchScreen.emptyKey,
            title: l10n.revChatSearchEmptyTitle,
            whatHappened: l10n.revChatSearchEmptyWhat,
            why: l10n.revChatSearchEmptyWhy,
            whatToDo: l10n.revChatSearchEmptyDo,
            actionLabel: l10n.revChatSearchEmptyAction,
            onAction: () {},
          )
        else
          for (final String row in _results) Text(row),
      ],
    );
  }
}

class RevivedContactInfoScreen extends StatefulWidget {
  const RevivedContactInfoScreen({
    required this.client,
    required this.userId,
    super.key,
  });

  final RevivedSocialClient client;
  final String userId;

  static const Key retryKey = ValueKey<String>('contact-retry');
  static const Key acceptedKey = ValueKey<String>('contact-accepted');

  @override
  State<RevivedContactInfoScreen> createState() =>
      _RevivedContactInfoScreenState();
}

class _RevivedContactInfoScreenState extends State<RevivedContactInfoScreen> {
  SafetyActionResult? _result;

  Future<void> _run(Future<SafetyActionResult> Function() action) async {
    try {
      final SafetyActionResult result = await action();
      if (!mounted) return;
      setState(() => _result = result);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _result = SafetyActionResult.retry(error.toString()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final SafetyActionResult? result = _result;
    return Scaffold(
      body: ListView(
        children: <Widget>[
          LingButton(
            label: l10n.revChatBlock,
            unavailableLabel: l10n.commonStateUnavailable,
            onPressed: () => _run(
              () => widget.client.block(
                widget.userId,
                successMessage: l10n.revChatBlocked,
                failureMessage: l10n.revChatActionFailed,
              ),
            ),
          ),
          LingButton(
            label: l10n.revChatReport,
            unavailableLabel: l10n.commonStateUnavailable,
            onPressed: () => _run(
              () => widget.client.report(
                widget.userId,
                successMessage: l10n.revChatReported,
                failureMessage: l10n.revChatActionFailed,
              ),
            ),
          ),
          if (result != null && result.accepted)
            Text(result.message, key: RevivedContactInfoScreen.acceptedKey)
          else if (result != null)
            LingErrorState(
              key: RevivedContactInfoScreen.retryKey,
              whatHappened: l10n.revChatErrorWhat,
              why: result.message,
              whatToDo: l10n.revChatErrorDo,
              actionLabel: l10n.revChatRetry,
              onAction: () => setState(() => _result = null),
            ),
        ],
      ),
    );
  }
}

class RevivedModerationScreen extends StatefulWidget {
  const RevivedModerationScreen({required this.client, super.key});

  final RevivedSocialClient client;

  static const Key deniedKey = ValueKey<String>('moderation-denied');

  @override
  State<RevivedModerationScreen> createState() =>
      _RevivedModerationScreenState();
}

class _RevivedModerationScreenState extends State<RevivedModerationScreen> {
  ModerationAccess? _access;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final AppLocalizations l10n = l10nOf(context);
    try {
      final ModerationAccess access = await widget.client.readModeration(
        denial: l10n.revChatNotModerator,
      );
      if (!mounted) return;
      setState(() {
        _access = access;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _access = null;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    if (_error != null) {
      return LingErrorState(
        whatHappened: l10n.revChatErrorWhat,
        why: l10n.revChatErrorWhy,
        whatToDo: l10n.revChatErrorDo,
        actionLabel: l10n.revChatErrorAction,
        onAction: _load,
      );
    }
    final ModerationAccess? access = _access;
    if (access == null) return const SizedBox.shrink();
    if (!access.isModerator) {
      return Text(access.denial ?? l10n.revChatNotModerator, key: RevivedModerationScreen.deniedKey);
    }
    return Text(l10n.revChatModerationTitle);
  }
}

class RevivedChatWelcomeScreen extends StatefulWidget {
  const RevivedChatWelcomeScreen({
    required this.store,
    required this.userId,
    super.key,
  });

  final ChatWelcomeStore store;
  final String userId;

  static const Key acceptKey = ValueKey<String>('chat-welcome-accept');
  static const Key acceptedKey = ValueKey<String>('chat-welcome-accepted');

  @override
  State<RevivedChatWelcomeScreen> createState() =>
      _RevivedChatWelcomeScreenState();
}

class _RevivedChatWelcomeScreenState extends State<RevivedChatWelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    if (widget.store.hasAccepted(widget.userId)) {
      return Text(l10n.revChatWelcomeAccepted, key: RevivedChatWelcomeScreen.acceptedKey);
    }
    return Column(
      children: <Widget>[
        Text(l10n.revChatWelcomeTitle),
        Text(l10n.revChatWelcomeBody),
        LingButton(
          key: RevivedChatWelcomeScreen.acceptKey,
          label: l10n.revChatWelcomeAccept,
          unavailableLabel: l10n.commonStateUnavailable,
          onPressed: () {
            widget.store.accept(widget.userId);
            setState(() {});
          },
        ),
      ],
    );
  }
}

class RevivedFamilyDashboardScreen extends StatefulWidget {
  const RevivedFamilyDashboardScreen({required this.client, super.key});

  final RevivedSocialClient client;

  static const String routePath = '/me/family';
  static const String routeKey = 'me/family';
  static const Key emptyKey = ValueKey<String>('family-empty');
  static const Key errorKey = ValueKey<String>('family-error');
  static const Key deniedKey = ValueKey<String>('family-denied');

  @override
  State<RevivedFamilyDashboardScreen> createState() =>
      _RevivedFamilyDashboardScreenState();
}

class _RevivedFamilyDashboardScreenState
    extends State<RevivedFamilyDashboardScreen> {
  FamilyDashboardData? _data;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final FamilyDashboardData data = await widget.client.readFamily();
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _data = null;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    if (_error != null) {
      return LingErrorState(
        key: RevivedFamilyDashboardScreen.errorKey,
        whatHappened: l10n.revFamilyErrorWhat,
        why: l10n.revChatErrorWhy,
        whatToDo: l10n.revChatErrorDo,
        actionLabel: l10n.revChatErrorAction,
        onAction: _load,
      );
    }
    final FamilyDashboardData? data = _data;
    if (data == null) return const SizedBox.shrink();
    if (!data.isGuardian) {
      return Text(data.denial ?? l10n.revFamilyDenied, key: RevivedFamilyDashboardScreen.deniedKey);
    }
    if (data.childLabels.isEmpty) {
      return LingEmptyState(
        key: RevivedFamilyDashboardScreen.emptyKey,
        title: l10n.revFamilyEmptyTitle,
        whatHappened: l10n.revFamilyEmptyWhat,
        why: l10n.revFamilyEmptyWhy,
        whatToDo: l10n.revFamilyEmptyDo,
        actionLabel: l10n.revFamilyEmptyAction,
        onAction: _load,
      );
    }
    return Column(
      children: <Widget>[
        Text(l10n.revFamilyTitle),
        for (final String child in data.childLabels) Text(child),
        for (final String approval in data.approvalLabels) Text(approval),
      ],
    );
  }
}

class PlusEntryScreen extends StatefulWidget {
  const PlusEntryScreen({required this.client, super.key});

  final RevivedSocialClient client;

  @override
  State<PlusEntryScreen> createState() => _PlusEntryScreenState();
}

class _PlusEntryScreenState extends State<PlusEntryScreen> {
  bool? _configured;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _readStore());
  }

  Future<void> _readStore() async {
    var configured = false;
    try {
      final service = RevenueCatService();
      await service.initialize();
      configured = service.isConfigured;
    } catch (_) {
      configured = false;
    }
    if (!mounted) return;
    setState(() => _configured = configured);
  }

  @override
  Widget build(BuildContext context) {
    final bool? configured = _configured;
    if (configured == null) return const SizedBox.shrink();
    return RevivedPlusScreen(
      client: widget.client,
      storeConfigured: configured,
    );
  }
}

class RevivedPlusScreen extends StatefulWidget {
  const RevivedPlusScreen({
    required this.client,
    required this.storeConfigured,
    super.key,
  });

  final RevivedSocialClient client;
  final bool storeConfigured;

  static const String routePath = '/me/plus';
  static const String routeKey = 'me/plus';
  static const Key unavailableKey = ValueKey<String>('plus-unavailable');
  static const Key unconfirmedKey = ValueKey<String>('plus-unconfirmed');
  static const Key entitledKey = ValueKey<String>('plus-entitled');

  @override
  State<RevivedPlusScreen> createState() => _RevivedPlusScreenState();
}

class _RevivedPlusScreenState extends State<RevivedPlusScreen> {
  PlusEntitlement? _result;
  bool _purchaseStarted = false;

  Future<void> _buy() async {
    if (!widget.storeConfigured) {
      setState(() {
        _purchaseStarted = false;
        _result = const PlusEntitlement(
          storeConfigured: false,
          serverConfirmed: false,
        );
      });
      return;
    }
    try {
      final PlusEntitlement result = await widget.client.confirmPlus(
        storeConfigured: true,
      );
      if (!mounted) return;
      setState(() {
        _purchaseStarted = result.serverConfirmed;
        _result = result;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _purchaseStarted = false;
        _result = PlusEntitlement(
          storeConfigured: true,
          serverConfirmed: false,
          message: error.toString(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final PlusEntitlement? result = _result;
    return Scaffold(
      body: ListView(
        children: <Widget>[
          Text(l10n.revPlusTitle),
          if (!widget.storeConfigured)
            Text(
              l10n.revPlusUnavailableBody,
              key: RevivedPlusScreen.unavailableKey,
            ),
          LingButton(
            label: l10n.revPlusBuy,
            unavailableLabel: l10n.commonStateUnavailable,
            onPressed: _buy,
          ),
        if (result != null && result.serverConfirmed)
          Text(l10n.revPlusEntitled, key: RevivedPlusScreen.entitledKey)
        else if (result != null && result.storeConfigured)
          Text(l10n.revPlusUnconfirmed, key: RevivedPlusScreen.unconfirmedKey),
        ],
      ),
    );
  }
}
