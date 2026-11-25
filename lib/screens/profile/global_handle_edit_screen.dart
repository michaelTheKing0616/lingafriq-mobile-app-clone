import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:lingafriq/utils/api_service.dart';

/// What a handle load returned. [ready] is the only status that carries a handle.
enum HandlePageStatus { loading, ready, empty, error, offline }

/// A loaded handle, or a load that has nothing, failed, or has no network.
class HandleView {
  const HandleView._(this.status, this.handle);

  const HandleView.ready(String handle)
    : this._(HandlePageStatus.ready, handle);

  const HandleView.empty() : this._(HandlePageStatus.empty, null);

  const HandleView.error() : this._(HandlePageStatus.error, null);

  const HandleView.offline() : this._(HandlePageStatus.offline, null);

  final HandlePageStatus status;
  final String? handle;
}

/// Whether the server answered both checks.
enum HandleCheckAvailability { answered, failed, offline }

/// Server uniqueness and profanity result.
///
/// A missing flag stays null. Nothing here fills in a pass.
class HandleVerdict {
  const HandleVerdict({
    required this.availability,
    this.unique,
    this.profanityClear,
    this.reason,
  });

  const HandleVerdict.failed()
    : this(availability: HandleCheckAvailability.failed);

  const HandleVerdict.offline()
    : this(availability: HandleCheckAvailability.offline);

  final HandleCheckAvailability availability;

  /// True when the server said the handle is unique.
  final bool? unique;

  /// True when the server said the handle is free of profanity.
  final bool? profanityClear;

  /// Reason text from the server, when it sent one.
  final String? reason;

  bool get answered =>
      availability == HandleCheckAvailability.answered &&
      unique != null &&
      profanityClear != null;

  bool get accepted => answered && unique == true && profanityClear == true;
}

/// Loads the saved handle and asks the server to check and keep a new one.
abstract class HandleClient {
  Future<HandleView> load();

  Future<HandleVerdict> check(String handle);

  /// Keeps [handle] after both checks have passed.
  /// Returns the handle the server stored.
  Future<String> save(String handle);
}

/// Reads uniqueness and profanity only from fields the server sent.
///
/// [available] is uniqueness, matching the check-handle response. It is not
/// a profanity result. A bare profanity boolean is ignored.
HandleVerdict parseHandleVerdict(Object? data) {
  if (data is! Map) return const HandleVerdict.failed();
  final Map<String, dynamic> map = Map<String, dynamic>.from(data);
  bool? unique = _flag(map, const <String>['unique', 'uniqueness']);
  if (unique == null) unique = _bool(map['available']);
  bool? profanityClear = _flag(map, const <String>[
    'profanity_clear',
    'profanity_ok',
  ]);
  final Object? profanity = map['profanity'];
  if (profanityClear == null && profanity is Map) {
    profanityClear = _flag(Map<String, dynamic>.from(profanity), const <String>[
      'ok',
      'clear',
      'passed',
    ]);
  }
  if (unique == null || profanityClear == null) {
    return const HandleVerdict.failed();
  }
  return HandleVerdict(
    availability: HandleCheckAvailability.answered,
    unique: unique,
    profanityClear: profanityClear,
    reason: _serverReason(map, unique: unique, profanityClear: profanityClear),
  );
}

bool? _flag(Map<String, dynamic> map, List<String> keys) {
  for (final String key in keys) {
    if (!map.containsKey(key)) continue;
    final Object? value = map[key];
    final bool? direct = _bool(value);
    if (direct != null) return direct;
    if (value is Map) {
      final bool? nested = _flag(
        Map<String, dynamic>.from(value),
        const <String>['ok', 'clear', 'passed'],
      );
      if (nested != null) return nested;
    }
  }
  return null;
}

bool? _bool(Object? value) {
  if (value is bool) return value;
  return null;
}

String? _text(Object? value) {
  if (value is! String) return null;
  final String trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
}

String? _serverReason(
  Map<String, dynamic> map, {
  required bool unique,
  required bool profanityClear,
}) {
  final String? top =
      _text(map['reason']) ?? _text(map['message']) ?? _text(map['detail']);
  if (top != null) return top;
  if (!unique) {
    final String? nested = _nestedReason(map['unique'] ?? map['uniqueness']);
    if (nested != null) return nested;
  }
  if (!profanityClear) {
    return _nestedReason(map['profanity']) ??
        _nestedReason(map['profanity_clear']) ??
        _nestedReason(map['profanity_ok']);
  }
  return null;
}

String? _nestedReason(Object? value) {
  if (value is! Map) return null;
  final Map<String, dynamic> map = Map<String, dynamic>.from(value);
  return _text(map['reason']) ?? _text(map['message']) ?? _text(map['detail']);
}

String? _storedHandle(Object? data) {
  if (data is! Map) return null;
  final Map<String, dynamic> map = Map<String, dynamic>.from(data);
  return _plainHandle(map['global_id'] ?? map['handle']);
}

String? _plainHandle(Object? value) {
  final String? text = _text(value);
  if (text == null) return null;
  final String plain = text.replaceFirst(RegExp(r'^@'), '').trim();
  if (plain.isEmpty) return null;
  return plain;
}

bool _isOffline(Object error) {
  final String text = error.toString().toLowerCase();
  return text.contains('internet') && text.contains('connection');
}

/// Server client. A missing verdict is a failed check, not a pass.
class ApiHandleClient implements HandleClient {
  ApiHandleClient({this.transport});

  final HandleTransport? transport;

  HandleTransport get _transport => transport ?? const ApiHandleTransport();

  @override
  Future<HandleView> load() async {
    try {
      final HandleHttp response = await _transport.get(
        Api.userInfo,
        query: null,
      );
      if (response.statusCode != 200) return const HandleView.error();
      final String? handle = _storedHandle(response.data);
      if (handle == null) return const HandleView.empty();
      return HandleView.ready(handle);
    } catch (error) {
      if (_isOffline(error)) return const HandleView.offline();
      return const HandleView.error();
    }
  }

  @override
  Future<HandleVerdict> check(String handle) async {
    try {
      final String root = AppConfig.backendBaseUrl.replaceAll(
        RegExp(r'/$'),
        '',
      );
      final HandleHttp response = await _transport.get(
        '$root/api/v1/accounts/auth/users/check-handle',
        query: <String, dynamic>{'handle': handle},
      );
      final int? code = response.statusCode;
      if (code == null || code >= 500) return const HandleVerdict.failed();
      return parseHandleVerdict(response.data);
    } catch (error) {
      if (_isOffline(error)) return const HandleVerdict.offline();
      return const HandleVerdict.failed();
    }
  }

  @override
  Future<String> save(String handle) async {
    final String root = AppConfig.backendBaseUrl.replaceAll(RegExp(r'/$'), '');
    final HandleHttp response = await _transport.patch(
      '$root/api/v1/accounts/auth/users/profile',
      <String, dynamic>{'global_id': handle},
    );
    final int code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw const HandleSaveException();
    }
    return _storedHandle(response.data) ?? handle;
  }
}

class HandleSaveException implements Exception {
  const HandleSaveException();
}

class HandleHttp {
  const HandleHttp({required this.statusCode, required this.data});

  final int? statusCode;
  final Object? data;
}

/// HTTP used by [ApiHandleClient]. Tests can stand in for the server.
abstract class HandleTransport {
  Future<HandleHttp> get(String path, {Map<String, dynamic>? query});

  Future<HandleHttp> patch(String path, Map<String, dynamic> data);
}

class ApiHandleTransport implements HandleTransport {
  const ApiHandleTransport();

  Options get _acceptClientErrors {
    return Options(validateStatus: (int? code) => code != null && code < 500);
  }

  @override
  Future<HandleHttp> get(String path, {Map<String, dynamic>? query}) async {
    final Response<dynamic> response = await ApiService.get(
      path,
      queryParameters: query,
      options: _acceptClientErrors,
    );
    return HandleHttp(statusCode: response.statusCode, data: response.data);
  }

  @override
  Future<HandleHttp> patch(String path, Map<String, dynamic> data) async {
    final Response<dynamic> response = await ApiService.patch(
      path,
      data: data,
      options: _acceptClientErrors,
    );
    return HandleHttp(statusCode: response.statusCode, data: response.data);
  }
}

/// Edit the learner's global handle.
///
/// Save asks the server about uniqueness and profanity. A missing check
/// is an error, and the screen does not say the handle was saved.
class GlobalHandleEditScreen extends StatefulWidget {
  const GlobalHandleEditScreen({super.key, this.currentGlobalId, this.client});

  /// App route `/me/handle`. The map key drops the leading slash.
  static const String routePath = '/me/handle';

  static const String routeKey = 'me/handle';

  static const Key emptyKey = ValueKey<String>('me-handle-empty');

  static const Key errorKey = ValueKey<String>('me-handle-error');

  static const Key offlineKey = ValueKey<String>('me-handle-offline');

  static const Key formKey = ValueKey<String>('me-handle-form');

  static const Key fieldKey = ValueKey<String>('me-handle-field');

  static const Key saveKey = ValueKey<String>('me-handle-save');

  static const Key reasonKey = ValueKey<String>('me-handle-reason');

  static const Key savedKey = ValueKey<String>('me-handle-saved');

  static const Key neededKey = ValueKey<String>('me-handle-needed');

  static const Key checkKey = ValueKey<String>('me-handle-check');

  static const Key saveErrorKey = ValueKey<String>('me-handle-save-error');

  static const Key currentKey = ValueKey<String>('me-handle-current');

  /// Handle already on the profile, when the opener has one.
  final String? currentGlobalId;

  /// Server seam. Null uses [ApiHandleClient] when no [currentGlobalId] is set.
  final HandleClient? client;

  @override
  State<GlobalHandleEditScreen> createState() => _GlobalHandleEditScreenState();
}

class _GlobalHandleEditScreenState extends State<GlobalHandleEditScreen> {
  final TextEditingController _field = TextEditingController();

  HandlePageStatus _status = HandlePageStatus.loading;
  String? _handle;
  bool _editing = false;
  bool _saving = false;
  bool _saved = false;
  bool _rejected = false;
  bool _needed = false;
  bool _checkFailed = false;
  bool _saveFailed = false;
  bool _saveOffline = false;
  String? _reason;

  HandleClient get _client => widget.client ?? ApiHandleClient();

  @override
  void initState() {
    super.initState();
    _beginLoad();
  }

  @override
  void didUpdateWidget(GlobalHandleEditScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.client != widget.client ||
        oldWidget.currentGlobalId != widget.currentGlobalId) {
      _status = HandlePageStatus.loading;
      _handle = null;
      _field.text = '';
      _editing = false;
      _clearOutcome();
      _beginLoad();
    }
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<HandleView> _fetch() {
    final HandleClient? client = widget.client;
    if (client != null) return client.load();
    if (widget.currentGlobalId != null) {
      final String? handle = _plainHandle(widget.currentGlobalId);
      if (handle == null)
        return Future<HandleView>.value(const HandleView.empty());
      return Future<HandleView>.value(HandleView.ready(handle));
    }
    return ApiHandleClient().load();
  }

  void _clearOutcome() {
    _saved = false;
    _rejected = false;
    _needed = false;
    _checkFailed = false;
    _saveFailed = false;
    _saveOffline = false;
    _reason = null;
  }

  Future<void> _beginLoad() async {
    final HandleView view = await _fetch();
    if (!mounted) return;
    setState(() {
      _clearOutcome();
      _saving = false;
      if (view.status == HandlePageStatus.ready &&
          view.handle != null &&
          view.handle!.isNotEmpty) {
        _status = HandlePageStatus.ready;
        _handle = view.handle;
        _field.text = view.handle!;
        _editing = true;
      } else {
        _status = view.status == HandlePageStatus.loading
            ? HandlePageStatus.error
            : view.status;
        _handle = null;
        _field.text = '';
        _editing = false;
      }
    });
  }

  void _retryLoad() {
    setState(() {
      _status = HandlePageStatus.loading;
      _handle = null;
      _field.text = '';
      _editing = false;
      _clearOutcome();
    });
    _beginLoad();
  }

  void _choose() {
    setState(() {
      _editing = true;
      _field.text = '';
      _handle = null;
      _clearOutcome();
    });
  }

  Future<void> _save() async {
    final String handle = _plainHandle(_field.text) ?? '';
    if (handle.isEmpty) {
      setState(() {
        _clearOutcome();
        _needed = true;
      });
      return;
    }
    setState(() {
      _saving = true;
      _clearOutcome();
    });
    try {
      final HandleVerdict verdict = await _client.check(handle);
      if (!mounted) return;
      if (verdict.availability == HandleCheckAvailability.offline) {
        setState(() {
          _saving = false;
          _saveOffline = true;
        });
        return;
      }
      if (!verdict.answered) {
        setState(() {
          _saving = false;
          _checkFailed = true;
        });
        return;
      }
      if (!verdict.accepted) {
        setState(() {
          _saving = false;
          _rejected = true;
          _reason = verdict.reason;
        });
        return;
      }
      final String stored = await _client.save(handle);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
        _handle = stored;
        _field.text = stored;
        _status = HandlePageStatus.ready;
        _editing = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveFailed = true;
        _saved = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            Text(
              l10n.revRvMeHandleTitle,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            ..._body(l10n, palette),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(AppLocalizations l10n, LingPalette palette) {
    if (_status == HandlePageStatus.loading) {
      return <Widget>[
        Text(
          l10n.loading,
          style: lingBody(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      ];
    }
    if (_status == HandlePageStatus.error) {
      return <Widget>[_loadError(l10n)];
    }
    if (_status == HandlePageStatus.offline) {
      return <Widget>[_loadOffline(l10n)];
    }
    if (_status == HandlePageStatus.empty && !_editing) {
      return <Widget>[_empty(l10n)];
    }
    return <Widget>[_form(l10n, palette)];
  }

  Widget _empty(AppLocalizations l10n) {
    return LingEmptyState(
      key: GlobalHandleEditScreen.emptyKey,
      title: l10n.revRvMeHandleTitle,
      whatHappened: l10n.revRvMeHandleEmptyWhat,
      why: l10n.revRvMeHandleEmptyWhy,
      whatToDo: l10n.revRvMeHandleEmptyNext,
      actionLabel: l10n.revRvMeHandleChoose,
      unavailableLabel: l10n.commonStateUnavailable,
      onAction: _choose,
    );
  }

  Widget _loadError(AppLocalizations l10n) {
    return LingErrorState(
      key: GlobalHandleEditScreen.errorKey,
      whatHappened: l10n.revRvMeHandleErrorWhat,
      why: l10n.revRvMeHandleErrorWhy,
      whatToDo: l10n.revRvMeHandleErrorNext,
      actionLabel: l10n.commonActionTryAgain,
      unavailableLabel: l10n.commonStateUnavailable,
      onAction: _retryLoad,
    );
  }

  Widget _loadOffline(AppLocalizations l10n) {
    return LingOfflineState(
      key: GlobalHandleEditScreen.offlineKey,
      whatHappened: l10n.shellOfflineWhat,
      why: l10n.revRvMeHandleOfflineWhy,
      whatToDo: l10n.shellOfflineNext,
      queuedActions: 0,
      actionLabel: l10n.commonActionTryAgain,
      unavailableLabel: l10n.commonStateUnavailable,
      onAction: _retryLoad,
    );
  }

  Widget _form(AppLocalizations l10n, LingPalette palette) {
    return Column(
      key: GlobalHandleEditScreen.formKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_handle != null) ...<Widget>[
          Text(
            l10n.revRvMeHandleCurrent,
            key: GlobalHandleEditScreen.currentKey,
            style: lingBody(palette.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: LingAfriqTokens.spacing8),
          Text(
            _handle!,
            style: lingBody(palette.onSurfaceVariant),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: LingAfriqTokens.spacing16),
        ],
        Semantics(
          label: l10n.revRvMeHandleField,
          textField: true,
          child: TextField(
            key: GlobalHandleEditScreen.fieldKey,
            controller: _field,
            enabled: !_saving,
            maxLines: null,
            decoration: InputDecoration(
              labelText: l10n.revRvMeHandleField,
              hintText: l10n.revRvMeHandleHint,
            ),
            onChanged: (_) {
              if (_saved ||
                  _rejected ||
                  _needed ||
                  _checkFailed ||
                  _saveFailed) {
                setState(_clearOutcome);
              }
            },
          ),
        ),
        const SizedBox(height: LingAfriqTokens.spacing16),
        Text(
          l10n.revRvMeHandleServer,
          style: lingBody(palette.onSurfaceVariant),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(height: LingAfriqTokens.spacing16),
        if (_needed)
          Text(
            l10n.revRvMeHandleNeeded,
            key: GlobalHandleEditScreen.neededKey,
            style: lingBody(palette.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        if (_rejected)
          Text(
            (_reason == null || _reason!.isEmpty)
                ? l10n.revRvMeHandleRejected
                : _reason!,
            key: GlobalHandleEditScreen.reasonKey,
            style: lingBody(palette.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        if (_checkFailed)
          LingErrorState(
            key: GlobalHandleEditScreen.checkKey,
            whatHappened: l10n.revRvMeHandleCheckWhat,
            why: l10n.revRvMeHandleCheckWhy,
            whatToDo: l10n.revRvMeHandleCheckNext,
            actionLabel: l10n.commonActionTryAgain,
            unavailableLabel: l10n.commonStateUnavailable,
            onAction: _saving ? () {} : _save,
          ),
        if (_saveFailed)
          LingErrorState(
            key: GlobalHandleEditScreen.saveErrorKey,
            whatHappened: l10n.revRvMeHandleSaveWhat,
            why: l10n.revRvMeHandleSaveWhy,
            whatToDo: l10n.revRvMeHandleSaveNext,
            actionLabel: l10n.commonActionTryAgain,
            unavailableLabel: l10n.commonStateUnavailable,
            onAction: _saving ? () {} : _save,
          ),
        if (_saveOffline)
          LingOfflineState(
            key: GlobalHandleEditScreen.offlineKey,
            whatHappened: l10n.shellOfflineWhat,
            why: l10n.revRvMeHandleOfflineWhy,
            whatToDo: l10n.shellOfflineNext,
            queuedActions: 0,
            actionLabel: l10n.commonActionTryAgain,
            unavailableLabel: l10n.commonStateUnavailable,
            onAction: _saving ? () {} : _save,
          ),
        if (_saved)
          Text(
            l10n.revRvMeHandleSaved,
            key: GlobalHandleEditScreen.savedKey,
            style: lingBody(palette.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        const SizedBox(height: LingAfriqTokens.spacing16),
        LingButton(
          key: GlobalHandleEditScreen.saveKey,
          label: _saving ? l10n.loading : l10n.revRvMeHandleSave,
          unavailableLabel: l10n.commonStateUnavailable,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
