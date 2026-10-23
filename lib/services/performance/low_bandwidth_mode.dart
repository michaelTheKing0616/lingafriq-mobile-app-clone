import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../connectivity_service.dart';

const String lowBandwidthPrefKey = 'lowbw.choice';

enum LowBandwidthChoice { auto, on, off }

class LowBandwidthDecision {
  const LowBandwidthDecision({required this.enabled, required this.source});

  final bool enabled;
  final String source;
}

/// A saved on or off beats Data Saver. Auto follows Data Saver.
LowBandwidthDecision resolveLowBandwidth({
  required LowBandwidthChoice choice,
  required bool dataSaverOn,
}) {
  switch (choice) {
    case LowBandwidthChoice.on:
      return const LowBandwidthDecision(enabled: true, source: 'manual-on');
    case LowBandwidthChoice.off:
      return const LowBandwidthDecision(enabled: false, source: 'off');
    case LowBandwidthChoice.auto:
      return LowBandwidthDecision(
        enabled: dataSaverOn,
        source: dataSaverOn ? 'auto-on' : 'off',
      );
  }
}

/// Audio stays a tap away while the mode is on. The text reply still shows.
bool loadAudioImmediately(LowBandwidthDecision decision) => !decision.enabled;

/// Asks the image host for a smaller variant. The original URL is unchanged
/// when the mode is off or the value is not an http URL.
String imageLightUrl(String url, {required bool lowBandwidth}) {
  if (!lowBandwidth) return url;
  final uri = Uri.tryParse(url);
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) return url;
  return uri.replace(queryParameters: {
    ...uri.queryParameters,
    'w': '480',
    'q': '40',
  }).toString();
}

class LowBandwidthMode {
  LowBandwidthMode._();

  static final LowBandwidthMode instance = LowBandwidthMode._();

  LowBandwidthChoice choice = LowBandwidthChoice.auto;
  LowBandwidthDecision decision = const LowBandwidthDecision(enabled: false, source: 'off');

  bool get enabled => decision.enabled;

  Future<void> refresh({bool? dataSaverOn}) async {
    final prefs = await SharedPreferences.getInstance();
    choice = _readChoice(prefs.getString(lowBandwidthPrefKey));
    final saver = dataSaverOn ?? await ConnectivityService.isDataSaverOn();
    decision = resolveLowBandwidth(choice: choice, dataSaverOn: saver);
  }

  Future<void> setChoice(LowBandwidthChoice next, {bool? dataSaverOn}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lowBandwidthPrefKey, next.name);
    choice = next;
    final saver = dataSaverOn ?? await ConnectivityService.isDataSaverOn();
    decision = resolveLowBandwidth(choice: choice, dataSaverOn: saver);
  }

  static LowBandwidthChoice _readChoice(String? raw) {
    for (final value in LowBandwidthChoice.values) {
      if (value.name == raw) return value;
    }
    return LowBandwidthChoice.auto;
  }
}

class LowBandwidthSettingsTile extends StatefulWidget {
  const LowBandwidthSettingsTile({super.key, this.initial, this.dataSaverOn = false});

  final LowBandwidthDecision? initial;
  final bool dataSaverOn;

  @override
  State<LowBandwidthSettingsTile> createState() => _LowBandwidthSettingsTileState();
}

class _LowBandwidthSettingsTileState extends State<LowBandwidthSettingsTile> {
  late LowBandwidthDecision _decision = widget.initial ??
      const LowBandwidthDecision(enabled: false, source: 'off');

  @override
  void initState() {
    super.initState();
    if (widget.initial == null) {
      LowBandwidthMode.instance.refresh(dataSaverOn: widget.dataSaverOn).then((_) {
        if (mounted) setState(() => _decision = LowBandwidthMode.instance.decision);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (_decision.source) {
      'auto-on' => 'On because Data Saver is on',
      'manual-on' => 'On until you turn it off',
      _ => 'Off',
    };
    return Semantics(
      label: 'Low bandwidth, $subtitle',
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: const Text('Low bandwidth'),
        subtitle: Text(subtitle),
        value: _decision.enabled,
        onChanged: (enabled) async {
          final choice = enabled ? LowBandwidthChoice.on : LowBandwidthChoice.off;
          await LowBandwidthMode.instance.setChoice(choice, dataSaverOn: widget.dataSaverOn);
          if (mounted) setState(() => _decision = LowBandwidthMode.instance.decision);
        },
      ),
    );
  }
}
