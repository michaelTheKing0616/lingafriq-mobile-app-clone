import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/snap_provider.dart';
import 'package:lingafriq/screens/snap/ui/snap_theme.dart';

enum _CaptureMode { camera, preview }

class SnapCameraScreen extends ConsumerStatefulWidget {
  const SnapCameraScreen({super.key});

  @override
  ConsumerState<SnapCameraScreen> createState() => _SnapCameraScreenState();
}

class _SnapCameraScreenState extends ConsumerState<SnapCameraScreen> {
  final _recipientController = TextEditingController();
  final _mediaUrlController = TextEditingController(text: 'https://example.com/snap.jpg');
  final _captionController = TextEditingController();
  _CaptureMode _mode = _CaptureMode.camera;
  bool _sending = false;

  @override
  void dispose() {
    _recipientController.dispose();
    _mediaUrlController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _sendSnap() async {
    final recipient = _recipientController.text.trim();
    final mediaUrl = _mediaUrlController.text.trim();
    if (recipient.isEmpty || mediaUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add recipient and media URL')));
      return;
    }

    setState(() => _sending = true);
    final ok = await ref.read(snapProvider.notifier).sendSnap(
          recipientId: recipient,
          mediaUrl: mediaUrl,
          caption: _captionController.text.trim().isEmpty ? null : _captionController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Snap sent' : 'Could not send snap')));
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Camera'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.flip_camera_ios_outlined)),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, SnapUi.accent().withValues(alpha: 0.3), Colors.black],
                ),
              ),
              child: Center(
                child: Icon(
                  _mode == _CaptureMode.camera ? Icons.camera_alt_rounded : Icons.image_outlined,
                  color: Colors.white70,
                  size: 72,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              color: Colors.black.withValues(alpha: 0.45),
              child: Column(
                children: [
                  if (_mode == _CaptureMode.preview) ...[
                    TextField(
                      controller: _recipientController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Send to (user id)',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.person_outline, color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _mediaUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Media URL',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.link_rounded, color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _captionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Caption (optional)',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.edit_note_rounded, color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _mode = _mode == _CaptureMode.camera ? _CaptureMode.preview : _CaptureMode.camera;
                          });
                        },
                        child: Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _mode == _CaptureMode.camera ? Colors.white : SnapUi.accent(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: (_mode == _CaptureMode.preview && !_sending) ? _sendSnap : null,
                        style: FilledButton.styleFrom(backgroundColor: SnapUi.accent()),
                        child: Text(_sending ? 'Sending...' : 'Send'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
