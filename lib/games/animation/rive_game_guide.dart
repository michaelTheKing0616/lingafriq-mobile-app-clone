import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'rive_asset_loader.dart';

/// Rive character guide controller
/// Controls the animated guide character that appears in all games
class RiveGameGuideController {
  Artboard? _artboard;
  SMIBool? _isListening;
  SMIBool? _isSpeaking;
  SMINumber? _confidence;
  SMINumber? _emotion;

  /// Initialize the Rive controller with the artboard
  void initialize(Artboard artboard) {
    _artboard = artboard;
    
    // Find state machine inputs
    final stateMachine = _artboard!.stateMachines.firstOrNull;
    if (stateMachine != null) {
      for (final input in stateMachine.inputs) {
        if (input.name == 'isListening') {
          _isListening = input as SMIBool;
        } else if (input.name == 'isSpeaking') {
          _isSpeaking = input as SMIBool;
        } else if (input.name == 'confidence') {
          _confidence = input as SMINumber;
        } else if (input.name == 'emotion') {
          _emotion = input as SMINumber;
        }
      }
    }
  }

  /// Set listening state
  void setListening(bool listening) {
    _isListening?.value = listening;
  }

  /// Set speaking state
  void setSpeaking(bool speaking) {
    _isSpeaking?.value = speaking;
  }

  /// Set confidence level (0.0 to 1.0)
  void setConfidence(double confidence) {
    _confidence?.value = confidence.clamp(0.0, 1.0);
  }

  /// Set emotion
  void setEmotion(GuideEmotion emotion) {
    _emotion?.value = emotion.index.toDouble();
  }

  /// Celebrate success
  void celebrate() {
    setEmotion(GuideEmotion.proud);
    setConfidence(1.0);
    // Trigger celebration animation if available
  }

  /// Show failure
  void fail() {
    setEmotion(GuideEmotion.disappointed);
    setConfidence(0.0);
  }

  /// Get the artboard for rendering
  Artboard? get artboard => _artboard;
}

/// Guide emotion enum
enum GuideEmotion {
  idle,
  thinking,
  encouraging,
  proud,
  disappointed,
  happy, // Added for positive reactions
}

/// Rive game guide widget
class RiveGameGuide extends StatefulWidget {
  final RiveGameGuideController controller;
  final double? width;
  final double? height;

  const RiveGameGuide({
    super.key,
    required this.controller,
    this.width,
    this.height,
  });

  @override
  State<RiveGameGuide> createState() => _RiveGameGuideState();
}

class _RiveGameGuideState extends State<RiveGameGuide> {
  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }

  Future<void> _loadRiveFile() async {
    await RiveAssetLoader.loadRiveAsset(widget.controller);
  }

  @override
  Widget build(BuildContext context) {
    final artboard = widget.controller.artboard;
    
    if (artboard == null) {
      // Fallback to simple icon if Rive not available
      return SizedBox(
        width: widget.width ?? 100,
        height: widget.height ?? 100,
        child: Icon(
          Icons.face,
          size: widget.width ?? 100,
          color: Colors.blue,
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Rive(
        artboard: artboard,
        fit: BoxFit.contain,
      ),
    );
  }
}

