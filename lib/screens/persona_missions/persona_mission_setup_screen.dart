import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/content/persona_mission_service.dart';
import 'package:lingafriq/screens/persona_missions/persona_mission_session_screen.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// User selects setting intensity and optional custom plot (blueprint §42).
class PersonaMissionSetupScreen extends ConsumerStatefulWidget {
  const PersonaMissionSetupScreen({super.key, required this.mission});

  final PersonaMission mission;

  @override
  ConsumerState<PersonaMissionSetupScreen> createState() =>
      _PersonaMissionSetupScreenState();
}

class _PersonaMissionSetupScreenState
    extends ConsumerState<PersonaMissionSetupScreen> {
  late String _selectedSetting;
  final _plotController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSetting = widget.mission.userSettingOptions.isNotEmpty
        ? widget.mission.userSettingOptions.first
        : widget.mission.historicalSetting;
  }

  @override
  void dispose() {
    _plotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    return Scaffold(
      appBar: AppBar(
        title: Text(m.personaTitle),
        backgroundColor: PanAfricanColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            m.historicalSetting,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your scene. Polie will stay in character for each step.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text('Setting', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          ...m.userSettingOptions.map(
            (opt) => RadioListTile<String>(
              value: opt,
              groupValue: _selectedSetting,
              title: Text(opt),
              onChanged: (v) => setState(() => _selectedSetting = v!),
            ),
          ),
          const SizedBox(height: 16),
          Text('Custom plot (optional)', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _plotController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g. You are nervous but determined on your first day…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () {
              final session = PersonaMissionSession(
                mission: m,
                selectedSetting: _selectedSetting,
                customPlot: _plotController.text.trim().isEmpty
                    ? null
                    : _plotController.text.trim(),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PersonaMissionSessionScreen(session: session),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: PanAfricanColors.primary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Begin mission'),
          ),
        ],
      ),
    );
  }
}
