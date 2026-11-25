import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../services/quiz/diacritic_grader.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/diacritic_keyboard_bar.dart';
import '../../widgets/lingafriq_keyboard_bar.dart';
import '../../widgets/pan_african_components.dart';

/// Copy key: `tutorial.kbd.try`
const String kTutorialKbdTry =
    'Tap a key on the LingAfriq bar, then check your answer.';

class KeyboardBarTutorialPrompt {
  const KeyboardBarTutorialPrompt({
    required this.introTitle,
    required this.introBody,
    required this.target,
    required this.mismatchHint,
    required this.successBody,
  });

  final String introTitle;
  final String introBody;
  final String target;
  final String mismatchHint;
  final String successBody;
}

KeyboardBarTutorialPrompt keyboardBarPromptForLanguage(String languageId) {
  switch (languageId.trim().toLowerCase()) {
    case 'yo':
      return const KeyboardBarTutorialPrompt(
        introTitle: 'Type Yoruba letters',
        introBody:
            'Yoruba uses ẹ, ọ, and ṣ on the bar above your keyboard — the same keys you will see in lessons.',
        target: 'ẹ',
        mismatchHint:
            'That is not ẹ. Tap ẹ on the bar (open e with a dot below), then check again.',
        successBody: 'Nicely done — you typed ẹ with the LingAfriq bar.',
      );
    case 'ig':
      return const KeyboardBarTutorialPrompt(
        introTitle: 'Type Igbo letters',
        introBody:
            'Igbo uses dotted vowels like ị and ọ on the diacritic bar. Tone marks come next in other drills.',
        target: 'ị',
        mismatchHint:
            'That is not ị. Choose ị on the bar (dotted i), then check again.',
        successBody: 'Great — ị is on the bar whenever you need it.',
      );
    case 'ha':
      return const KeyboardBarTutorialPrompt(
        introTitle: 'Type Hausa hooked letters',
        introBody:
            'Hausa Boko uses ɓ, ɗ, and ƙ on the bar. They are different consonants, not optional styling.',
        target: 'ɓ',
        mismatchHint:
            'That is not ɓ. Tap ɓ on the bar (hooked b), then check again.',
        successBody: 'You typed ɓ — keep using the bar for hooked letters.',
      );
    case 'tw':
      return const KeyboardBarTutorialPrompt(
        introTitle: 'Type Akan letters',
        introBody:
            'Twi uses ɛ and ɔ on the bar. Pick the letter that matches the prompt.',
        target: 'ɛ',
        mismatchHint:
            'That is not ɛ. Tap ɛ on the bar, then check again.',
        successBody: 'ɛ looks right — the bar stays with your keyboard.',
      );
    default:
      return const KeyboardBarTutorialPrompt(
        introTitle: 'Diacritic keyboard',
        introBody:
            'This language does not have a diacritic layout yet. Try Yoruba, Igbo, Hausa, or Twi from settings.',
        target: '',
        mismatchHint: 'No layout for this language.',
        successBody: '',
      );
  }
}

enum KeyboardBarTutorialPhase {
  loading,
  error,
  offline,
  intro,
  typing,
  correct,
  incorrect,
}

bool keyboardBarCharacterMatches(String typed, String target) {
  final got = nfc(typed.trim());
  final expected = nfc(target.trim());
  return got.isNotEmpty && got == expected;
}

class KeyboardBarTutorialScreen extends StatefulWidget {
  const KeyboardBarTutorialScreen({
    super.key,
    required this.languageId,
    this.layouts,
    this.layoutsLoader,
    this.isOffline = false,
    this.prompt,
  });

  final String languageId;
  final DiacriticKeyboardLayouts? layouts;
  final Future<DiacriticKeyboardLayouts> Function()? layoutsLoader;
  final bool isOffline;
  final KeyboardBarTutorialPrompt? prompt;

  @override
  State<KeyboardBarTutorialScreen> createState() =>
      _KeyboardBarTutorialScreenState();
}

class _KeyboardBarTutorialScreenState extends State<KeyboardBarTutorialScreen> {
  KeyboardBarTutorialPhase _phase = KeyboardBarTutorialPhase.loading;
  DiacriticKeyboardLayouts? _layouts;
  String? _loadError;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late KeyboardBarTutorialPrompt _prompt;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _prompt = widget.prompt ?? keyboardBarPromptForLanguage(widget.languageId);
    _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (widget.isOffline) {
      setState(() => _phase = KeyboardBarTutorialPhase.offline);
      return;
    }
    try {
      final layouts = widget.layouts ??
          await (widget.layoutsLoader ?? DiacriticKeyboardLayouts.loadFromAsset)();
      if (!mounted) return;
      _layouts = layouts;
      if (layouts.forLanguage(widget.languageId) == null ||
          _prompt.target.isEmpty) {
        setState(() {
          _phase = KeyboardBarTutorialPhase.error;
          _loadError = 'No diacritic keyboard for this language yet.';
        });
        return;
      }
      setState(() => _phase = KeyboardBarTutorialPhase.intro);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = KeyboardBarTutorialPhase.error;
        _loadError = 'Could not load keyboard layouts.';
      });
    }
  }

  void _startTyping() {
    setState(() {
      _phase = KeyboardBarTutorialPhase.typing;
      _controller.clear();
    });
    _focusNode.requestFocus();
    SemanticsService.announce(kTutorialKbdTry, TextDirection.ltr);
  }

  void _checkAnswer() {
    if (keyboardBarCharacterMatches(_controller.text, _prompt.target)) {
      setState(() => _phase = KeyboardBarTutorialPhase.correct);
      SemanticsService.announce(_prompt.successBody, TextDirection.ltr);
      return;
    }
    setState(() => _phase = KeyboardBarTutorialPhase.incorrect);
    SemanticsService.announce(_prompt.mismatchHint, TextDirection.ltr);
  }

  void _retry() {
    _controller.clear();
    setState(() => _phase = KeyboardBarTutorialPhase.typing);
    _focusNode.requestFocus();
  }

  Duration _motionDuration(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return reduce ? Duration.zero : const Duration(milliseconds: 220);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: ValueKey('keyboard-bar-tutorial-${_phase.name}'),
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(_prompt.introTitle),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_phase) {
      case KeyboardBarTutorialPhase.loading:
        return const Center(
          key: ValueKey('kbd-tutorial-loading'),
          child: CircularProgressIndicator(),
        );
      case KeyboardBarTutorialPhase.offline:
        return _messagePanel(
          key: const ValueKey('kbd-tutorial-offline'),
          title: 'You are offline',
          body:
              'Reconnect to load the keyboard tutorial. Your lesson progress is safe.',
          actionLabel: 'Try again',
          onAction: () {
            if (!widget.isOffline) _bootstrap();
          },
        );
      case KeyboardBarTutorialPhase.error:
        return _messagePanel(
          key: const ValueKey('kbd-tutorial-error'),
          title: 'Tutorial unavailable',
          body: _loadError ?? 'Something went wrong.',
          actionLabel: 'Try again',
          onAction: _bootstrap,
        );
      case KeyboardBarTutorialPhase.intro:
        return _introPanel(context);
      case KeyboardBarTutorialPhase.typing:
      case KeyboardBarTutorialPhase.incorrect:
        return _typingPanel(context);
      case KeyboardBarTutorialPhase.correct:
        return _correctPanel(context);
    }
  }

  Widget _introPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      key: const ValueKey('kbd-tutorial-intro'),
      children: [
        Text(
          _prompt.introBody,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        SizedBox(height: 24.h),
        PanAfricanButton(
          label: 'Start typing',
          onPressed: _startTyping,
          width: double.infinity,
        ),
      ],
    );
  }

  Widget _typingPanel(BuildContext context) {
    final layouts = _layouts!;
    final showMismatch = _phase == KeyboardBarTutorialPhase.incorrect;
    final duration = _motionDuration(context);

    return SingleChildScrollView(
      key: const ValueKey('kbd-tutorial-typing'),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          kTutorialKbdTry,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: PanAfricanColors.primary,
              ),
        ),
        SizedBox(height: 12.h),
        Text(
          'Type this letter:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: 8.h),
        Text(
          _prompt.target,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          semanticsLabel: 'Target letter ${_prompt.target}',
        ),
        SizedBox(height: 20.h),
        Semantics(
          label: 'Your answer',
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            readOnly: false,
            decoration: InputDecoration(
              hintText: 'Your letter',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              errorText: showMismatch ? _prompt.mismatchHint : null,
            ),
            onSubmitted: (_) => _checkAnswer(),
          ),
        ),
        SizedBox(height: 8.h),
        LingAfriqKeyboardBar(
          languageId: widget.languageId,
          focusNode: _focusNode,
          controller: _controller,
          layouts: layouts,
        ),
        if (showMismatch) ...[
          SizedBox(height: 12.h),
          Text(
            _prompt.mismatchHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
          SizedBox(height: 12.h),
          PanAfricanButton(
            label: 'Try again',
            onPressed: _retry,
            isOutlined: true,
            width: double.infinity,
          ),
        ],
        SizedBox(height: 16.h),
        PanAfricanButton(
          label: 'Check',
          onPressed: _checkAnswer,
          width: double.infinity,
        ),
      ],
      ),
    ).animate().fadeIn(duration: duration);
  }

  Widget _correctPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      key: const ValueKey('kbd-tutorial-correct'),
      children: [
        Icon(Icons.check_circle, color: PanAfricanColors.primary, size: 56.sp),
        SizedBox(height: 16.h),
        Text(
          _prompt.successBody,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 24.h),
        PanAfricanButton(
          label: 'Done',
          onPressed: () => Navigator.maybePop(context),
          width: double.infinity,
        ),
      ],
    );
  }

  Widget _messagePanel({
    required Key key,
    required String title,
    required String body,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 12.h),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
        SizedBox(height: 24.h),
        PanAfricanButton(
          label: actionLabel,
          onPressed: onAction,
          width: double.infinity,
        ),
      ],
    );
  }

}
