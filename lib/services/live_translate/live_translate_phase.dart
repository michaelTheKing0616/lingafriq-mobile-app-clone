/// Mirrors backend `stateMachine.ts` — client UX phases for live translate.
enum LiveTranslatePhase {
  idle,
  creatingSession,
  connectingSocket,
  ready,
  listening,
  playingTts,
  reconnecting,
  error,
}

extension LiveTranslatePhaseLabel on LiveTranslatePhase {
  String get label {
    switch (this) {
      case LiveTranslatePhase.idle:
        return 'Idle';
      case LiveTranslatePhase.creatingSession:
        return 'Creating session…';
      case LiveTranslatePhase.connectingSocket:
        return 'Connecting…';
      case LiveTranslatePhase.ready:
        return 'Ready';
      case LiveTranslatePhase.listening:
        return 'Listening';
      case LiveTranslatePhase.playingTts:
        return 'Playing translation';
      case LiveTranslatePhase.reconnecting:
        return 'Reconnecting…';
      case LiveTranslatePhase.error:
        return 'Error';
    }
  }
}
