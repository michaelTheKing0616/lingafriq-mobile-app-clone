import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/avatars/avatars.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/profile/global_handle_edit_screen.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_tab.dart'
    show ProfileImageBuilder;
import 'package:lingafriq/widgets/points_and_profile_image_builder.dart'
    show kHeaderAvatarDisc;
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart'
    show ageTierStatusProvider;
import 'package:lingafriq/services/account_service.dart';
import 'package:lingafriq/utils/constants.dart';

import '../../../widgets/delete_account_dialogue.dart';

/// Sends a profile update; returns false on failure. Swappable in tests.
final profileSaveProvider =
    Provider<Future<bool> Function(Map<String, dynamic>)>(
      (ref) => ref.read(apiProvider.notifier).updateProfile,
    );

/// Deletes the account with [password]; returns the server message.
final profileDeleteProvider =
    Provider<Future<String> Function(WidgetRef, String)>(
      (ref) =>
          (widgetRef, password) =>
              AccountService(widgetRef).deleteAccount(password),
    );

const _navy = Color(0xFF2E3A87);
const _ink = Color(0xFF1F2340);
const _muted = Color(0xFF5B607A);
const _line = Color(0xFFE3E5EF);
const _soft = Color(0xFFF4F5FA);
const _danger = Color(0xFFB3261E);

String _iso(BuildContext c, String s) =>
    Directionality.of(c) == TextDirection.rtl ? '\u2066$s\u2069' : s;

/// Edit profile (profile-progress/09 avatar card + Duolingo profile form):
/// avatar hero with edit pen, name fields with inline validation, handle
/// row (opens the handle editor that really saves it), locked country,
/// sticky save, and a separated delete-account zone.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  bool _seeded = false;
  bool _saving = false;
  bool _failed = false;
  bool _tried = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  void _seed(ProfileModel u) {
    if (_seeded) return;
    _seeded = true;
    _first.text = u.first_name;
    _last.text = u.last_name;
  }

  bool _dirty(ProfileModel u) =>
      _first.text.trim() != u.first_name || _last.text.trim() != u.last_name;

  Future<void> _save(ProfileModel u) async {
    setState(() => _tried = true);
    if (_first.text.trim().isEmpty || _last.text.trim().isEmpty) return;
    final l = l10nOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() {
      _saving = true;
      _failed = false;
    });
    final ok = await ref.read(profileSaveProvider)(
      u
          .copyWith(
            first_name: _first.text.trim(),
            last_name: _last.text.trim(),
          )
          .toMap(),
    );
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _saving = false;
        _failed = true;
      });
      return;
    }
    await ref.read(userProvider.notifier).refreshUser();
    if (!mounted) return;
    HapticFeedback.lightImpact();
    messenger.showSnackBar(SnackBar(content: Text(l.peSaved)));
    nav.pop();
  }

  Future<void> _delete() async {
    final l = l10nOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final confirm = await DeleteAccountDialog.showDeleteAccountDialog(context);
    if (confirm != true || !mounted) return;
    final password = await EnterPasswordDialog.show(context);
    if (password == null || password.isEmpty) return;
    try {
      final msg = await ref.read(profileDeleteProvider)(ref, password);
      messenger.showSnackBar(SnackBar(content: Text(msg)));
      await ref.read(authProvider.notifier).signOut(deleteAccount: true);
      nav.popUntil((r) => r.isFirst);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.peDeleteError)));
    }
  }

  void _editAvatar() {
    final config = ref.read(userAvatarConfigProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scroll) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scroll,
            child: Column(
              children: [
                const SizedBox(height: 560, child: CastBuilder()),
                UserAvatarCustomizer(
                  initialConfig: config,
                  onConfigChanged: (c) =>
                      ref.read(userAvatarConfigProvider.notifier).setConfig(c),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final u = ref.watch(userProvider);
    final tier = ref.watch(ageTierStatusProvider).value?.tier?.toLowerCase();
    final minor = tier == 'child' || tier == 'teen';

    final big = MediaQuery.textScalerOf(context).scale(10) > 15;
    final appBar = AppBar(
      toolbarHeight: big ? 88 : null,
      backgroundColor: Colors.white,
      foregroundColor: _ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        key: const Key('pe-back'),
        tooltip: l.peBack,
        icon: const BackButtonIcon(),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        l.peTitle,
        maxLines: 2,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );

    if (u == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: appBar,
        body: Semantics(
          key: const Key('pe-loading'),
          label: l.peLoading,
          liveRegion: true,
          child: ExcludeSemantics(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: _soft,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                for (var i = 0; i < 4; i++)
                  Container(
                    height: 56,
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: _soft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    _seed(u);
    final flag = kCountries[u.nationality] ?? '';
    final handle = u.global_id?.replaceFirst('@', '');
    String? req(TextEditingController c, String f) =>
        _tried && c.text.trim().isEmpty ? l.peRequired(f.toLowerCase()) : null;
    final canSave = !_saving && _dirty(u);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar,
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _line)),
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: FilledButton(
                key: const Key('pe-save'),
                style: FilledButton.styleFrom(
                  backgroundColor: _navy,
                  disabledBackgroundColor: _line,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: canSave ? () => _save(u) : null,
                child: Text(
                  _saving ? l.peSaving : l.peSave,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            key: const Key('pe-list'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Container(
                key: const Key('pe-avatar-card'),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Semantics(
                          button: true,
                          label: l.peAvatarEdit,
                          excludeSemantics: true,
                          // Same persona art as the profile header.
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kHeaderAvatarDisc,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const ProfileImageBuilder(
                              size: Size(112, 112),
                              showEditIcon: false,
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          end: -6,
                          bottom: -6,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: IconButton(
                              key: const Key('pe-avatar-edit'),
                              tooltip: l.peAvatarEdit,
                              icon: const Icon(
                                Icons.edit_rounded,
                                color: _navy,
                              ),
                              onPressed: _editAvatar,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _iso(context, u.username),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.peAvatarHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFD9DCF2),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (_failed)
                Container(
                  key: const Key('pe-error'),
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: _danger),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.peSaveError,
                          style: const TextStyle(color: _ink),
                        ),
                      ),
                    ],
                  ),
                ),
              _Header(l.peAbout),
              _Field(
                fieldKey: const Key('pe-first'),
                controller: _first,
                label: l.peFirst,
                error: req(_first, l.peFirst),
                enabled: !_saving,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 12),
              _Field(
                fieldKey: const Key('pe-last'),
                controller: _last,
                label: l.peLast,
                error: req(_last, l.peLast),
                enabled: !_saving,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 12),
              _Row(
                rowKey: const Key('pe-handle'),
                icon: Icons.alternate_email_rounded,
                label: l.peHandle,
                value: handle == null || handle.isEmpty
                    ? l.peHandleNone
                    : _iso(context, '@$handle'),
                action: l.peHandleEdit,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        GlobalHandleEditScreen(currentGlobalId: handle),
                  ),
                ),
              ),
              if (minor)
                Padding(
                  key: const Key('pe-minor-tip'),
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_rounded, size: 18, color: _navy),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.peMinorTip,
                          style: const TextStyle(color: _ink, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              _Row(
                rowKey: const Key('pe-email'),
                icon: Icons.mail_outline_rounded,
                label: l.peEmail,
                value: _iso(context, u.email),
              ),
              const SizedBox(height: 12),
              _Row(
                rowKey: const Key('pe-country'),
                icon: Icons.lock_outline_rounded,
                label: l.peCountry,
                value: '$flag ${u.nationality}'.trim(),
                note: l.peCountryLocked,
              ),
              _Header(l.peDanger),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _line, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.peDeleteSub,
                      style: const TextStyle(color: _muted, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      key: const Key('pe-delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _danger,
                        side: const BorderSide(color: _danger, width: 1.5),
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: _saving ? null : _delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(l.peDelete),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: _ink,
        ),
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.error,
    required this.enabled,
    required this.onChanged,
  });
  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String? error;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    key: fieldKey,
    controller: controller,
    enabled: enabled,
    textInputAction: TextInputAction.next,
    textCapitalization: TextCapitalization.words,
    onChanged: (_) => onChanged(),
    decoration: InputDecoration(
      labelText: label,
      errorText: error,
      filled: true,
      fillColor: _soft,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _navy, width: 2),
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.rowKey,
    required this.icon,
    required this.label,
    required this.value,
    this.note,
    this.action,
    this.onTap,
  });
  final Key rowKey;
  final IconData icon;
  final String label, value;
  final String? note, action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    key: rowKey,
    color: _soft,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: _navy),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 13, color: _muted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      note!,
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Semantics(
                label: action,
                child: const Icon(Icons.chevron_right_rounded, color: _muted),
              ),
          ],
        ),
      ),
    ),
  );
}
