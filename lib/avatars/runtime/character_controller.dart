import 'package:rive/rive.dart';

import 'rive_file_cache.dart';

/// One [RiveWidgetController] for a single on-screen character. Call [dispose]
/// when the widget leaves the tree; pause via [active] when offscreen.
class CharacterController {
  CharacterController({
    required this.assetPath,
    required this.artboard,
    this.stateMachine = 'CharacterSM',
    required this.viewModelName,
  });

  final String assetPath;
  final String artboard;
  final String stateMachine;
  final String viewModelName;

  RiveWidgetController? _controller;
  ViewModelInstance? _viewModel;

  RiveWidgetController get controller {
    final value = _controller;
    if (value == null) {
      throw StateError('CharacterController not attached');
    }
    return value;
  }

  ViewModelInstance? get viewModel => _viewModel;

  bool get isAttached => _controller != null;

  bool get active => _controller?.active ?? false;

  set active(bool value) {
    final current = _controller;
    if (current != null && current.active != value) {
      current.active = value;
    }
  }

  Future<void> attach() async {
    if (_controller != null) return;
    final file = await RiveFileCache.instance.load(assetPath);
    final controller = RiveWidgetController(
      file,
      artboardSelector: ArtboardSelector.byName(artboard),
      stateMachineSelector: StateMachineSelector.byName(stateMachine),
    );
    final instance = controller.dataBind(DataBind.byName(viewModelName));
    _controller = controller;
    _viewModel = instance;
  }

  void dispose() {
    _viewModel?.dispose();
    _viewModel = null;
    _controller?.dispose();
    _controller = null;
  }
}
