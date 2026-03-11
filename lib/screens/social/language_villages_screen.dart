import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/language_village_provider.dart';
import '../../models/language_village_model.dart';
import '../../utils/performance_utils.dart';
import '../../utils/pan_african_design_system.dart';
import '../../utils/supported_languages.dart';
import '../../widgets/lingafriq_ui_helpers.dart';
import '../../widgets/pan_african_components.dart';
import '../../screens/chat/live_classroom_screen_material3.dart';
import 'package:lingafriq/avatars/avatars.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/utils/integration_helpers.dart';

/// Language Villages Screen - Voice rooms for target-language-only practice
class LanguageVillagesScreen extends ConsumerWidget {
  const LanguageVillagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final villageProvider = ref.watch(languageVillageProvider.notifier);
    final villages = villageProvider.villages;
    final currentVillage = villageProvider.currentVillage;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Language Villages'),
            Text('LingAfriq', style: TextStyle(fontSize: 12, color: PanAfricanColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showCreateVillageDialog(context, ref);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              villageProvider.refresh();
            },
          ),
        ],
      ),
      body: currentVillage != null
          ? _buildCurrentVillageView(context, ref, currentVillage)
          : _buildVillageList(context, ref, villages),
    );
  }

  Widget _buildVillageList(
    BuildContext context,
    WidgetRef ref,
    List<LanguageVillage> villages,
  ) {
  final colorScheme = Theme.of(context).colorScheme;
    if (villages.isEmpty) {
      return PanAfricanEmptyState(
        icon: Icons.location_city_outlined,
        title: 'No villages available',
        description: 'Create a village to practice your target language with others.',
        actionLabel: 'Create Village',
        onAction: () => _showCreateVillageDialog(context, ref),
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          child: PanAfricanCard(
            hasGlow: true,
            glowColor: PanAfricanColors.primary,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: PanAfricanGradients.savannaGold,
                    borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                  ),
                  child: Icon(Icons.language_rounded, color: colorScheme.onPrimary, size: 28),
                ),
                SizedBox(width: PanAfricanSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Language Villages',
                        style: PanAfricanTypography.titleLarge(context),
                      ),
                      SizedBox(height: PanAfricanSpacing.xxs),
                      Text(
                        'Join a village to practice live and meet other learners.',
                        style: PanAfricanTypography.bodySmall(context).copyWith(
                          color: PanAfricanColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: 'Create village',
                  button: true,
                  child: PanAfricanButton(
                  label: 'Create',
                  icon: Icons.add_rounded,
                  onPressed: () => _showCreateVillageDialog(context, ref),
                  backgroundColor: PanAfricanColors.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: OptimizedListView.builder(
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
            itemCount: villages.length,
            itemBuilder: (context, index) {
              final village = villages[index];
              return _VillageCard(
                village: village,
                onJoin: () async {
                  HapticFeedback.lightImpact();
                  await safeAsync(
                    context: context,
                    operation: () async {
                      final success = await ref
                          .read(languageVillageProvider.notifier)
                          .joinVillage(village.id);
                      if (context.mounted) {
                        if (success) {
                          showLingAfriqSuccess(context, 'Joined ${village.name}!');
                        } else {
                          throw Exception('Failed to join village');
                        }
                      }
                    },
                    errorContext: 'joinVillage',
                    showError: true,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentVillageView(
    BuildContext context,
    WidgetRef ref,
    LanguageVillage village,
  ) {
    final villageProvider = ref.read(languageVillageProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // Village header
        Container(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          decoration: BoxDecoration(
            color: isDark 
                ? PanAfricanColors.surfaceContainerDark 
                : PanAfricanColors.surfaceContainerLight,
            boxShadow: PanAfricanShadows.sm,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          village.name,
                          style: PanAfricanTypography.titleLarge(context).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        SizedBox(height: PanAfricanSpacing.xs),
                        Text(
                          village.description,
                          style: PanAfricanTypography.bodyMedium(context),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.exit_to_app),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      await safeAsync(
                        context: context,
                        operation: () async {
                          await ref.read(languageVillageProvider.notifier).leaveVillage();
                        },
                        errorContext: 'leaveVillage',
                        showError: true,
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              Row(
                children: [
                  Icon(Icons.people, size: 16.sp, color: PanAfricanColors.primary),
                  SizedBox(width: PanAfricanSpacing.xs),
                  Text(
                    '${village.currentParticipants}/${village.maxParticipants}',
                    style: PanAfricanTypography.labelLarge(context),
                  ),
                  SizedBox(width: PanAfricanSpacing.md),
                  Icon(Icons.language, size: 16.sp, color: PanAfricanColors.primary),
                  SizedBox(width: PanAfricanSpacing.xs),
                  Text(
                    '${village.language} only',
                    style: PanAfricanTypography.labelLarge(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Rules
        if (village.rules.isNotEmpty)
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Village Rules',
                  style: PanAfricanTypography.titleMedium(context).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                ...village.rules.map((rule) => Padding(
                      padding: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 16.sp, color: PanAfricanColors.success),
                          SizedBox(width: PanAfricanSpacing.sm),
                          Expanded(
                            child: Text(
                              rule,
                              style: PanAfricanTypography.bodyMedium(context),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        // Voice Room UI
        Expanded(
          child: _VoiceRoomView(
            village: village,
            onLeave: () {
              villageProvider.leaveVillage();
            },
          ),
        ),
      ],
    );
  }

  void _showCreateVillageDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedLanguage;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Create Language Village'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Village Name *',
                      hintText: 'e.g., Yoruba Village',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Village name is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Name must be at least 3 characters';
                      }
                      if (value.trim().length > 50) {
                        return 'Name must be 50 characters or fewer';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                  DropdownButtonFormField<String>(
                    value: selectedLanguage,
                    decoration: InputDecoration(
                      labelText: 'Language *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      ),
                    ),
                    hint: const Text('Select language'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a language';
                      }
                      return null;
                    },
                    items: SupportedLanguages.allLanguages.map((langKey) {
                      final info = SupportedLanguages.getLanguageInfo(langKey);
                      final name = info['name'] as String? ?? langKey;
                      return DropdownMenuItem<String>(
                        value: langKey,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedLanguage = value);
                    },
                  ),
                    SizedBox(height: PanAfricanSpacing.md),
                    TextFormField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description *',
                        hintText: 'What is this village about?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                        ),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        if (value.trim().length < 10) {
                          return 'Description must be at least 10 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              PanAfricanButton(
                label: 'Create',
                onPressed: () async {
                  if (formKey.currentState == null || !formKey.currentState!.validate()) return;
                  final name = nameController.text.trim();
                  final description = descriptionController.text.trim();
                  if (selectedLanguage == null || selectedLanguage!.isEmpty) return;
                  await safeAsync(
                    context: context,
                    operation: () async {
                      final success = await ref
                          .read(languageVillageProvider.notifier)
                          .createVillage(
                            name: name,
                            language: selectedLanguage!,
                            description: description,
                          );
                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                        if (success) {
                          showLingAfriqSuccess(context, 'Village created!');
                        }
                      }
                    },
                    errorContext: 'createVillage',
                    showError: true,
                  );
                },
                hasGradient: true,
                gradientColors: [
                  PanAfricanColors.primary,
                  PanAfricanColors.secondary,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VillageCard extends StatelessWidget {
  final LanguageVillage village;
  final VoidCallback onJoin;

  const _VillageCard({
    required this.village,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final occupancy = village.maxParticipants > 0
        ? (village.currentParticipants / village.maxParticipants).clamp(0.0, 1.0)
        : 0.0;

    return PanAfricanCard(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanAfricanAvatar(
            initials: village.name.isNotEmpty ? village.name[0].toUpperCase() : 'V',
            size: 48.w,
            backgroundColor: PanAfricanColors.primary,
            borderColor: Colors.transparent,
            showBadge: village.currentParticipants >= village.maxParticipants,
            badgeColor: PanAfricanColors.secondary,
          ),
          SizedBox(width: PanAfricanSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  village.name,
                  style: PanAfricanTypography.titleMedium(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.xs),
                Text(
                  village.description,
                  style: PanAfricanTypography.bodyMedium(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                Row(
                  children: [
                    PanAfricanBadge(
                      label: '${village.currentParticipants}/${village.maxParticipants} members',
                      color: PanAfricanColors.primary,
                      icon: Icons.people,
                    ),
                    SizedBox(width: PanAfricanSpacing.sm),
                    PanAfricanBadge(
                      label: village.language,
                      color: PanAfricanColors.secondary,
                      icon: Icons.language,
                    ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                PanAfricanProgressBar(
                  progress: occupancy,
                  color: occupancy >= 0.85
                      ? PanAfricanColors.tertiary
                      : PanAfricanColors.primary,
                  height: 6.h,
                ),
              ],
            ),
          ),
          SizedBox(width: PanAfricanSpacing.sm),
          PanAfricanButton(
            label: 'Join',
            onPressed: village.currentParticipants < village.maxParticipants
                ? () {
                    HapticFeedback.lightImpact();
                    onJoin();
                  }
                : null,
            isOutlined: village.currentParticipants >= village.maxParticipants,
            backgroundColor: PanAfricanColors.primary,
            foregroundColor:
                village.currentParticipants >= village.maxParticipants
                  ? PanAfricanColors.primary
                  : colorScheme.onPrimary,
          ),
        ],
      ),
    );
  }
}

/// Voice Room View Widget
class _VoiceRoomView extends ConsumerStatefulWidget {
  final LanguageVillage village;
  final VoidCallback onLeave;

  const _VoiceRoomView({
    required this.village,
    required this.onLeave,
  });

  @override
  ConsumerState<_VoiceRoomView> createState() => _VoiceRoomViewState();
}

class _VoiceRoomViewState extends ConsumerState<_VoiceRoomView> {
  @override
  Widget build(BuildContext context) {
    ref.watch(languageVillageProvider);
    final villageNotifier = ref.read(languageVillageProvider.notifier);
    final providerParticipants = villageNotifier.participants;
    final isConnected = villageNotifier.isRoomConnected;
    final isMicEnabled = villageNotifier.isMicEnabled;
    final isCameraEnabled = villageNotifier.isCameraEnabled;
    final connectionError = villageNotifier.connectionError;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final participantCount = providerParticipants.isNotEmpty
        ? providerParticipants.length
        : widget.village.currentParticipants;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? PanAfricanGradients.darkSurface
            : PanAfricanGradients.forest,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.md,
              vertical: PanAfricanSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? PanAfricanColors.surfaceContainerDark
                  : PanAfricanColors.surfaceContainerLight,
              boxShadow: PanAfricanShadows.sm,
            ),
            child: Row(
              children: [
                LingAfriqAvatar.fromInitials(
                  username: widget.village.name.isNotEmpty
                      ? widget.village.name
                      : 'Village',
                  size: 40.w,
                ),
                SizedBox(width: PanAfricanSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.village.name,
                        style: PanAfricanTypography.titleMedium(context).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '$participantCount/${widget.village.maxParticipants} participants',
                            style: PanAfricanTypography.bodySmall(context).copyWith(
                              color: PanAfricanColors.textSecondary,
                            ),
                          ),
                          SizedBox(width: PanAfricanSpacing.xs),
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isConnected
                                  ? PanAfricanColors.success
                                  : PanAfricanColors.neutralMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onLeave,
                  tooltip: 'Leave Room',
                ),
              ],
            ),
          ),
          // Connection error banner
          if (connectionError != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.md,
                vertical: PanAfricanSpacing.sm,
              ),
              color: PanAfricanColors.error.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 18.sp, color: PanAfricanColors.error),
                  SizedBox(width: PanAfricanSpacing.sm),
                  Expanded(
                    child: Text(
                      connectionError,
                      style: PanAfricanTypography.bodySmall(context).copyWith(
                        color: PanAfricanColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Participants grid
          Expanded(
            child: providerParticipants.isNotEmpty
                ? GridView.builder(
                    padding: EdgeInsets.all(4.w),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 4.w,
                      mainAxisSpacing: 4.h,
                    ),
                    itemCount: providerParticipants.length,
                    itemBuilder: (context, index) {
                      final participant = providerParticipants[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? PanAfricanColors.cardDark
                              : PanAfricanColors.cardLight,
                          borderRadius:
                              BorderRadius.circular(PanAfricanRadius.md),
                          boxShadow: PanAfricanShadows.sm,
                          border: participant.isSpeaking
                              ? Border.all(
                                  color: PanAfricanColors.success, width: 2.w)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LingAfriqAvatar.fromInitials(
                              username: participant.username,
                              size: 60.r,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              participant.username,
                              style: TextStyle(fontSize: 12.sp),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (participant.isSpeaking)
                              Padding(
                                padding: EdgeInsets.only(top: 2.h),
                                child: Icon(Icons.graphic_eq,
                                    size: 14.sp,
                                    color: PanAfricanColors.success),
                              ),
                          ],
                        ),
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline,
                            size: 48.sp,
                            color: PanAfricanColors.textSecondary),
                        SizedBox(height: PanAfricanSpacing.sm),
                        Text(
                          isConnected
                              ? 'Waiting for others to join...'
                              : 'Connecting to voice room...',
                          style: PanAfricanTypography.bodyMedium(context)
                              .copyWith(color: PanAfricanColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
          ),
          // Controls
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: isDark
                  ? PanAfricanColors.surfaceContainerDark
                  : PanAfricanColors.surfaceContainerLight,
              boxShadow: PanAfricanShadows.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(isMicEnabled ? Icons.mic : Icons.mic_off),
                  iconSize: 32.sp,
                  color: isMicEnabled
                      ? PanAfricanColors.primary
                      : PanAfricanColors.error,
                  onPressed: isConnected
                      ? () {
                          villageNotifier.toggleMicrophone();
                          HapticFeedback.lightImpact();
                        }
                      : null,
                  tooltip: isMicEnabled ? 'Mute' : 'Unmute',
                ),
                IconButton(
                  icon: Icon(isCameraEnabled
                      ? Icons.videocam
                      : Icons.videocam_off),
                  iconSize: 32.sp,
                  color: isCameraEnabled
                      ? PanAfricanColors.primary
                      : PanAfricanColors.neutralMedium,
                  onPressed: isConnected
                      ? () {
                          villageNotifier.toggleCamera();
                          HapticFeedback.lightImpact();
                        }
                      : null,
                  tooltip: isCameraEnabled
                      ? 'Turn off video'
                      : 'Turn on video',
                ),
                PanAfricanButton(
                  label: 'Full View',
                  icon: Icons.fullscreen,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LiveClassroomScreenMaterial3(
                          roomId: widget.village.id,
                          roomName: widget.village.name,
                        ),
                      ),
                    );
                  },
                  backgroundColor: PanAfricanColors.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

