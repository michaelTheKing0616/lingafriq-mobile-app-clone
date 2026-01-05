import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/social_audio/social_audio_room_model.dart';
import '../../providers/social_audio_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/loading/loading_overlay.dart';
import 'package:intl/intl.dart';

/// Create Room Screen - Create a new language practice room
class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedLanguage;
  RoomType _selectedType = RoomType.practice;
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
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(userProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to create rooms')),
      );
      return;
    }

    if (_selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a language')),
      );
      return;
    }

    final room = await ref.read(socialAudioProvider.notifier).createRoom(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          language: _selectedLanguage!,
          type: _selectedType,
          maxParticipants: _maxParticipants,
          isPrivate: _isPrivate,
          tags: _tags,
          scheduledStartTime: _scheduledStartTime,
          durationMinutes: _durationMinutes,
        );

    if (room != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room created successfully!')),
      );
      Navigator.pop(context, room);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Room'),
      ),
      body: LoadingOverlay(
        isLoading: state.isLoading,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Room Name',
                    hintText: 'e.g., Yoruba Conversation Practice',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a room name';
                    }
                    if (value.length < 3) {
                      return 'Room name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 4.h),

                // Description
                TextFormField(
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
                SizedBox(height: 4.h),

                // Language selection
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: InputDecoration(
                    labelText: 'Language *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                  ),
                  items: ['Yoruba', 'Swahili', 'Zulu', 'Igbo', 'Hausa', 'Xhosa', 'Amharic']
                      .map((lang) => DropdownMenuItem(
                            value: lang,
                            child: Text(lang),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedLanguage = value);
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a language';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 4.h),

                // Room type
                DropdownButtonFormField<RoomType>(
                  value: _selectedType,
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
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _createRoom,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Room'),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 3.h),
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

