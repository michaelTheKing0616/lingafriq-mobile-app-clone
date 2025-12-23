import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:dio/dio.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'community_chat_screen.dart';

/// Material 3 Community Chat Screen (wrapper/alias)
/// Uses the existing community_chat_screen.dart which already has Material 3 design
class CommunityChatScreenMaterial3 extends StatelessWidget {
  final String villageId;
  final String villageName;

  const CommunityChatScreenMaterial3({
    Key? key,
    required this.villageId,
    required this.villageName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommunityChatScreen(
      villageId: villageId,
      villageName: villageName,
    );
  }
}

