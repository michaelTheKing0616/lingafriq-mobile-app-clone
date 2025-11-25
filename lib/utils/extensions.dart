import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

extension BuildContextExtended on BuildContext {
  Color get adaptive5 => theme.dividerColor.withOpacity(0.05);
  Color get adaptive8 => theme.dividerColor.withOpacity(0.08);
  Color get adaptive12 => theme.dividerColor.withOpacity(0.12);
  Color get adaptive26 => theme.dividerColor.withOpacity(0.26);
  Color get adaptive38 => theme.dividerColor.withOpacity(0.38);
  Color get adaptive45 => theme.dividerColor.withOpacity(0.45);
  Color get adaptive54 => theme.dividerColor.withOpacity(0.54);
  Color get adaptive60 => theme.dividerColor.withOpacity(0.60);
  Color get adaptive70 => theme.dividerColor.withOpacity(0.70);
  Color get adaptive75 => theme.dividerColor.withOpacity(0.75);
  Color get adaptive87 => theme.dividerColor.withOpacity(0.87);
  Color get adaptive => theme.dividerColor;
  Color get shadow => theme.brightness == Brightness.dark ? Colors.transparent : Colors.black12;
  bool get isDarkMode => theme.brightness == Brightness.dark;
  bool get isSmall => MediaQuery.of(this).size.height < 700;
  bool get isExtraSmall => MediaQuery.of(this).size.height < 600;
  bool get isTablet => MediaQuery.of(this).size.height > 1100;

  double getAdaptiveHeight() {
    if (isExtraSmall) {
      return screenHeight * 0.4;
    } else if (isSmall) {
      return screenHeight * 0.33;
    } else if (isTablet) {
      return screenHeight * 0.3;
    } else {
      return screenHeight * 0.3;
    }
  }

  double getMainHeight() {
    if (isExtraSmall) {
      return 720.0;
    } else if (isSmall) {
      return 750;
    } else if (isTablet) {
      return 1100;
    } else {
      return 940.0;
    }
  }

  double getMainWidth() {
    if (isExtraSmall) {
      return 500.0;
    } else if (isSmall) {
      return 750;
    } else if (isTablet) {
      return 1100;
    } else {
      return 430.0;
    }
  }

  void nextEditableTextFocus() {
    do {
      FocusScope.of(this).nextFocus();
    } while (FocusScope.of(this).focusedChild?.context?.widget is! EditableText);
  }
}

extension ExtendedStrign on String? {
  bool get isBlank => this == null || (this?.isEmpty ?? false);
  bool get isNotBlank => this != null || (this?.isNotEmpty ?? false);
}

extension ExtendedList on List? {
  bool get isBlank => this == null || (this?.isEmpty ?? false);
  bool get isNotBlank => this != null || (this?.isNotEmpty ?? false);
  bool get allNotNull => !allNull;
  bool get allNull => this!.every((e) => e == null);
}

extension MapExtension on Map<String, dynamic> {
  Map removeNulls() => removeNullsFromMap(this);
}

Map<String, dynamic> removeNullsFromMap(Map<String, dynamic> json) => json
  ..removeWhere((String key, dynamic value) => value == null || (value is List && value.isEmpty));

extension ExtendedObject on Object? {
  void log([String? name]) => dev.log(toString(), name: name ?? '');
}

extension ExtendedMap on Map? {
  String prettyJson() {
    var spaces = ' ' * 4;
    var encoder = JsonEncoder.withIndent(spaces);
    return encoder.convert(this);
  }
}

extension ExtendedRandom on Random {
  int randomUpto(int max) => 0 + nextInt(max - 0);
}
