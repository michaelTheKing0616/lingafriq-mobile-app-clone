charter: v2

# P2-021 — On-device tone feedback hook

Offline speaking practice can ask a distilled tone model for feedback. The model is a later milestone. This spec is the hook. It does not score speech.

## Interface

The app calls one method. The method returns either a scored result or an unavailable state. It never returns both.

```text
evaluate(reference, audioPath, language) -> ToneFeedback

ToneFeedback
  state: available | unavailable
  score: number, only when state is available
  reason: string, only when state is unavailable
```

`reference` is the expected phrase. `audioPath` is the local recording. `language` is the language code. The caller does not pass a score.

## Model size budget

The distilled model package, including its weights, stays at or under 20 MB. That sits beside a unit pack without taking the unit's 10–30 MB audio budget. A package over 20 MB is not installed.

## Accuracy floor

A result may be shown only after the model reaches the signed tone floor: at least 90 percent native-judged accuracy on a 100-item set for that language (D13). Until that floor is met for the language, `evaluate` returns unavailable. The on-device hook does not invent a lower bar.

## Offline fallback

When the device is offline and the distilled model is not installed, or the installed model has not met the floor, the state is unavailable. The screen reads that tone feedback is unavailable. It shows no score, no guessed number, and no device-voice stand-in.

The real server scorer is not available for this hook yet. Offline practice does not call it and does not substitute a heuristic. The unavailable state is the result.

## Licence

The distilled model must be on a commercial licence. A research-only or non-commercial weight file is not a candidate. No model is selected in this spec.
