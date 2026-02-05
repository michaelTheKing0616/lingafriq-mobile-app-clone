import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/language_village_provider.dart';
import '../../models/language_village_model.dart';
import '../../utils/error_handler.dart';
import '../../utils/integration_helpers.dart';
import '../../utils/performance_utils.dart';
import '../../utils/pan_african_design_system.dart';
import '../../utils/supported_languages.dart';
import '../../widgets/lingafriq_ui_helpers.dart';
import '../../widgets/primary_button.dart';
import '../../screens/chat/live_classroom_screen_material3.dart';
import 'package:flutter/services.dart';

/// Language Villages Screen - Voice rooms for target-language-only practice
class LanguageVillagesScreen extends ConsumerWidget {
  const LanguageVillagesScreen({Key? key}) : super(key: key);

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
    if (villages.isEmpty) {
      return LingAfriqEmptyState(
        icon: Icons.location_city_outlined,
        title: 'No villages available',
        subtitle: 'Create a village to practice your target language with others.',
        actionLabel: 'Create Village',
        onAction: () => _showCreateVillageDialog(context, ref),
      );
    }

    return OptimizedListView.builder(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      itemCount: villages.length,
      itemBuilder: (context, index) {
        final village = villages[index];
        return _VillageCard(
          village: village,
          onJoin: () async {
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
    );
  }

  Widget _buildCurrentVillageView(
    BuildContext context,
    WidgetRef ref,
    LanguageVillage village,
  ) {
    final villageProvider = ref.read(languageVillageProvider.notifier);
    return Column(
      children: [
        // Village header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          village.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.exit_to_app),
                    onPressed: () async {
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
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${village.currentParticipants}/${village.maxParticipants}',
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.language, size: 16),
                  const SizedBox(width: 4),
                  Text('${village.language} only'),
                ],
              ),
            ],
          ),
        ),
        // Rules
        if (village.rules.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Village Rules',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...village.rules.map((rule) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(child: Text(rule)),
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
                    TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Village Name',
                      hintText: 'e.g., Yoruba Village',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      ),
                    ),
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
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'What is this village about?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                        ),
                      ),
                      maxLines: 3,
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
              PrimaryButton(
                text: 'Create',
                onTap: () async {
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.location_city, color: Colors.white),
        ),
        title: Text(village.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(village.description),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${village.currentParticipants}/${village.maxParticipants}',
                ),
                const SizedBox(width: 16),
                const Icon(Icons.language, size: 16),
                const SizedBox(width: 4),
                Text('${village.language} only'),
              ],
            ),
          ],
        ),
        trailing: PrimaryButton(
          text: 'Join',
          enabled: village.currentParticipants < village.maxParticipants,
          onTap: onJoin,
        ),
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
  bool _isMuted = false;
  bool _isVideoEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: isDark
                  ? PanAfricanColors.surfaceContainerDark
                  : PanAfricanColors.surfaceContainerLight,
              boxShadow: PanAfricanShadows.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.village.name,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.village.currentParticipants}/${widget.village.maxParticipants} participants',
                        style: TextStyle(fontSize: 12.sp),
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
          // Participants grid
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(4.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 4.w,
                mainAxisSpacing: 4.h,
              ),
              itemCount: widget.village.currentParticipants,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                    borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    boxShadow: PanAfricanShadows.sm,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30.r,
                        backgroundColor: PanAfricanColors.primary,
                        child: Text(
                          'P${index + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Participant ${index + 1}',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ],
                  ),
                );
              },
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
                  icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                  iconSize: 32.sp,
                  color: _isMuted ? Colors.red : PanAfricanColors.primary,
                  onPressed: () {
                    setState(() => _isMuted = !_isMuted);
                    HapticFeedback.lightImpact();
                  },
                  tooltip: _isMuted ? 'Unmute' : 'Mute',
                ),
                IconButton(
                  icon: Icon(_isVideoEnabled ? Icons.videocam : Icons.videocam_off),
                  iconSize: 32.sp,
                  color: _isVideoEnabled ? PanAfricanColors.primary : Colors.grey,
                  onPressed: () {
                    setState(() => _isVideoEnabled = !_isVideoEnabled);
                    HapticFeedback.lightImpact();
                  },
                  tooltip: _isVideoEnabled ? 'Turn off video' : 'Turn on video',
                ),
                PrimaryButton(
                  text: 'Full View',
                  onTap: () {
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
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fullscreen, size: 20.sp, color: Colors.white),
                        SizedBox(width: 8.w),
                        Text('Full View', style: TextStyle(color: Colors.white, fontSize: 16.sp)),
                      ],
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

