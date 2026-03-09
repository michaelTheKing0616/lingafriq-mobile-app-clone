import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import '../../utils/error_handler.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/gamification_services_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/lingafriq_ui_helpers.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/responsive_safe_area.dart';
import '../../screens/loading/dynamic_loading_screen.dart';

/// Tribe Selection Screen
class TribeSelectionScreen extends ConsumerStatefulWidget {
  const TribeSelectionScreen({super.key});

  @override
  ConsumerState<TribeSelectionScreen> createState() => _TribeSelectionScreenState();
}

class _TribeSelectionScreenState extends ConsumerState<TribeSelectionScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _availableTribes = [];
  String? _currentTribeId;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadTribes();
  }

  Future<void> _loadTribes() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final tribesService = ref.read(tribesServiceProvider);
      final user = ref.read(userProvider);

      // Fetch tribes from API
      final tribes = await tribesService.getAllTribes();
      _availableTribes = tribes.map((tribe) => {
        'name': tribe['name'] as String,
        'id': tribe['id'] as String,
        'slug': tribe['slug'] as String?,
        'members_count': tribe['members_count'] as int?,
        'language_tag': tribe['language_tag'] as String?,
      }).toList();

      // Get user's current tribe if exists
      if (user != null) {
        final userTribes = await tribesService.getUserTribes(user.id.toString());
        if (userTribes.isNotEmpty) {
          _currentTribeId = userTribes.first['tribe_id'] as String?;
        }
      }
    } catch (e) {
      _loadError = e is DioException ? TransportErrorPolicy.toUserMessage(e) : e.toString();
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
      _availableTribes = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinTribe(String tribeId, String tribeName) async {
    final id = tribeId.toString();
    if (id.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final tribesService = ref.read(tribesServiceProvider);
      await tribesService.joinTribe(id);

      final gamification = ref.read(gamificationProvider.notifier);
      await gamification.selectTribe(tribeName);

      setState(() => _currentTribeId = id);

      if (mounted) {
        showLingAfriqSuccess(context, 'Joined $tribeName tribe!');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, customMessage: _tribeJoinErrorMessage(e));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _tribeJoinErrorMessage(dynamic e) {
    if (e is DioException) {
      return TransportErrorPolicy.toUserMessage(e);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final gamification = ref.watch(gamificationProvider.notifier);
    final currentTribe = gamification.gamification.tribe;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_isLoading && _availableTribes.isEmpty && _loadError == null) {
      return const Scaffold(
        body: DynamicLoadingScreen(),
      );
    }

    if (_loadError != null && _availableTribes.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Choose Your Tribe',
            style: PanAfricanTypography.headlineMedium(context),
          ),
          leading: Semantics(
            label: 'Back',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, semanticLabel: 'Back'),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
          ),
        ),
        body: ResponsiveSafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 64.sp,
                    color: PanAfricanColors.error,
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                  Text(
                    _loadError!,
                    textAlign: TextAlign.center,
                    style: PanAfricanTypography.bodyLarge(context),
                  ),
                  SizedBox(height: PanAfricanSpacing.lg),
                  Semantics(
                    label: 'Try again',
                    button: true,
                    child: PrimaryButton(
                      text: 'Try again',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _loadTribes();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    final tribes = _availableTribes;

    // Map tribe names to emojis
    final Map<String, String> tribeEmojis = {
      'Zulu': '🇿🇦',
      'Yoruba': '🇳🇬',
      'Igbo': '🇳🇬',
      'Hausa': '🇳🇬',
      'Swahili': '🇰🇪',
      'Amhara': '🇪🇹',
      'Xhosa': '🇿🇦',
      'Shona': '🇿🇼',
      'Twi': '🇬🇭',
      'Wolof': '🇸🇳',
      'Somali': '🇸🇴',
      'Luo': '🇰🇪',
      'Kikuyu': '🇰🇪',
      'Oromo': '🇪🇹',
      'Mandinka': '🇬🇲',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Choose Your Tribe',
          style: PanAfricanTypography.headlineMedium(context),
        ),
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, semanticLabel: 'Back'),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card with gradient
            Container(
              decoration: BoxDecoration(
                gradient: PanAfricanGradients.forest,
                borderRadius: PanAfricanRadius.lgBR,
                boxShadow: PanAfricanShadows.md,
              ),
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.groups_rounded,
                        color: colorScheme.onPrimary,
                        size: 32.sp,
                      ),
                      SizedBox(width: PanAfricanSpacing.sm),
                      Text(
                        'Join a Tribe',
                        style: PanAfricanTypography.titleLarge(context, color: colorScheme.onPrimary),
                      ),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  Text(
                    'Tribes compete in leaderboards and events. '
                    'Choose the tribe that represents your heritage or interests!',
                    style: PanAfricanTypography.bodyMedium(context, color: colorScheme.onPrimary.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            Text(
              'Available Tribes',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            if (tribes.isEmpty)
              Container(
                padding: EdgeInsets.all(PanAfricanSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                  borderRadius: PanAfricanRadius.lgBR,
                  border: Border.all(
                    color: isDark
                        ? PanAfricanColors.borderDark
                        : PanAfricanColors.borderLight,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      color: PanAfricanColors.neutralMedium,
                      size: 28.sp,
                    ),
                    SizedBox(height: PanAfricanSpacing.sm),
                    Text(
                      'No tribes available yet',
                      style: PanAfricanTypography.titleSmall(context),
                    ),
                    SizedBox(height: PanAfricanSpacing.xxs),
                    Text(
                      'Please refresh once the server is reachable.',
                      textAlign: TextAlign.center,
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                  ],
                ),
              ),
            ...tribes.map((tribe) {
              final isSelected = currentTribe == tribe['name'] || _currentTribeId == tribe['id'];
              return Semantics(
                label: '${tribe['name']} tribe. ${isSelected ? 'Joined' : 'Tap to join'}',
                button: !_isLoading,
                child: GestureDetector(
                onTap: _isLoading
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        _joinTribe(tribe['id'], tribe['name']);
                      },
                child: Container(
                  margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                    borderRadius: PanAfricanRadius.lgBR,
                    border: Border.all(
                      color: isSelected
                          ? PanAfricanColors.success
                          : (isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? PanAfricanShadows.md : PanAfricanShadows.sm,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? PanAfricanColors.success.withOpacity(0.15)
                                : PanAfricanColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              tribeEmojis[tribe['name']] ?? '🏛️',
                              style: TextStyle(fontSize: 24.sp),
                            ),
                          ),
                        ),
                        SizedBox(width: PanAfricanSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tribe['name'],
                                style: PanAfricanTypography.titleSmall(
                                  context,
                                  color: isSelected ? PanAfricanColors.success : null,
                                ),
                              ),
                              SizedBox(height: PanAfricanSpacing.xxxs),
                              Text(
                                'Join the ${tribe['name']} tribe',
                                style: PanAfricanTypography.bodySmall(context),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: EdgeInsets.all(PanAfricanSpacing.xxs),
                            decoration: BoxDecoration(
                              color: PanAfricanColors.success.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: PanAfricanColors.success,
                              size: 24.sp,
                            ),
                          )
                        else if (_isLoading)
                          SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: PanAfricanColors.primary,
                            ),
                          )
                        else
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16.sp,
                            color: PanAfricanColors.neutralMedium,
                            semanticLabel: 'Join',
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

