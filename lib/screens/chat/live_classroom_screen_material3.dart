import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/supported_languages.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/navigation/village_navigation.dart';
import 'package:lingafriq/providers/onboarding_provider.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:lingafriq/widgets/lingafriq_ui_helpers.dart';
import 'package:lingafriq/widgets/primary_button.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/pan_african_app_bar.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../widgets/whiteboard/interactive_whiteboard.dart';
import 'package:lingafriq/content/lingafriq_ux_voice.dart';
import '../ai_chat/polie_workspace_screen.dart';
import '../../providers/ai_chat_provider_groq.dart';

/// Extracts a room ID from a backend response map, tolerating multiple response shapes.
String _extractRoomId(Map<String, dynamic> data) {
  for (final key in ['tribe', 'classroom', 'room', 'data']) {
    final nested = data[key];
    if (nested is Map) {
      final nestedMap = Map<String, dynamic>.from(nested);
      final id = nestedMap['_id'] ??
          nestedMap['id'] ??
          nestedMap['roomId'] ??
          nestedMap['room_id'];
      if (id != null) return id.toString();
    }
  }
  final id = data['_id'] ?? data['id'] ?? data['roomId'] ?? data['room_id'];
  if (id != null) return id.toString();
  return DateTime.now().millisecondsSinceEpoch.toString();
}

/// Material 3 Live Classroom Screen with LiveKit Integration
/// Features: Video/Audio, Interactive Whiteboard, Screen Sharing
/// Similar to X's Spaces but for educational purposes
class LiveClassroomScreenMaterial3 extends HookConsumerWidget {
  final String? roomId;
  final String? roomName;
  final String? livekitToken;
  final String? livekitUrl;

  const LiveClassroomScreenMaterial3({
    super.key,
    this.roomId,
    this.roomName,
    this.livekitToken,
    this.livekitUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If no room provided, show room selection/creation
    if (roomId == null || roomName == null) {
      return _RoomSelectionScreen();
    }

    return _ClassroomView(
      roomId: roomId!,
      roomName: roomName!,
      initialLivekitToken: livekitToken,
      initialLivekitUrl: livekitUrl,
    );
  }
}

/// Room Selection/Creation Screen
class _RoomSelectionScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomNameController = useTextEditingController();
    final selectedLanguage = useState<String?>(null);
    final isCreating = useState(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
        ),
        title: const Text('Live Classroom'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : PanAfricanGradients.forest,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.xl,
              vertical: PanAfricanSpacing.lg,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 80.sp,
                  color: colorScheme.onPrimary,
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.8, 0.8)),
                SizedBox(height: PanAfricanSpacing.xl),
                Text(
                  'Live Classroom',
                  style: PanAfricanTypography.headlineLarge(context).copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms),
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  'Create or join a virtual classroom with video, audio, and whiteboard',
                  style: PanAfricanTypography.bodyLarge(context).copyWith(
                    color: colorScheme.onPrimary.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms),
                SizedBox(height: PanAfricanSpacing.xxl),
                Semantics(
                  label: 'Room name input',
                  hint: 'Enter classroom name',
                  textField: true,
                  child: TextField(
                    controller: roomNameController,
                    style: PanAfricanTypography.bodyLarge(context),
                    decoration: InputDecoration(
                      labelText: 'Room Name',
                      hintText: 'Enter classroom name',
                      prefixIcon: Icon(Icons.school, color: PanAfricanColors.primary),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 400.ms)
                    .slideY(begin: 0.2, duration: 400.ms),
                SizedBox(height: PanAfricanSpacing.md),
                Semantics(
                  label: 'Language of instruction. Select language for the classroom.',
                  child: DropdownButtonFormField<String?>(
                  value: selectedLanguage.value,
                  style: PanAfricanTypography.bodyLarge(context),
                  decoration: InputDecoration(
                    labelText: 'Language (optional)',
                    prefixIcon: Icon(Icons.language, color: PanAfricanColors.primary),
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                    ),
                  ),
                  hint: const Text('Select language of instruction'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('None')),
                    ...SupportedLanguages.allLanguages.map((langKey) {
                      final info = SupportedLanguages.getLanguageInfo(langKey);
                      final name = info['name'] as String? ?? langKey;
                      return DropdownMenuItem<String?>(
                        value: langKey,
                        child: Text(name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    selectedLanguage.value = value;
                  },
                ),
                )
                    .animate()
                    .fadeIn(delay: 650.ms, duration: 400.ms)
                    .slideY(begin: 0.2, duration: 400.ms),
                SizedBox(height: PanAfricanSpacing.md),
                OutlinedButton.icon(
                  onPressed: () {
                    final langKey = selectedLanguage.value ?? 'yoruba';
                    final info = SupportedLanguages.getLanguageInfo(langKey);
                    final display = info['name'] as String? ?? langKey;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PolieWorkspaceScreen(
                          sourceLanguage: 'English',
                          targetLanguage: display,
                          initialMode: PolieMode.conversation,
                          initialRoleplayScene:
                              'Pre-class warm-up for Live Classroom: $display',
                          conversationOnly: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: const Text('Pre-class with Polie'),
                ),
                SizedBox(height: PanAfricanSpacing.lg),
                Semantics(
                  label: isCreating.value ? 'Creating classroom' : 'Create classroom',
                  button: true,
                  enabled: !isCreating.value,
                  child: PanAfricanButton(
                    label: 'Create Classroom',
                    icon: Icons.add,
                    onPressed: isCreating.value
                        ? null
                        : () async {
                          if (roomNameController.text.trim().isEmpty) {
                            showLingAfriqError(context, 'Please enter a room name');
                            return;
                          }

                          isCreating.value = true;
                          try {
                            await safeAsync(
                              context: context,
                              operation: () async {
                                await ApiService.initialize();
                                final name = roomNameController.text.trim();
                                final lang = selectedLanguage.value ?? 'general';
                                final resp = await ApiService.post(
                                  Api.tribesClassrooms,
                                  data: {
                                    'name': name,
                                    'language_tag': lang,
                                  },
                                );
                                String roomId;
                                if (resp.statusCode == 201 && resp.data != null && resp.data is Map) {
                                  roomId = _extractRoomId(Map<String, dynamic>.from(resp.data as Map));
                                } else {
                                  roomId = DateTime.now().millisecondsSinceEpoch.toString();
                                }
                                if (context.mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => _ClassroomView(
                                        roomId: roomId,
                                        roomName: name,
                                      ),
                                    ),
                                  );
                                }
                              },
                              onError: (e) {
                                ErrorHandler.showError(context, e);
                              },
                            );
                          } finally {
                            if (context.mounted) isCreating.value = false;
                          }
                        },
                  ),
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 400.ms)
                    .scale(delay: 800.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Main Classroom View with Video, Audio, and Whiteboard
class _ClassroomView extends HookConsumerWidget {
  final String roomId;
  final String roomName;
  final String? initialLivekitToken;
  final String? initialLivekitUrl;

  const _ClassroomView({
    required this.roomId,
    required this.roomName,
    this.initialLivekitToken,
    this.initialLivekitUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVideoEnabled = useState(true);
    final isAudioEnabled = useState(true);
    final isWhiteboardVisible = useState(false);
    final isScreenSharing = useState(false);
    final participants = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState(true);
    final joinError = useState<String?>(null);
    final roomState = useState<Room?>(null);
    final localParticipant = useState<LocalParticipant?>(null);
    final remoteParticipants = useState<Map<String, RemoteParticipant>>({});
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final whiteboardController = useMemoized(() => WhiteboardController());
    final dataListenerCleanup = useRef<VoidCallback?>(null);

    Future<void> joinClassroom() async {
      joinError.value = null;
      await safeAsync(
        context: context,
        showError: false,
        operation: () async {
          String token = initialLivekitToken ?? '';
          String url = initialLivekitUrl ?? AppConfig.liveKitUrl;
          if (token.isEmpty) {
            // Backward-compatible fallback for older entry points.
            final response = await ApiService.get(
              AppConfig.chatClassroomToken(roomId),
            );
            if (response.statusCode == 200 && response.data is Map) {
              final payload = Map<String, dynamic>.from(response.data as Map);
              final data = payload['data'];
              if (data is Map) {
                final d = Map<String, dynamic>.from(data);
                token = d['token'] as String? ?? '';
                url = d['url'] as String? ?? AppConfig.liveKitUrl;
              }
            }
          }
          if (token.isEmpty) {
            // Fallback: language-village LiveKit token endpoint.
            // This unblocks classrooms in deployments where the legacy classroom-token
            // endpoint is locked or not configured.
            final onboarding = ref.read(onboardingProvider);
            final label = onboarding.selectedLanguage ?? 'swahili';
            final code = VillageNavigation.isoCodeForLanguageLabel(label);
            final response = await ApiService.get(
              ApiContract.url(ApiContract.villages.livekitToken(code)),
            );
            if (response.statusCode == 200 && response.data is Map) {
              final payload = Map<String, dynamic>.from(response.data as Map);
              final data = payload['data'];
              if (data is Map) {
                final d = Map<String, dynamic>.from(data);
                token = d['token'] as String? ?? token;
                url = d['url'] as String? ?? url;
              }
            }
          }
          if (token.isEmpty) {
            throw Exception(
              'Live classroom needs a LiveKit token from the server. '
              'Ask your admin to configure the chat classroom token endpoint, or open this room from a scheduled class that includes credentials.',
            );
          }

            // Initialize LiveKit Room
            final room = Room();
            await room.connect(
              url,
              token,
              roomOptions: RoomOptions(
                // Audio and video options are set via LocalTrackPublication in newer API
                // defaultAudioOptions and defaultVideoOptions removed in livekit_client 1.5.6+
              ),
            );

            // Store room reference
            roomState.value = room;
            localParticipant.value = room.localParticipant;

            // Set up participant tracking
            final localP = room.localParticipant;
            participants.value = [
              {
                'name': localP?.name ?? 'You',
                'id': localP?.sid ?? 'local',
                'isLocal': true,
              },
            ];

            // Listen for remote participants
            room.addListener(() {
              final remoteParts = <String, RemoteParticipant>{};
              final participantList = <Map<String, dynamic>>[
                {
                  'name': localP?.name ?? 'You',
                  'id': localP?.sid ?? 'local',
                  'isLocal': true,
                },
              ];

              // LiveKit 2.x: remote participants are exposed via `room.remoteParticipants`.
              for (final participant in room.remoteParticipants.values) {
                remoteParts[participant.sid] = participant;
                participantList.add({
                  'name': participant.name,
                  'id': participant.sid,
                  'isLocal': false,
                });
              }

              remoteParticipants.value = remoteParts;
              participants.value = participantList;
            });

            // Listen for whiteboard data from remote participants
            final eventsListener = room.createListener();
            eventsListener.on<DataReceivedEvent>((event) {
              if (event.topic != 'whiteboard') return;
              try {
                final json = jsonDecode(utf8.decode(event.data))
                    as Map<String, dynamic>;
                final action = json['action'] as String?;
                if (action == 'clear') {
                  whiteboardController.remoteClear();
                } else if (action == 'draw') {
                  final points = (json['points'] as List)
                      .map((p) => DrawingPoint.fromJson(
                          Map<String, dynamic>.from(p as Map)))
                      .toList();
                  whiteboardController.addRemotePoints(points);
                }
              } catch (_) {
                // Ignore malformed whiteboard data
              }
            });
            dataListenerCleanup.value = () => eventsListener.dispose();

            // Enable camera and microphone
            if (localP != null) {
              await localP.setCameraEnabled(isVideoEnabled.value);
              await localP.setMicrophoneEnabled(isAudioEnabled.value);
            }

            isLoading.value = false;
        },
        onError: (e) {
          final msg = e is DioException
              ? TransportErrorPolicy.toUserMessage(e)
              : e.toString().replaceFirst('Exception: ', '').trim();
          joinError.value = msg.isEmpty
              ? 'Could not join the live classroom. Please try again.'
              : msg;
          isLoading.value = false;
        },
      );
    }

    Future<void> leaveClassroom() async {
      dataListenerCleanup.value?.call();
      dataListenerCleanup.value = null;
      final room = roomState.value;
      if (room != null) {
        await room.disconnect();
        roomState.value = null;
        localParticipant.value = null;
        remoteParticipants.value = {};
      }
    }

    useEffect(() {
      joinClassroom();
      return () {
        leaveClassroom();
        whiteboardController.dispose();
      };
    }, []);

    return Scaffold(
      appBar: PanAfricanAppBar(
        title: roomName,
        subtitle: '${participants.value.length} participants',
        showBackButton: true,
        actions: [
          Semantics(
            label: isWhiteboardVisible.value ? 'Hide whiteboard' : 'Show whiteboard',
            button: true,
            child: IconButton(
              icon: Icon(
                isWhiteboardVisible.value ? Icons.edit : Icons.edit_outlined,
                semanticLabel: isWhiteboardVisible.value ? 'Hide whiteboard' : 'Show whiteboard',
              ),
              onPressed: () {
                isWhiteboardVisible.value = !isWhiteboardVisible.value;
                HapticFeedback.lightImpact();
              },
              tooltip: 'Toggle Whiteboard',
            ),
          ),
          Semantics(
            label: 'View participants, ${participants.value.length} in room',
            button: true,
            child: IconButton(
              icon: Icon(Icons.people_outline, semanticLabel: 'Participants'),
              onPressed: () {
                _showParticipantsDialog(context, participants.value, isDark);
              },
              tooltip: 'Participants',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : PanAfricanGradients.forest,
        ),
        child: isLoading.value
            ? Center(
                child: CircularProgressIndicator(
                  color: PanAfricanColors.primary,
                ),
              )
            : roomState.value == null && joinError.value != null
                ? Padding(
                    padding: EdgeInsets.all(PanAfricanSpacing.xl),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam_off_outlined,
                            size: 64.sp,
                            color: PanAfricanColors.neutralMedium,
                          ),
                          SizedBox(height: PanAfricanSpacing.md),
                          Text(
                            'Could not connect',
                            style: PanAfricanTypography.titleLarge(context),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: PanAfricanSpacing.sm),
                          Text(
                            joinError.value!,
                            style: PanAfricanTypography.bodyMedium(context),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: PanAfricanSpacing.xl),
                          FilledButton.icon(
                            onPressed: () {
                              isLoading.value = true;
                              joinClassroom();
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                          SizedBox(height: PanAfricanSpacing.md),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Leave'),
                          ),
                        ],
                      ),
                    ),
                  )
            : Column(
                children: [
                  // Video Grid
                  Expanded(
                    flex: isWhiteboardVisible.value ? 2 : 3,
                    child: _VideoGrid(
                      participants: participants.value,
                      room: roomState.value,
                      localParticipant: localParticipant.value,
                      remoteParticipants: remoteParticipants.value,
                      isDark: isDark,
                    ),
                  ),

                  // Whiteboard (if visible)
                  if (isWhiteboardVisible.value)
                    Expanded(
                      flex: 1,
                      child: InteractiveWhiteboard(
                        roomId: roomId,
                        controller: whiteboardController,
                        onStrokeComplete: (newPoints) {
                          final room = roomState.value;
                          if (room == null) return;
                          try {
                            final jsonStr = jsonEncode({
                              'type': 'whiteboard',
                              'action': 'draw',
                              'points':
                                  newPoints.map((p) => p.toJson()).toList(),
                            });
                            room.localParticipant?.publishData(
                              utf8.encode(jsonStr),
                              reliable: true,
                              topic: 'whiteboard',
                            );
                          } catch (_) {}
                        },
                        onBoardCleared: () {
                          final room = roomState.value;
                          if (room == null) return;
                          try {
                            final jsonStr = jsonEncode({
                              'type': 'whiteboard',
                              'action': 'clear',
                            });
                            room.localParticipant?.publishData(
                              utf8.encode(jsonStr),
                              reliable: true,
                              topic: 'whiteboard',
                            );
                          } catch (_) {}
                        },
                      ),
                    ),

                  // Controls
                  _ClassroomControls(
                    isVideoEnabled: isVideoEnabled.value,
                    isAudioEnabled: isAudioEnabled.value,
                    isScreenSharing: isScreenSharing.value,
                    onVideoToggle: (value) async {
                      isVideoEnabled.value = value;
                      final localP = localParticipant.value;
                      await localP?.setCameraEnabled(value);
                      HapticFeedback.mediumImpact();
                    },
                    onAudioToggle: (value) async {
                      isAudioEnabled.value = value;
                      final localP = localParticipant.value;
                      await localP?.setMicrophoneEnabled(value);
                      HapticFeedback.mediumImpact();
                    },
                    onScreenShareToggle: (value) async {
                      final localP = localParticipant.value;
                      if (localP == null) {
                        if (context.mounted) {
                          showLingAfriqError(
                              context, 'Not connected to classroom');
                        }
                        return;
                      }
                      try {
                        await localP.setScreenShareEnabled(value);
                        isScreenSharing.value = value;
                        HapticFeedback.mediumImpact();
                      } catch (e) {
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title:
                                  const Text('Screen Sharing Unavailable'),
                              content: const Text(
                                'Screen sharing could not be started. '
                                'On mobile devices this feature may require '
                                'additional platform setup.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                    onLeave: () async {
                      await leaveClassroom();
                      if (!context.mounted) return;
                      final review = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Class ended'),
                          content: Text(
                            '${LingAfriqUxVoice.dailyPractice.first}\n\nReview with Polie while the session is fresh?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Not now'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Post-class with Polie'),
                            ),
                          ],
                        ),
                      );
                      if (review == true && context.mounted) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PolieWorkspaceScreen(
                              sourceLanguage: 'English',
                              targetLanguage: roomName,
                              initialMode: PolieMode.conversation,
                              initialRoleplayScene:
                                  'Post-class summary for "$roomName": recap key phrases, one pronunciation tip, and one challenge for tomorrow.',
                              conversationOnly: true,
                            ),
                          ),
                        );
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    isDark: isDark,
                  ),
                ],
              ),
      ),
    );
  }

  void _showParticipantsDialog(
    BuildContext context,
    List<Map<String, dynamic>> participants,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final dialogColorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
        backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
        title: Text(
          'Participants (${participants.length})',
          style: PanAfricanTypography.titleLarge(context),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participant = participants[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: PanAfricanColors.primary,
                  child: Text(
                    (participant['name'] ?? 'U')[0].toUpperCase(),
                    style: TextStyle(color: dialogColorScheme.onPrimary),
                  ),
                ),
                title: Text(
                  participant['name'] ?? 'Participant',
                  style: PanAfricanTypography.bodyLarge(context),
                ),
                trailing: participant['id'] == 'local'
                    ? Chip(
                        label: Text('You'),
                        backgroundColor: PanAfricanColors.primary,
                        labelStyle: TextStyle(color: dialogColorScheme.onPrimary),
                      )
                    : null,
              );
            },
          ),
        ),
        actions: [
          Semantics(
            label: 'Close participants list',
            button: true,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ),
        ],
      );
      },
    );
  }
}

/// Video Grid Widget
class _VideoGrid extends StatelessWidget {
  final List<Map<String, dynamic>> participants;
  final Room? room;
  final LocalParticipant? localParticipant;
  final Map<String, RemoteParticipant> remoteParticipants;
  final bool isDark;

  const _VideoGrid({
    required this.participants,
    this.room,
    this.localParticipant,
    required this.remoteParticipants,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (participants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 64.sp,
              color: colorScheme.onPrimary.withOpacity(0.7),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Waiting for participants...',
              style: PanAfricanTypography.bodyLarge(context).copyWith(
                color: colorScheme.onPrimary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: participants.length <= 2 ? 1 : 2,
        crossAxisSpacing: PanAfricanSpacing.sm,
        mainAxisSpacing: PanAfricanSpacing.sm,
        childAspectRatio: 16 / 9,
      ),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final participant = participants[index];
        final isLocal = participant['isLocal'] == true;
        final participantId = participant['id'] as String;
        
        // Get the actual participant object
        Participant? liveParticipant;
        if (isLocal && localParticipant != null) {
          liveParticipant = localParticipant;
        } else if (!isLocal) {
          liveParticipant = remoteParticipants[participantId];
        }
        
        return _VideoTile(
          participant: participant,
          liveParticipant: liveParticipant,
          isDark: isDark,
        )
            .animate(delay: (index * 100).ms)
            .fadeIn(duration: 300.ms)
            .scale(begin: const Offset(0.9, 0.9), duration: 300.ms);
      },
    );
  }
}

/// Classroom Controls
class _ClassroomControls extends StatelessWidget {
  final bool isVideoEnabled;
  final bool isAudioEnabled;
  final bool isScreenSharing;
  final Function(bool) onVideoToggle;
  final Function(bool) onAudioToggle;
  final Function(bool) onScreenShareToggle;
  final VoidCallback onLeave;
  final bool isDark;

  const _ClassroomControls({
    required this.isVideoEnabled,
    required this.isAudioEnabled,
    required this.isScreenSharing,
    required this.onVideoToggle,
    required this.onAudioToggle,
    required this.onScreenShareToggle,
    required this.onLeave,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.surfaceContainerLight,
        boxShadow: PanAfricanShadows.lg,
      ),
        child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Semantics(
            label: isVideoEnabled ? 'Turn off camera' : 'Turn on camera',
            button: true,
            child: _ControlButton(
            icon: isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            label: 'Video',
            isActive: isVideoEnabled,
            onPressed: () => onVideoToggle(!isVideoEnabled),
            isDark: isDark,
          ),
          ),
          Semantics(
            label: isAudioEnabled ? 'Mute microphone' : 'Unmute microphone',
            button: true,
            child: _ControlButton(
            icon: isAudioEnabled ? Icons.mic : Icons.mic_off,
            label: 'Audio',
            isActive: isAudioEnabled,
            onPressed: () => onAudioToggle(!isAudioEnabled),
            isDark: isDark,
          ),
          ),
          Semantics(
            label: isScreenSharing ? 'Stop sharing screen' : 'Share screen',
            button: true,
            child: _ControlButton(
            icon: Icons.screen_share,
            label: 'Share',
            isActive: isScreenSharing,
            onPressed: () => onScreenShareToggle(!isScreenSharing),
            isDark: isDark,
          ),
          ),
          Semantics(
            label: 'Leave classroom',
            button: true,
            child: PrimaryButton(
            text: 'Leave',
            color: PanAfricanColors.error,
            textColor: colorScheme.onPrimary,
            onTap: onLeave,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.call_end, size: 20.sp, color: colorScheme.onPrimary),
                SizedBox(width: 8.w),
                Text('Leave', style: TextStyle(color: colorScheme.onPrimary, fontSize: 18.sp)),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;
  final bool isDark;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: isActive ? PanAfricanColors.primary : PanAfricanColors.error,
          iconSize: 32.sp,
        ),
        Text(
          label,
          style: PanAfricanTypography.labelSmall(context),
        ),
      ],
    );
  }
}

/// Video Tile Widget
class _VideoTile extends StatelessWidget {
  final Map<String, dynamic> participant;
  final Participant? liveParticipant;
  final bool isDark;

  const _VideoTile({
    required this.participant,
    this.liveParticipant,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        border: Border.all(
          color: PanAfricanColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // LiveKit video track rendering
          _buildVideoTrack(context),
          // Name overlay
          Positioned(
            bottom: PanAfricanSpacing.sm,
            left: PanAfricanSpacing.sm,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.sm,
                vertical: PanAfricanSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
              ),
              child: Text(
                participant['name'] ?? 'Participant',
                style: PanAfricanTypography.labelSmall(context)
                    .copyWith(color: colorScheme.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoTrack(BuildContext context) {
    // Find video track from participant
    VideoTrack? videoTrack;
    if (liveParticipant != null) {
      // Get video track publications from participant
      // LiveKit 1.5.6+ API: trackPublications is a Map<String, TrackPublication>
      final trackPublications = liveParticipant!.trackPublications.values;
      // Filter for video tracks - check if track is VideoTrack type
      final videoPublications = trackPublications
          .where((pub) => pub.subscribed && pub.track != null && pub.track is VideoTrack)
          .toList();
      
      if (videoPublications.isNotEmpty) {
        final firstPublication = videoPublications.first;
        videoTrack = firstPublication.track as VideoTrack?;
      }
    }

    if (videoTrack != null) {
      // Render actual LiveKit video track using VideoTrackRenderer
      return VideoTrackRenderer(videoTrack);
    }

    // Fallback to avatar when no video track available
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40.r,
            backgroundColor: PanAfricanColors.primary,
            child: Text(
              (participant['name'] ?? 'U')[0].toUpperCase(),
              style: PanAfricanTypography.headlineSmall(context)
                  .copyWith(color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Text(
            participant['name'] ?? 'Participant',
            style: PanAfricanTypography.titleMedium(context),
          ),
        ],
      ),
    );
  }
}

