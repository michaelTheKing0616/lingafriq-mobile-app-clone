import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/social_audio/social_audio_room_model.dart';
import '../../providers/social_audio_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/pan_african_design_system.dart';
import '../../utils/supported_languages.dart';
import '../../widgets/loading/loading_overlay.dart';
import '../../widgets/pan_african_components.dart';
import '../../widgets/lingafriq_ui_helpers.dart';
import 'package:intl/intl.dart';

/// Create Room Screen - Create a new language practice room
class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _topicController = TextEditingController();
  String? _selectedLanguage;
  String? _selectedLevel;
  RoomType _selectedType = RoomType.practice;
  bool _dropInNow = true;
  bool _aiFacilitatorEnabled = false;
  int _maxParticipants = 50;
  bool _isPrivate = false;
  DateTime? _scheduledStartTime;
  int? _durationMinutes;
  final List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _topicController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(userProvider);
    if (user == null) {
      showLingAfriqError(context, 'Please log in to create rooms');
      return;
    }

    if (_selectedLanguage == null) {
      showLingAfriqError(context, 'Please select a language');
      return;
    }

    if (_selectedType == RoomType.practice) {
      if (_topicController.text.trim().isEmpty) {
        showLingAfriqError(context, 'Add a topic so learners know what you\'ll practice');
        return;
      }
      if (_selectedLevel == null) {
        showLingAfriqError(context, 'Pick a CEFR level for this room');
        return;
      }
      if (!_dropInNow && _scheduledStartTime == null) {
        showLingAfriqError(context, 'Schedule a start time or choose drop-in now');
        return;
      }
    }

    final room = await ref.read(socialAudioProvider.notifier).createRoom(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          language: _selectedLanguage!,
          type: _selectedType,
          maxParticipants: _maxParticipants,
          isPrivate: _isPrivate,
          tags: _tags,
          scheduledStartTime: _dropInNow ? null : _scheduledStartTime,
          durationMinutes: _durationMinutes,
          practiceTopic: _selectedType == RoomType.practice ? _topicController.text.trim() : null,
          cefrLevel: _selectedLevel,
          dropIn: _dropInNow,
          aiFacilitatorEnabled: _aiFacilitatorEnabled,
        );

    if (!mounted) return;
    if (room != null) {
      showLingAfriqSuccess(context, 'Room created! You can invite others to join.');
      Navigator.pop(context, room);
    } else {
      final err = ref.read(socialAudioProvider).error;
      showLingAfriqError(
        context,
        err?.isNotEmpty == true ? err! : 'Couldn\'t create room. Please try again.',
        onRetry: () => _createRoom(),
      );
    }
  }

  Future<void> _selectScheduleTime() async {
    final now = DateTime.now();
    final initialDate = _scheduledStartTime ?? now.add(const Duration(hours: 1));
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (time != null) {
        setState(() {
          _scheduledStartTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialAudioProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Create practice room', style: Theme.of(context).textTheme.titleLarge),
            Text('Host a Clubhouse-style session', style: TextStyle(fontSize: 12, color: PanAfricanColors.textSecondary)),
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: state.isLoading,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.lg,
            vertical: PanAfricanSpacing.md,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room name
                Semantics(
                  label: 'Room name',
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Room Name',
                      hintText: 'e.g., Yoruba Conversation Practice',
                      helperText: 'At least 3 characters',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a room name';
                    }
                    if (value.trim().length < 3) {
                      return 'Room name must be at least 3 characters';
                    }
                    return null;
                  },
                  ),
                ),
                SizedBox(height: 4.h),

                // Description
                Semantics(
                  label: 'Room description',
                  child: TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'What will this room be about?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                  ),
                ),
                SizedBox(height: 4.h),

                // Language selection — all supported African languages
                DropdownButtonFormField<String>(
                  initialValue: _selectedLanguage,
                  decoration: InputDecoration(
                    labelText: 'Language *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                  ),
                  items: SupportedLanguages.allLanguages.map((langKey) {
                    final info = SupportedLanguages.getLanguageInfo(langKey);
                    final name = info['name'] as String? ?? langKey;
                    return DropdownMenuItem<String>(
                      value: langKey,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedLanguage = value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Select a language for this room';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 4.h),

                // Room type
                DropdownButtonFormField<RoomType>(
                  initialValue: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Room Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                  ),
                  items: RoomType.values.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(_getRoomTypeLabel(type)),
                      )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),
                SizedBox(height: 4.h),

                if (_selectedType == RoomType.practice) ...[
                  Semantics(
                    label: 'Practice topic',
                    child: TextFormField(
                      controller: _topicController,
                      decoration: InputDecoration(
                        labelText: 'Topic',
                        hintText: 'e.g., Market bargaining, Family greetings',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLevel,
                    decoration: InputDecoration(
                      labelText: 'Level (CEFR)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      ),
                    ),
                    items: const ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedLevel = v),
                  ),
                  SizedBox(height: 2.h),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Drop-in now'),
                    subtitle: const Text('Open the room immediately without a schedule'),
                    value: _dropInNow,
                    onChanged: (v) => setState(() {
                      _dropInNow = v;
                      if (v) _scheduledStartTime = null;
                    }),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('AI facilitator'),
                    subtitle: const Text('Labelled AI prompts the host can mute anytime'),
                    value: _aiFacilitatorEnabled,
                    onChanged: (v) => setState(() => _aiFacilitatorEnabled = v),
                  ),
                  SizedBox(height: 2.h),
                ],

                // Max participants
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Max Participants: $_maxParticipants',
                        style: TextStyle(fontSize: 16.sp),
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _maxParticipants.toDouble(),
                        min: 10,
                        max: 100,
                        divisions: 9,
                        label: _maxParticipants.toString(),
                        onChanged: (value) {
                          setState(() => _maxParticipants = value.toInt());
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),

                // Schedule
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Schedule Room'),
                  subtitle: Text(
                    _scheduledStartTime != null
                        ? DateFormat('MMM d, y • h:mm a').format(_scheduledStartTime!)
                        : 'Start immediately',
                  ),
                  trailing: Switch(
                    value: _scheduledStartTime != null,
                    onChanged: (value) {
                      if (value) {
                        _selectScheduleTime();
                      } else {
                        setState(() => _scheduledStartTime = null);
                      }
                    },
                  ),
                ),

                if (_scheduledStartTime != null) ...[
                  ListTile(
                    leading: const Icon(Icons.timer),
                    title: const Text('Duration (minutes)'),
                    subtitle: Text(_durationMinutes?.toString() ?? 'No limit'),
                    trailing: DropdownButton<int>(
                      value: _durationMinutes,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('No limit')),
                        ...([30, 60, 90, 120]).map((mins) => DropdownMenuItem(
                              value: mins,
                              child: Text('$mins min'),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() => _durationMinutes = value);
                      },
                    ),
                  ),
                ],

                // Privacy
                SwitchListTile(
                  value: _isPrivate,
                  onChanged: (value) {
                    setState(() => _isPrivate = value);
                  },
                  title: const Text('Private Room'),
                  subtitle: const Text('Only invited users can join'),
                ),
                SizedBox(height: 4.h),

                // Tags
                Text(
                  'Tags',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagController,
                        decoration: InputDecoration(
                          hintText: 'Add a tag',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                          ),
                        ),
                        onSubmitted: (_) => _addTag(),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addTag,
                    ),
                  ],
                ),
                if (_tags.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 2.h,
                    children: _tags.map((tag) => Chip(
                          label: Text(tag),
                          onDeleted: () => _removeTag(tag),
                        )).toList(),
                  ),
                ],
                SizedBox(height: 4.h),

                // Create button
                Semantics(
                  label: 'Create room',
                  button: true,
                  child: SizedBox(
                    width: double.infinity,
                    child: PanAfricanButton(
                      label: 'Create Room',
                      icon: Icons.add,
                      onPressed: _createRoom,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRoomTypeLabel(RoomType type) {
    switch (type) {
      case RoomType.practice:
        return 'Practice';
      case RoomType.lesson:
        return 'Lesson';
      case RoomType.discussion:
        return 'Discussion';
      case RoomType.pronunciation:
        return 'Pronunciation';
      case RoomType.storytelling:
        return 'Storytelling';
      case RoomType.qa:
        return 'Q&A';
      case RoomType.cultural:
        return 'Cultural';
    }
  }
}

