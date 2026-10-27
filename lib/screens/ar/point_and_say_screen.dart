import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/lens/lens_screen.dart';
import 'package:lingafriq/services/lens/on_device_object_classifier.dart';
import 'package:lingafriq/services/lens/point_say_dictionary.dart';

/// Shared on-device classifier for Point and Say (P7-945).
OnDeviceObjectClassifier createPointSayObjectClassifier() =>
    OnDeviceObjectClassifier();

/// Legacy route `point-and-say` with dictionary mapping on tap (P7-946).
class PointAndSayScreen extends ConsumerStatefulWidget {
  const PointAndSayScreen({super.key, required this.language});

  final String language;

  @override
  ConsumerState<PointAndSayScreen> createState() => _PointAndSayScreenState();
}

class _PointAndSayScreenState extends ConsumerState<PointAndSayScreen> {
  PointSayDictionaryService? _dictionaryService;

  @override
  void initState() {
    super.initState();
    createPointSayDictionaryService().then((service) {
      if (mounted) setState(() => _dictionaryService = service);
    });
  }

  Future<void> _onLabelTap(String mlKitLabel) async {
    final service = _dictionaryService;
    if (service == null) return;
    final profile = ref.read(userProvider);
    final userId = profile != null ? '${profile.id}' : 'local';

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => PointSayDictionarySheet(
        service: service,
        mlKitLabel: mlKitLabel,
        learnerLanguageCode: widget.language,
        userId: userId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LensScreen(
      fallbackLanguage: widget.language,
      onDetectionLabelTap: _dictionaryService == null ? null : _onLabelTap,
    );
  }
}
