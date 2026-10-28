import 'package:flutter/material.dart';
import 'package:lingafriq/avatars/cast/cast_contract.dart';
import 'package:lingafriq/avatars/cast/cast_session.dart';
import 'package:lingafriq/avatars/cast/cast_stage.dart';
import 'package:lingafriq/avatars/customisation/palette.dart';
import 'package:lingafriq/avatars/customisation/slot_binding.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';

/// Server-verified mastery ids (ADR-032). Client never invents unlocks.
class AvatarEditorEntitlements {
  const AvatarEditorEntitlements({this.unlockedMasteryIds = const {}});

  final Set<String> unlockedMasteryIds;

  static const starterParts = <String>{
    'Hair/None',
    'Hair/Afro',
    'Hair/ShortCoils',
    'Headwear/None',
    'Top/Tee',
    'Bottom/Trousers',
    'Bottom/Shorts',
    'Accessory/None',
    'Prop/None',
  };

  bool isUnlocked({
    required AvatarSlotDefinition slot,
    required String artboardId,
  }) {
    if (starterParts.contains(artboardId)) return true;
    if (artboardId == 'Hair/None' ||
        artboardId == 'Headwear/None' ||
        artboardId.endsWith('/None')) {
      return true;
    }
    final mastery = AvatarEditorCatalog.masteryIdFor(artboardId);
    if (mastery != null) {
      return unlockedMasteryIds.contains(mastery);
    }
    if (slot.sourceFor(artboardId) == AvatarPartSource.streamedPack) {
      return unlockedMasteryIds.contains('mastery:style_stream_pack');
    }
    return true;
  }

  String lockReason(BuildContext context, String artboardId) {
    final l10n = AppLocalizations.of(context)!;
    final mastery = AvatarEditorCatalog.masteryIdFor(artboardId);
    if (mastery == 'mastery:greetings_respect') {
      return l10n.avatarItemLockedReasonGreetings;
    }
    if (mastery == 'mastery:tone_checkpoint') {
      return l10n.avatarItemLockedReasonTone;
    }
    if (mastery == 'mastery:fugu_cultural_review') {
      return l10n.avatarItemLockedReasonCulturalReview;
    }
    if (mastery == 'mastery:isicholo_context') {
      return l10n.avatarItemLockedReasonIsicholo;
    }
    if (mastery != null) {
      return l10n.avatarItemLockedReasonMastery;
    }
    return l10n.avatarItemLockedReasonStreamPack;
  }
}

/// One-line cultural notes sourced from [cultural_design_bible.md] (P11-034).
class AvatarEditorCatalog {
  const AvatarEditorCatalog._();

  static const Map<String, String> culturalNotes = {
    'Hair/FulaniBraids':
        'Fulani braids: centre braid with side braids; beads mark celebration, not loot.',
    'Hair/Shuku': 'Yoruba shuku — a braided crown style in Yorùbá hair art.',
    'Hair/BantuKnots': 'Bantu knots: coiled knots common across southern Africa.',
    'Hair/IrunKiko': 'Irun kiko: thread-wrapped Yoruba protective style.',
    'Hair/Locs': 'Locs: rope-like locks worn across the diaspora.',
    'Hair/Albaso': 'Albaso: Ethiopian cornrows finishing in a full puff.',
    'Hair/Afro': 'Afro: coiled texture with a rounded silhouette.',
    'Hair/ShortCoils': 'Short coils: close natural texture for everyday wear.',
    'Headwear/Gele':
        'Gele: tied wrap; height and knot reflect the occasion.',
    'Headwear/Fila': 'Fila: Yoruba cap; flop direction is personal taste.',
    'Headwear/Kufi': 'Kufi: brimless cap worn across West Africa.',
    'Headwear/Duku': 'Duku: Akan knotted wrap; fabric signals the event.',
    'Headwear/Isicholo':
        'Isicholo: Zulu flared hat — wear with cultural context.',
    'Top/WovenWrap': 'Woven wrap: strip cloth for celebrations (Akan, Yoruba, Igbo).',
    'Top/Kaftan': 'Kaftan / boubou silhouette for formal gatherings.',
    'Top/Fugu': 'Fugu smock: Dagomba stripes from northern Ghana.',
    'Top/Tee': 'Everyday top — pair with your learning journey colours.',
    'Bottom/Wrapper': 'Wrapper cloth: wrapped skirt style for ceremony.',
    'Bottom/Trousers': 'Trousers for daily lessons and village meetups.',
  };

  static const Map<String, String> masteryByArtboard = {
    'Headwear/Gele': 'mastery:greetings_respect',
    'Headwear/Fila': 'mastery:greetings_respect',
    'Headwear/Kufi': 'mastery:greetings_respect',
    'Headwear/Duku': 'mastery:greetings_respect',
    'Prop/TalkingDrum': 'mastery:tone_checkpoint',
    'Top/Fugu': 'mastery:fugu_cultural_review',
    'Headwear/Isicholo': 'mastery:isicholo_context',
  };

  static String? masteryIdFor(String artboardId) => masteryByArtboard[artboardId];

  static String culturalNoteFor(String artboardId) {
    return culturalNotes[artboardId] ??
        'Styled on the same rig as our cast — wear it with pride.';
  }

  static String displayLabel(String artboardId) {
    final slash = artboardId.indexOf('/');
    if (slash < 0) return artboardId;
    return artboardId.substring(slash + 1).replaceAll(RegExp(r'([a-z])([A-Z])'), r'$1 $2');
  }
}

/// Learner avatar editor on the shared CharacterVM rig (P11-053).
class AvatarEditorScreen extends StatefulWidget {
  const AvatarEditorScreen({
    super.key,
    this.entitlements = const AvatarEditorEntitlements(),
    this.initialAppearance = const AvatarAppearance(skinToneId: 6),
    this.initialParts = const {
      AvatarPartSlots.hair: 'Hair/Afro',
      AvatarPartSlots.headwear: 'Headwear/None',
      AvatarPartSlots.top: 'Top/Tee',
      AvatarPartSlots.bottom: 'Bottom/Trousers',
    },
  });

  final AvatarEditorEntitlements entitlements;
  final AvatarAppearance initialAppearance;
  final Map<String, String> initialParts;

  @override
  State<AvatarEditorScreen> createState() => _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends State<AvatarEditorScreen> {
  late final CastSession _session;
  AvatarPartCatalog? _catalog;
  String _activeSlot = AvatarPartSlots.hair;
  late AvatarAppearance _appearance;
  late Map<String, String> _parts;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _session = CastSession(preset: 'Learner');
    _appearance = widget.initialAppearance;
    _parts = Map<String, String>.from(widget.initialParts);
    _session.addListener(_syncAppearanceToRig);
    _bootstrap();
  }

  void _syncAppearanceToRig() {
    final bound = _session.bound;
    if (bound != null) {
      AvatarColorPalette.bind(bound, _appearance);
    }
  }

  Future<void> _bootstrap() async {
    try {
      final catalog = await CastContract.loadPartCatalog();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _loadError = null;
      });
      _applyToSession();
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  void _applyToSession() {
    for (final entry in _parts.entries) {
      _session.wear(entry.key, entry.value);
    }
    _session.reducedMotion(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
  }

  @override
  void dispose() {
    _session.removeListener(_syncAppearanceToRig);
    _session.dispose();
    super.dispose();
  }

  void _selectPart(String slot, String artboardId) {
    setState(() {
      _parts[slot] = artboardId;
      _activeSlot = slot;
    });
    _session.wear(slot, artboardId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catalog = _catalog;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.avatarEditorTitle),
        centerTitle: true,
      ),
      body: catalog == null
          ? Center(
              child: _loadError != null
                  ? Text(l10n.avatarEditorLoadError)
                  : const CircularProgressIndicator.adaptive(),
            )
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(PanAfricanSpacing.lg),
                  child: PanAfricanCard(
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    child: SizedBox(
                      height: 220,
                      child: CastStage(session: _session),
                    ),
                  ),
                ),
                _SkinToneRow(
                  appearance: _appearance,
                  onSelected: (tone) {
                    setState(() => _appearance = AvatarAppearance(
                          skinToneId: tone.id,
                          hairColorId: _appearance.hairColorId,
                          outfitPrimary: _appearance.outfitPrimary,
                          outfitSecondary: _appearance.outfitSecondary,
                        ));
                    _syncAppearanceToRig();
                  },
                ),
                _SlotTabs(
                  active: _activeSlot,
                  onChanged: (slot) => setState(() => _activeSlot = slot),
                ),
                Expanded(
                  child: AvatarEditorItemGrid(
                    catalog: catalog,
                    slot: _activeSlot,
                    selectedId: _parts[_activeSlot],
                    entitlements: widget.entitlements,
                    onSelect: (id) => _selectPart(_activeSlot, id),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SkinToneRow extends StatelessWidget {
  const _SkinToneRow({required this.appearance, required this.onSelected});

  final AvatarAppearance appearance;
  final ValueChanged<AvatarSkinTone> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.avatarEditorSkinTone,
            style: PanAfricanTypography.labelLarge(context),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AvatarSkinTone.catalog.length,
              separatorBuilder: (_, __) => SizedBox(width: PanAfricanSpacing.sm),
              itemBuilder: (context, index) {
                final tone = AvatarSkinTone.catalog[index];
                final selected = tone.id == appearance.skinToneId;
                return Semantics(
                  label: tone.slug,
                  button: true,
                  selected: selected,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSelected(tone),
                      customBorder: const CircleBorder(),
                      child: Ink(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tone.color,
                          border: Border.all(
                            color: selected
                                ? PanAfricanColors.primary
                                : Theme.of(context).dividerColor,
                            width: selected ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: PanAfricanSpacing.md),
        ],
      ),
    );
  }
}

class _SlotTabs extends StatelessWidget {
  const _SlotTabs({required this.active, required this.onChanged});

  final String active;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = <String, String>{
      AvatarPartSlots.hair: l10n.avatarEditorSlotHair,
      AvatarPartSlots.headwear: l10n.avatarEditorSlotHeadwear,
      AvatarPartSlots.top: l10n.avatarEditorSlotTop,
      AvatarPartSlots.bottom: l10n.avatarEditorSlotBottom,
      AvatarPartSlots.accessory: l10n.avatarEditorSlotAccessory,
      AvatarPartSlots.prop: l10n.avatarEditorSlotProp,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
      child: Row(
        children: AvatarPartSlots.all.map((slot) {
          final selected = slot == active;
          return Padding(
            padding: EdgeInsets.only(right: PanAfricanSpacing.sm),
            child: ChoiceChip(
              label: Text(labels[slot] ?? slot),
              selected: selected,
              onSelected: (_) => onChanged(slot),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Grid of rig parts for one slot — testable / golden target `editor_grid`.
class AvatarEditorItemGrid extends StatelessWidget {
  const AvatarEditorItemGrid({
    super.key,
    required this.catalog,
    required this.slot,
    required this.selectedId,
    required this.entitlements,
    required this.onSelect,
  });

  final AvatarPartCatalog catalog;
  final String slot;
  final String? selectedId;
  final AvatarEditorEntitlements entitlements;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final def = catalog.slot(slot);
    return GridView.builder(
      key: const ValueKey('editor_grid'),
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: PanAfricanSpacing.md,
        crossAxisSpacing: PanAfricanSpacing.md,
        childAspectRatio: 0.82,
      ),
      itemCount: def.allOptions.length,
      itemBuilder: (context, index) {
        final artboardId = def.allOptions[index];
        final unlocked = entitlements.isUnlocked(
          slot: def,
          artboardId: artboardId,
        );
        final selected = artboardId == selectedId;
        return AvatarEditorItemTile(
          label: AvatarEditorCatalog.displayLabel(artboardId),
          culturalNote: AvatarEditorCatalog.culturalNoteFor(artboardId),
          locked: !unlocked,
          selected: selected,
          lockReason: unlocked
              ? null
              : entitlements.lockReason(context, artboardId),
          onTap: () {
            if (!unlocked) {
              _showLockedSheet(context, artboardId);
              return;
            }
            onSelect(artboardId);
          },
        );
      },
    );
  }

  void _showLockedSheet(BuildContext context, String artboardId) {
    final l10n = AppLocalizations.of(context)!;
    final reason = entitlements.lockReason(context, artboardId);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.avatarItemLockedTitle,
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              l10n.avatarItemLocked(reason),
              style: PanAfricanTypography.bodyMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              l10n.avatarItemNote(AvatarEditorCatalog.culturalNoteFor(artboardId)),
              style: PanAfricanTypography.bodySmall(context),
            ),
          ],
        ),
      ),
    );
  }
}

class AvatarEditorItemTile extends StatelessWidget {
  const AvatarEditorItemTile({
    super.key,
    required this.label,
    required this.culturalNote,
    required this.locked,
    required this.selected,
    required this.onTap,
    this.lockReason,
  });

  final String label;
  final String culturalNote;
  final bool locked;
  final bool selected;
  final String? lockReason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight;

    return Semantics(
      label: locked
          ? '${l10n.avatarItemLocked(lockReason ?? '')}. $label. $culturalNote'
          : '$label. ${l10n.avatarItemNote(culturalNote)}',
      button: true,
      enabled: !locked,
      selected: selected,
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PanAfricanRadius.md),
              border: Border.all(
                color: selected
                    ? PanAfricanColors.primary
                    : Theme.of(context).dividerColor.withValues(alpha: 0.4),
                width: selected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: locked
                          ? Icon(
                              Icons.lock_rounded,
                              size: 28,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            )
                          : const Icon(
                              Icons.checkroom_outlined,
                              size: 28,
                              color: PanAfricanColors.primary,
                            ),
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PanAfricanTypography.labelMedium(context),
                  ),
                  Flexible(
                    child: Text(
                      culturalNote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PanAfricanTypography.bodySmall(context).copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
