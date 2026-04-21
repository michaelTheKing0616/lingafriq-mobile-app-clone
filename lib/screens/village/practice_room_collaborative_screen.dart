import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/navigation/village_navigation.dart';
import 'package:lingafriq/providers/onboarding_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/modern_griot_design_system.dart';
import 'package:lingafriq/utils/supported_languages.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';
import 'package:lingafriq/widgets/griot/griot_widgets.dart';
import 'package:lingafriq/widgets/game/game_widgets.dart';
import 'package:lingafriq/widgets/livekit/livekit_video_widgets.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';

const _kPracticeDataTopic = 'practice_chat';

/// Live collaborative practice: **LiveKit** WebRTC (same token path as live classroom).
/// Without [roomId]/[roomName], shows a lobby to create a tribe classroom room, then connects.
class PracticeRoomCollaborativeScreen extends HookConsumerWidget {
  const PracticeRoomCollaborativeScreen({
    super.key,
    this.roomId,
    this.roomName,
    this.livekitToken,
    this.livekitUrl,
    this.languageTag,
  });

  final String? roomId;
  final String? roomName;
  final String? livekitToken;
  final String? livekitUrl;
  final String? languageTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (roomId == null ||
        roomId!.isEmpty ||
        roomName == null ||
        roomName!.isEmpty) {
      return _CollaborativeLobbyScreen(
        initialLanguageTag: languageTag,
      );
    }
    return _CollaborativeLiveSession(
      roomId: roomId!,
      roomName: roomName!,
      initialToken: livekitToken,
      initialUrl: livekitUrl,
      languageTag: languageTag,
    );
  }
}

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

class _CollaborativeLobbyScreen extends HookConsumerWidget {
  const _CollaborativeLobbyScreen({this.initialLanguageTag});

  final String? initialLanguageTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomNameController = useTextEditingController();
    final selectedLanguage = useState<String?>(null);
    final isCreating = useState(false);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    useEffect(() {
      selectedLanguage.value = initialLanguageTag;
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: const Text('Collaborative practice'),
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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.xl,
              vertical: PanAfricanSpacing.lg,
            ),
            child: Column(
              children: [
                Icon(Icons.groups_rounded, size: 72.sp, color: cs.primary)
                    .animate()
                    .fadeIn(duration: 400.ms),
                SizedBox(height: PanAfricanSpacing.md),
                Text(
                  'Practice live with others',
                  style: PanAfricanTypography.headlineSmall(context),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  'Creates a server-backed practice room and connects via LiveKit (camera + mic). '
                  'Share notes in the scratchpad — messages sync over the room data channel.',
                  style: PanAfricanTypography.bodyMedium(context).copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: PanAfricanSpacing.xl),
                TextField(
                  controller: roomNameController,
                  decoration: InputDecoration(
                    labelText: 'Room name',
                    hintText: 'e.g. Yoruba tones — tonight',
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                    ),
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.md),
                DropdownButtonFormField<String?>(
                  value: selectedLanguage.value,
                  decoration: InputDecoration(
                    labelText: 'Language tag',
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                    ),
                  ),
                  hint: const Text('Optional'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...SupportedLanguages.allLanguages.map((langKey) {
                      final info = SupportedLanguages.getLanguageInfo(langKey);
                      final name = info['name'] as String? ?? langKey;
                      return DropdownMenuItem<String?>(
                        value: langKey,
                        child: Text(name),
                      );
                    }),
                  ],
                  onChanged: (v) => selectedLanguage.value = v,
                ),
                SizedBox(height: PanAfricanSpacing.xl),
                PanAfricanButton(
                  label: isCreating.value ? 'Creating…' : 'Create & join room',
                  icon: Icons.video_call_rounded,
                  onPressed: isCreating.value
                      ? null
                      : () async {
                          final me = ref.read(userProvider);
                          if (me == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sign in to start a live room.'),
                              ),
                            );
                            return;
                          }
                          if (roomNameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Enter a room name.'),
                              ),
                            );
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
                                    'name': 'Practice: $name',
                                    'language_tag': lang,
                                  },
                                );
                                String rid;
                                if (resp.statusCode == 201 &&
                                    resp.data != null &&
                                    resp.data is Map) {
                                  rid = _extractRoomId(
                                    Map<String, dynamic>.from(resp.data as Map),
                                  );
                                } else {
                                  rid = DateTime.now().millisecondsSinceEpoch.toString();
                                }
                                if (!context.mounted) return;
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/practice-room-collaborative',
                                  arguments: <String, dynamic>{
                                    'roomId': rid,
                                    'roomName': name,
                                    'language': lang,
                                  },
                                );
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScratchChatMessage {
  _ScratchChatMessage({
    required this.author,
    required this.text,
    required this.at,
    this.isLocal = false,
  });

  final String author;
  final String text;
  final String at;
  final bool isLocal;
}

class _CollaborativeLiveSession extends HookConsumerWidget {
  const _CollaborativeLiveSession({
    required this.roomId,
    required this.roomName,
    this.initialToken,
    this.initialUrl,
    this.languageTag,
  });

  final String roomId;
  final String roomName;
  final String? initialToken;
  final String? initialUrl;
  final String? languageTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final displayName = user?.username.trim().isNotEmpty == true
        ? user!.username
        : (user?.global_id ?? 'You');

    final isVideoEnabled = useState(true);
    final isAudioEnabled = useState(true);
    final participants = useState<List<Map<String, dynamic>>>([]);
    final remoteParticipants = useState<Map<String, RemoteParticipant>>({});
    final isLoading = useState(true);
    final joinError = useState<String?>(null);
    final roomState = useState<Room?>(null);
    final localParticipant = useState<LocalParticipant?>(null);
    final messages = useState<List<_ScratchChatMessage>>([]);
    final flashRevealed = useState(false);
    final activeTool = useState(0);
    final scratchController = useTextEditingController();
    final seconds = useState(0);
    final dataCleanup = useRef<VoidCallback?>(null);

    final flash = _flashForLanguage(languageTag);

    useEffect(() {
      var alive = true;
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 1));
        if (!alive || !context.mounted) return false;
        seconds.value++;
        return true;
      });
      return () {
        alive = false;
      };
    }, const []);

    Future<void> connect() async {
      joinError.value = null;
      await safeAsync(
        context: context,
        showError: false,
        operation: () async {
          var token = initialToken ?? '';
          var url = initialUrl ?? AppConfig.liveKitUrl;
          if (token.isEmpty) {
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
            // Fallback: language-village LiveKit token endpoint (used by practice rooms too).
            final code = (languageTag != null && languageTag!.trim().isNotEmpty)
                ? languageTag!.trim()
                : VillageNavigation.isoCodeForLanguageLabel(
                    ref.read(onboardingProvider).selectedLanguage ?? 'swahili',
                  );
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
              'Missing LiveKit token. Configure the classroom token API for this room.',
            );
          }

          final room = Room();
          await room.connect(
            url,
            token,
            roomOptions: RoomOptions(),
          );

          roomState.value = room;
          final localP = room.localParticipant;
          localParticipant.value = localP;

          void syncParticipantList() {
            final local = room.localParticipant;
            final list = <Map<String, dynamic>>[
              {
                'name': displayName,
                'id': local?.sid ?? 'local',
                'isLocal': true,
              },
            ];
            for (final rp in room.remoteParticipants.values) {
              list.add({
                'name': rp.name.isNotEmpty ? rp.name : 'Guest',
                'id': rp.sid,
                'isLocal': false,
              });
            }
            participants.value = list;
            remoteParticipants.value =
                Map<String, RemoteParticipant>.from(room.remoteParticipants);
          }

          syncParticipantList();
          room.addListener(syncParticipantList);

          final listener = room.createListener();
          listener.on<DataReceivedEvent>((event) {
            if (event.topic != _kPracticeDataTopic) return;
            try {
              final json = jsonDecode(utf8.decode(event.data))
                  as Map<String, dynamic>;
              final author = json['author']?.toString() ?? '?';
              final text = json['text']?.toString() ?? '';
              final at = json['ts']?.toString() ??
                  DateTime.now().toIso8601String();
              if (text.trim().isEmpty) return;
              messages.value = [
                ...messages.value,
                _ScratchChatMessage(author: author, text: text, at: at),
              ];
            } catch (_) {}
          });
          dataCleanup.value = () => listener.dispose();

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
              ? 'Could not connect to the practice room.'
              : msg;
          isLoading.value = false;
        },
      );
    }

    useEffect(() {
      connect();
      return () {
        dataCleanup.value?.call();
        dataCleanup.value = null;
        final r = roomState.value;
        if (r != null) {
          r.disconnect();
        }
      };
    }, const []);

    Future<void> leave() async {
      dataCleanup.value?.call();
      final r = roomState.value;
      if (r != null) await r.disconnect();
      roomState.value = null;
      if (context.mounted) Navigator.of(context).pop();
    }

    Future<void> publishScratch(String raw) async {
      final text = raw.trim();
      if (text.isEmpty) return;
      final room = roomState.value;
      final lp = room?.localParticipant;
      if (room == null || lp == null) return;
      final at = DateTime.now().toIso8601String();
      final payload = jsonEncode({
        'author': displayName,
        'text': text,
        'ts': at,
      });
      await lp.publishData(
        utf8.encode(payload),
        reliable: true,
        topic: _kPracticeDataTopic,
      );
      messages.value = [
        ...messages.value,
        _ScratchChatMessage(
          author: displayName,
          text: text,
          at: at,
          isLocal: true,
        ),
      ];
      scratchController.clear();
    }

    final cs = Theme.of(context).colorScheme;
    final timerText =
        '${(seconds.value ~/ 60).toString().padLeft(2, '0')}:${(seconds.value % 60).toString().padLeft(2, '0')}';

    if (isLoading.value) {
      return Scaffold(
        appBar: AppBar(
          title: Text(roomName),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => leave(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (joinError.value != null && roomState.value == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(roomName),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.xl),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 56),
                SizedBox(height: PanAfricanSpacing.md),
                Text(
                  joinError.value!,
                  textAlign: TextAlign.center,
                  style: PanAfricanTypography.bodyLarge(context),
                ),
                SizedBox(height: PanAfricanSpacing.lg),
                FilledButton.icon(
                  onPressed: () {
                    isLoading.value = true;
                    joinError.value = null;
                    connect();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GriotScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => leave(),
                    child: Icon(Icons.arrow_back_rounded,
                        size: 24.sp, color: cs.onSurface),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      roomName,
                      style: ModernGriotTypography.titleMedium(context: context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GriotBadgePill(label: timerText, icon: Icons.timer_outlined),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            SizedBox(
              height: 220.h,
              child: LiveKitParticipantGrid(
                participants: participants.value,
                room: roomState.value,
                localParticipant: localParticipant.value,
                remoteParticipants: remoteParticipants.value,
                isDark: isDark,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _RoundToggle(
                    on: isVideoEnabled.value,
                    iconOn: Icons.videocam_rounded,
                    iconOff: Icons.videocam_off_rounded,
                    label: 'Video',
                    onTap: () async {
                      final next = !isVideoEnabled.value;
                      isVideoEnabled.value = next;
                      await localParticipant.value?.setCameraEnabled(next);
                    },
                  ),
                  _RoundToggle(
                    on: isAudioEnabled.value,
                    iconOn: Icons.mic_rounded,
                    iconOff: Icons.mic_off_rounded,
                    label: 'Mic',
                    onTap: () async {
                      final next = !isAudioEnabled.value;
                      isAudioEnabled.value = next;
                      await localParticipant.value?.setMicrophoneEnabled(next);
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: _buildTools(context, ref, flash, flashRevealed, activeTool, scratchController, messages, publishScratch)),
            _buildEndBar(context, leave),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTools(
    BuildContext context,
    WidgetRef ref,
    _MiniFlash flash,
    ValueNotifier<bool> flashRevealed,
    ValueNotifier<int> activeTool,
    TextEditingController scratchController,
    ValueNotifier<List<_ScratchChatMessage>> messages,
    Future<void> Function(String) publishScratch,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          Row(
            children: [
              _ToolChip(
                label: 'Flashcard',
                selected: activeTool.value == 0,
                onTap: () => activeTool.value = 0,
              ),
              SizedBox(width: 8.w),
              _ToolChip(
                label: 'Scratchpad',
                selected: activeTool.value == 1,
                onTap: () => activeTool.value = 1,
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Expanded(
            child: activeTool.value == 0
                ? _buildFlash(flash, flashRevealed, cs, context)
                : _buildScratchList(
                    context,
                    scratchController,
                    messages,
                    publishScratch,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlash(
    _MiniFlash f,
    ValueNotifier<bool> revealed,
    ColorScheme cs,
    BuildContext context,
  ) {
    return GriotCard(
      surfaceLevel: 1,
      padding: EdgeInsets.all(20.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.style_rounded, size: 28.sp, color: cs.primary),
          SizedBox(height: 12.h),
          Text(
            revealed.value ? f.back : f.front,
            style: ModernGriotTypography.headlineSmall(context: context),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          if (revealed.value)
            Text(
              f.hint,
              style: ModernGriotTypography.bodySmall(
                context: context,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              revealed.value = !revealed.value;
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: cs.primary.withAlpha(20),
                borderRadius: ModernGriotRadius.borderPill,
                border: Border.all(color: cs.primary.withAlpha(60)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    revealed.value
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18.sp,
                    color: cs.primary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    revealed.value ? 'Hide' : 'Reveal',
                    style: ModernGriotTypography.labelLarge(
                      context: context,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScratchList(
    BuildContext context,
    TextEditingController scratchController,
    ValueNotifier<List<_ScratchChatMessage>> messages,
    Future<void> Function(String) publishScratch,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: GriotCard(
            surfaceLevel: 1,
            padding: EdgeInsets.all(12.r),
            child: messages.value.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet. Say hi below — synced for everyone in the room.',
                      style: ModernGriotTypography.bodySmall(
                        context: context,
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    itemCount: messages.value.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (_, i) {
                      final msg = messages.value[i];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GriotAvatar(size: 28),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.author,
                                  style: ModernGriotTypography.labelSmall(
                                    context: context,
                                    color: cs.primary,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  msg.text,
                                  style: ModernGriotTypography.bodySmall(
                                    context: context,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44.h,
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: ModernGriotRadius.borderPill,
                  border: Border.all(color: cs.outlineVariant.withAlpha(38)),
                ),
                child: TextField(
                  controller: scratchController,
                  style: ModernGriotTypography.bodySmall(context: context),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (s) => publishScratch(s),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Message the room…',
                    hintStyle: ModernGriotTypography.bodySmall(
                      context: context,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () => publishScratch(scratchController.text),
              child: Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  gradient: ModernGriotGradients.signatureGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.send_rounded,
                    size: 20.sp, color: ModernGriotColors.onPrimary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEndBar(BuildContext context, Future<void> Function() leave) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.heavyImpact();
            leave();
          },
          child: Container(
            height: 48.h,
            decoration: BoxDecoration(
              color: ModernGriotColors.error,
              borderRadius: ModernGriotRadius.borderPill,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.call_end_rounded,
                      size: 20.sp, color: ModernGriotColors.onError),
                  SizedBox(width: 8.w),
                  Text(
                    'Leave room',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: ModernGriotColors.onError,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniFlash {
  const _MiniFlash(this.front, this.back, this.hint);
  final String front;
  final String back;
  final String hint;
}

_MiniFlash _flashForLanguage(String? tag) {
  final t = (tag ?? 'yo').toLowerCase();
  if (t.contains('sw') || t == 'swahili') {
    return const _MiniFlash('Habari', 'Hello / How are you', 'Common greeting');
  }
  if (t.contains('zu') || t == 'zulu') {
    return const _MiniFlash('Sawubona', 'Hello', 'Literally “I see you”');
  }
  return const _MiniFlash(
    'Ẹ kú àárọ̀',
    'Good morning',
    'Greeting used before noon',
  );
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerLow,
          borderRadius: ModernGriotRadius.borderPill,
        ),
        child: Text(
          label,
          style: ModernGriotTypography.labelMedium(
            context: context,
            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _RoundToggle extends StatelessWidget {
  const _RoundToggle({
    required this.on,
    required this.iconOn,
    required this.iconOff,
    required this.label,
    required this.onTap,
  });

  final bool on;
  final IconData iconOn;
  final IconData iconOff;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Material(
          color: on ? cs.primaryContainer : cs.surfaceContainerHighest,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Icon(
                on ? iconOn : iconOff,
                color: on ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(label, style: ModernGriotTypography.labelSmall(context: context)),
      ],
    );
  }
}
