import 'package:flutter/material.dart';

import '../../utils/polie_design_tokens.dart';
import 'cast_contract.dart';
import 'cast_session.dart';
import 'cast_stage.dart';

/// Part lists come from the contract. Nothing here is a second catalogue.
class CastBuilder extends StatefulWidget {
  const CastBuilder({super.key, this.preset = 'Learner'});

  final String preset;

  @override
  State<CastBuilder> createState() => _CastBuilderState();
}

class _CastBuilderState extends State<CastBuilder> {
  late final CastSession _session = CastSession(preset: widget.preset);
  CastContract? _contract;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSession);
    _load();
  }

  void _onSession() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      final contract = await CastContract.load();
      if (!mounted) return;
      setState(() => _contract = contract);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _session.removeListener(_onSession);
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contract = _contract;
    final scheme = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: PolieColors.goldEmber,
          surface: PolieColors.surfaceContainer,
          onSurface: PolieColors.textPrimary,
        ),
      ),
      child: Material(
        color: PolieColors.surfaceContainer,
        child: contract == null
            ? Center(
                child: _error == null
                    ? const CircularProgressIndicator()
                    : Text('$_error'),
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shape ${castSpokenName(widget.preset)}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: PolieColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Parts, build, and face come from the cast contract.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: PolieColors.textPrimary.withValues(
                                    alpha: 0.72,
                                  ),
                                ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: SizedBox(
                              width: 220,
                              height: 308,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: PolieColors.obsidian,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: CastStage(session: _session),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  for (final slot in contract.partSlots)
                    SliverToBoxAdapter(
                      child: _SlotRow(slot: slot, session: _session),
                    ),
                  SliverToBoxAdapter(
                    child: _EnumRow(
                      title: 'Build',
                      values: contract.enums['bodyType'] ?? const [],
                      selected: _session.pose.bodyType,
                      onSelected: (value) => setState(
                        () => _session.body(value, _session.pose.faceShape),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _EnumRow(
                      title: 'Face',
                      values: contract.enums['faceShape'] ?? const [],
                      selected: _session.pose.faceShape,
                      onSelected: (value) => setState(
                        () => _session.body(_session.pose.bodyType, value),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SwitchListTile(
                      value: _session.pose.wheelchair,
                      activeThumbColor: scheme.tertiary,
                      title: const Text(
                        'Wheelchair',
                        style: TextStyle(color: PolieColors.textPrimary),
                      ),
                      onChanged: (value) =>
                          setState(() => _session.wheelchair(value)),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.slot, required this.session});

  final CastPartSlot slot;
  final CastSession session;

  @override
  Widget build(BuildContext context) {
    final selected = session.pose.parts[slot.name];
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              slot.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: PolieColors.goldEmberLight,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: slot.options.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = slot.options[index];
                final label = option.split('/').last;
                final on = selected == option;
                return ChoiceChip(
                  label: Text(label),
                  selected: on,
                  onSelected: (_) => session.wear(slot.name, option),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EnumRow extends StatelessWidget {
  const _EnumRow({
    required this.title,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: PolieColors.goldEmberLight,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final value = values[index];
                return ChoiceChip(
                  label: Text(value),
                  selected: selected == value,
                  onSelected: (_) => onSelected(value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
