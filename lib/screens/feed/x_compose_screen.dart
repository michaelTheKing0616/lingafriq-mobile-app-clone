import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/x_feed_provider.dart';
import 'package:lingafriq/screens/feed/ui/x_theme.dart';

class XComposeScreen extends ConsumerStatefulWidget {
  const XComposeScreen({super.key});

  @override
  ConsumerState<XComposeScreen> createState() => _XComposeScreenState();
}

class _XComposeScreenState extends ConsumerState<XComposeScreen> {
  final _controller = TextEditingController();
  bool _posting = false;
  String _type = 'text';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remaining = 280 - _controller.text.characters.length;

    return Scaffold(
      backgroundColor: XUi.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: XUi.scaffoldBg(isDark),
        title: const Text('Compose'),
        actions: [
          TextButton(
            onPressed: (_posting || _controller.text.trim().isEmpty || remaining < 0)
                ? null
                : () async {
                    setState(() => _posting = true);
                    final ok = await ref.read(xFeedProvider.notifier).composePost(
                          content: _controller.text.trim(),
                          type: _type,
                        );
                    if (!mounted) return;
                    setState(() => _posting = false);
                    if (ok) {
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not post')));
                    }
                  },
            child: _posting ? const Text('Posting...') : const Text('Post'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'text', label: Text('Text')),
              ButtonSegment(value: 'phrase', label: Text('Phrase')),
              ButtonSegment(value: 'poll', label: Text('Poll')),
              ButtonSegment(value: 'quiz', label: Text('Quiz')),
            ],
            selected: {_type},
            onSelectionChanged: (value) => setState(() => _type = value.first),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: XUi.cardBg(isDark),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: XUi.divider(isDark)),
            ),
            child: TextField(
              controller: _controller,
              maxLines: 10,
              maxLength: 280,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Share a phrase, cultural insight, or language tip...',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.image_outlined),
              const SizedBox(width: 10),
              const Icon(Icons.poll_outlined),
              const SizedBox(width: 10),
              const Icon(Icons.language_outlined),
              const Spacer(),
              Text(
                '$remaining',
                style: TextStyle(
                  color: remaining < 0 ? Colors.red : XUi.secondaryText(isDark),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
