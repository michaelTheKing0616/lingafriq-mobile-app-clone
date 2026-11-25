import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

const _steps = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950];
const _mirror = {
  50: 950,
  100: 900,
  200: 800,
  300: 700,
  400: 600,
  500: 500,
  600: 400,
  700: 300,
  800: 200,
  900: 100,
  950: 50,
};

Map<String, dynamic> _spec() => jsonDecode(
      File('design/tokens/tokens.json').readAsStringSync(),
    ) as Map<String, dynamic>;

class _Srgb {
  _Srgb(this.r, this.g, this.b);
  final double r;
  final double g;
  final double b;
  bool inGamut() =>
      r >= -0.0001 &&
      r <= 1.0001 &&
      g >= -0.0001 &&
      g <= 1.0001 &&
      b >= -0.0001 &&
      b <= 1.0001;
}

double _lin(double channel) {
  final c = channel / 255.0;
  if (c <= 0.04045) return c / 12.92;
  return math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _enc(double linear) {
  if (linear <= 0.0031308) return 12.92 * linear;
  return 1.055 * math.pow(linear, 1 / 2.4).toDouble() - 0.055;
}

_Srgb _oklchToLinear(double l, double c, double hDeg) {
  final h = hDeg * math.pi / 180;
  final a = c * math.cos(h);
  final b = c * math.sin(h);
  final l_ = l + 0.3963377774 * a + 0.2158037573 * b;
  final m_ = l - 0.1055613458 * a - 0.0638541728 * b;
  final s_ = l - 0.0894841775 * a - 1.2914855480 * b;
  final ll = l_ * l_ * l_;
  final mm = m_ * m_ * m_;
  final ss = s_ * s_ * s_;
  return _Srgb(
    4.0767416621 * ll - 3.3077115913 * mm + 0.2309699292 * ss,
    -1.2684380046 * ll + 2.6097574011 * mm - 0.3413193965 * ss,
    -0.0041960863 * ll - 0.7034186147 * mm + 1.7076147010 * ss,
  );
}

int _byte(double linear) {
  final encoded = _enc(linear.clamp(0, 1));
  return (encoded * 255).round().clamp(0, 255);
}

String _hexOf(double l, double c, double h) {
  final s = _oklchToLinear(l, c, h);
  final r = _byte(s.r).toRadixString(16).padLeft(2, '0');
  final g = _byte(s.g).toRadixString(16).padLeft(2, '0');
  final b = _byte(s.b).toRadixString(16).padLeft(2, '0');
  return '#${(r + g + b).toUpperCase()}';
}

double _clampChroma(double l, double c, double h) {
  if (_oklchToLinear(l, c, h).inGamut()) return c;
  var lo = 0.0;
  var hi = c;
  for (var i = 0; i < 48; i++) {
    final mid = (lo + hi) / 2;
    if (_oklchToLinear(l, mid, h).inGamut()) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return lo;
}

double _contrast(String fg, String bg) {
  double lum(String hex) {
    final n = int.parse(hex.replaceFirst('#', ''), radix: 16);
    final r = _lin(((n >> 16) & 255).toDouble());
    final g = _lin(((n >> 8) & 255).toDouble());
    final b = _lin((n & 255).toDouble());
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  final a = lum(fg);
  final b = lum(bg);
  final hi = math.max(a, b);
  final lo = math.min(a, b);
  return (hi + 0.05) / (lo + 0.05);
}

bool _passes(String fg, String bg, String level) {
  final ratio = _contrast(fg, bg);
  if (level == 'body') return ratio >= 4.5;
  if (level == 'large') return ratio >= 3;
  throw StateError('unknown level $level');
}

String _roleHex(Map<String, dynamic> ramps, Map role) {
  final ramp = ramps[role['ramp']] as Map<String, dynamic>;
  final step = (ramp['steps'] as Map)['${role['step']}'] as Map;
  return step['hex'] as String;
}

String _invert(String hex) {
  final n = int.parse(hex.replaceFirst('#', ''), radix: 16);
  final r = 255 - ((n >> 16) & 255);
  final g = 255 - ((n >> 8) & 255);
  final b = 255 - (n & 255);
  return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}

void main() {
  final spec = _spec();
  final colorRamps = spec['colorRamps'] as Map<String, dynamic>;
  final ramps = (colorRamps['ramps'] as Map).cast<String, dynamic>();

  test('neutral, accent and four meaning ramps each have 11 OKLCH steps', () {
    expect(ramps.keys.toSet(), {'neutral', 'accent', 'success', 'warning', 'danger', 'info'});
    for (final entry in ramps.entries) {
      final steps = (entry.value as Map)['steps'] as Map;
      expect(steps.keys.map((key) => int.parse('$key')).toList()..sort(), _steps, reason: entry.key);
      for (final id in _steps) {
        final step = steps['$id'] as Map;
        expect(step['l'], isA<num>());
        expect(step['c'], isA<num>());
        expect(step['h'], isA<num>());
        final hex = _hexOf(
          (step['l'] as num).toDouble(),
          (step['c'] as num).toDouble(),
          (step['h'] as num).toDouble(),
        );
        expect(step['hex'], hex, reason: '${entry.key} $id');
        expect(_oklchToLinear(
          (step['l'] as num).toDouble(),
          (step['c'] as num).toDouble(),
          (step['h'] as num).toDouble(),
        ).inGamut(), isTrue);
      }
    }
  });

  test('sRGB gamut clamping is logged for every out-of-gamut step', () {
    final log = (colorRamps['gamutClamp'] as List).cast<Map>();
    final expected = <String>{};
    for (final entry in ramps.entries) {
      final ramp = entry.value as Map;
      final requested = (ramp['requestedChroma'] as num).toDouble();
      final hue = (ramp['hue'] as num).toDouble();
      final steps = ramp['steps'] as Map;
      for (final id in _steps) {
        final step = steps['$id'] as Map;
        final l = (step['l'] as num).toDouble();
        final clamped = _clampChroma(l, requested, hue);
        if (clamped < requested - 1e-6) {
          expected.add('${entry.key}:$id');
          expect((step['c'] as num).toDouble(), closeTo(clamped, 0.0000011));
        } else {
          expect(step['c'], requested);
        }
      }
    }
    expect(log, isNotEmpty);
    expect(log.map((row) => '${row['ramp']}:${row['step']}').toSet(), expected);
    for (final row in log) {
      final ramp = ramps[row['ramp']] as Map;
      final step = (ramp['steps'] as Map)['${row['step']}'] as Map;
      final l = (step['l'] as num).toDouble();
      final hue = (ramp['hue'] as num).toDouble();
      final requested = (row['requestedChroma'] as num).toDouble();
      expect(_oklchToLinear(l, requested, hue).inGamut(), isFalse);
      expect(_oklchToLinear(l, (row['clampedChroma'] as num).toDouble(), hue).inGamut(), isTrue);
    }
  });

  test('there is exactly one accent and its only meaning is primary action', () {
    final accents = ramps.values.where((ramp) => (ramp as Map)['kind'] == 'accent').toList();
    expect(accents, hasLength(1));
    expect((accents.single as Map)['meaning'], 'primary-action');
    final meanings = ramps.values.where((ramp) => (ramp as Map)['meaning'] == 'primary-action');
    expect(meanings, hasLength(1));
  });

  test('dark surfaces use their own steps rather than an inverted light palette', () {
    final modes = colorRamps['modes'] as Map;
    final light = (modes['light'] as Map).cast<String, dynamic>();
    final dark = (modes['dark'] as Map).cast<String, dynamic>();
    final table = File('design/tokens/color_roles.md').readAsStringSync();
    expect(light.keys.toSet(), dark.keys.toSet());
    for (final name in light.keys) {
      final lightRole = light[name] as Map;
      final darkRole = dark[name] as Map;
      expect(table, contains('| light | $name |'));
      expect(table, contains('| dark | $name |'));
      if (lightRole['group'] == 'surface') {
        expect(darkRole['step'], isNot(_mirror[lightRole['step']]), reason: name);
      }
      final lightHex = _roleHex(ramps, lightRole);
      final darkHex = _roleHex(ramps, darkRole);
      expect(darkHex, isNot(_invert(lightHex)), reason: name);
    }
  });

  test('body pairs are at least 4.5:1 and large pairs at least 3:1', () {
    final modes = colorRamps['modes'] as Map;
    for (final raw in colorRamps['pairs'] as List) {
      final pair = raw as Map;
      final mode = (modes[pair['mode']] as Map).cast<String, dynamic>();
      final fg = _roleHex(ramps, mode[pair['fg']] as Map<dynamic, dynamic>);
      final bg = _roleHex(ramps, mode[pair['bg']] as Map<dynamic, dynamic>);
      final level = pair['level'] as String;
      expect(_passes(fg, bg, level), isTrue, reason: '${pair['mode']} ${pair['fg']} on ${pair['bg']}');
      if (level == 'body') {
        expect(_contrast(fg, bg), greaterThanOrEqualTo(4.5));
      }
    }
  });

  test('a lower-contrast pair fails the body check', () {
    expect(_contrast('#777777', '#767676'), lessThan(4.5));
    expect(_passes('#777777', '#767676', 'body'), isFalse);
  });

  test('CI contrast check names a failing pair and passes the token roles', () {
    final self = Process.runSync('python3', ['scripts/lint/contrast_check.py', '--self-test']);
    expect(self.exitCode, 0, reason: '${self.stdout}${self.stderr}');
    final live = Process.runSync('python3', ['scripts/lint/contrast_check.py']);
    expect(live.exitCode, 0, reason: '${live.stdout}${live.stderr}');
    expect(live.stdout.toString(), contains('WCAG 2.2 AA'));
    final broken = Process.runSync('python3', ['scripts/lint/contrast_check.py', '--sample-failure']);
    expect(broken.exitCode, 1);
    final line = broken.stdout.toString();
    expect(line, contains('onSurface'));
    expect(line, contains('surface'));
    expect(line, contains('<'));
  });

  test('each state colour lists a non-colour cue', () {
    final table = File('design/tokens/color_roles.md').readAsStringSync();
    for (final name in ['success', 'warning', 'danger', 'info']) {
      final ramp = ramps[name] as Map;
      expect(ramp['kind'], 'meaning');
      expect((ramp['cue'] as String).isNotEmpty, isTrue);
      expect(table, contains('| $name | ${ramp['meaning']} | ${ramp['cue']} |'));
    }
  });
}
