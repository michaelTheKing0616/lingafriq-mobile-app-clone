import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lingafriq/providers/wa_status_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class WaStatusCreateScreen extends ConsumerStatefulWidget {
  const WaStatusCreateScreen({super.key});

  @override
  ConsumerState<WaStatusCreateScreen> createState() =>
      _WaStatusCreateScreenState();
}

class _WaStatusCreateScreenState extends ConsumerState<WaStatusCreateScreen> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  bool _submitting = false;
  File? _mediaFile;
  String? _mediaKind;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final x = await _picker.pickImage(source: source, maxWidth: 1920, imageQuality: 85);
      if (x == null) return;
      setState(() {
        _mediaFile = File(x.path);
        _mediaKind = 'image';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final x = await _picker.pickVideo(source: ImageSource.gallery);
      if (x == null) return;
      setState(() {
        _mediaFile = File(x.path);
        _mediaKind = 'video';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick video: $e')),
      );
    }
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add text or choose a photo or video.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final notifier = ref.read(waStatusProvider.notifier);
    bool ok;
    if (_mediaFile != null && _mediaKind != null) {
      ok = await notifier.createStatusFromLocalFile(
        _mediaFile!,
        mediaKind: _mediaKind!,
        caption: text.isEmpty ? null : text,
      );
    } else {
      ok = await notifier.createStatus(
        mediaType: 'text',
        text: text,
      );
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Status posted' : (ref.read(waStatusProvider).errorMessage ?? 'Could not post status'))),
    );
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? PanAfricanGradients.darkSurface : PanAfricanGradients.savannaGold,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Create status',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Photo, video, or text',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _submitting ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _submitting ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _submitting ? null : _pickVideo,
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Video'),
                  ),
                ],
              ),
              if (_mediaFile != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InputChip(
                    label: Text(_mediaKind == 'video' ? 'Video attached' : 'Image attached'),
                    onDeleted: _submitting
                        ? null
                        : () => setState(() {
                              _mediaFile = null;
                              _mediaKind = null;
                            }),
                  ),
                ),
                if (_mediaKind == 'image')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _mediaFile!,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Caption (optional if you add media)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _textController,
                      maxLines: 6,
                      maxLength: 300,
                      decoration: InputDecoration(
                        hintText: 'Share a phrase, progress win, or describe your clip...',
                        filled: true,
                        fillColor: isDark
                            ? PanAfricanColors.surfaceContainerHighDark
                            : PanAfricanColors.surfaceContainerLowLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Auto-expires in 24 hours',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_submitting ? 'Posting...' : 'Post status'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
