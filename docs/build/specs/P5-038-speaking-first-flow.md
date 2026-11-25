charter: v2

# P5-038 — Speaking-first flow with recasts (not text-heavy)

ELEVATION §6.2 requires speaking from session 1, negotiated meaning with Polie, and recasts rather than red marks. Reading-heavy screens are out of scope for A1 session shells.

## Session 1 speak-first (AC1)

The first learner session opens with a production step before passive reading.

```text
firstInteractionForSession(1) -> speak
sessionOneSpeakingFirstPlan -> [speak, listen, choose, speak]
sessionOneStartsWithSpeak(plannedSteps) -> bool
```

## Polie recasts (AC2)

On learner error, Polie uses [PolieCorrectionStyle.recast] only. Rule dumps and explicit red-mark copy are rejected.

```text
polieErrorStyleAllowed(style) -> style == recast
looksLikeGrammarRuleDump(reply) -> bool
isRecastReply(reply, targetLanguageExcerpt) -> bool
```

Recasts embed a correct target-language excerpt and avoid grammar-lecture fragments.

## Text budgets (AC3)

Lesson chrome stays within `SpeakingScreenTextBudget` (default 18 instruction words, 42 body words, 55 total).

```text
screenIsTextHeavy(instructionText, bodyText, budget) -> bool
```

`orderSpeakingBeforeReading` keeps the first speak beat before `readPassage` when planners reorder steps.
