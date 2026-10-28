#!/usr/bin/env python3
"""One-off generator for P12-005 build_host handler extensions."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
text = Path("/tmp/bh_orig.dart").read_text()
lines = text.splitlines(keepends=True)
gateway_idx = next(i for i, l in enumerate(lines) if "final gateway = AiGatewayClient" in l)
pending_voice_idx = text.index(
    "    useEffect(() {\n      final pending = pendingVoiceConversationText"
)
handlers_block = text[
    text.index("final gateway = AiGatewayClient", 0) : pending_voice_idx
]
handlers_block = handlers_block[handlers_block.index("\n") + 1 :]

fields = set(
    """context ref screen isCompactTopBar activeMode activeTargetLanguage isBusy modeResponse modeError
translationInput conversationInput tutorInput roleplayInput autoTranslate translationTone translationOutput
translationHistoryQuery translationHistory translationTrayOpen translationTimer translationSourceLang translationTargetLang
tutorLesson tutorFeedback tutorDifficulty tutorFlipped tutorAutoLoadInFlight tutorSeenConcepts tutorSavedCards tutorIsCurrentSaved
roleplayDifficulty roleplayScene roleplayMessages conversationMessages languageRatio conversationIncludeEnglishTranslations
conversationResponseStyle conversationStreamingTarget conversationStreamingActive conversationId voiceService voiceListening
voiceErrorMessage pendingVoiceConversationText persistence conversationRestored vocabCard vocabReveal vocabDeckCount vocabSetName
vocabDifficultyTarget vocabSrsChoice vocabShownWords reviewPayload reviewPeriod modeIntroDismissed chat gateway
translationHistoryService tutorProgress vocabProgress vocabularyService reviewProgress streakDays targetLanguage""".split()
)

func_starts = [
    m.start()
    for m in re.finditer(
        r"    ((?:Future<[^>]+>|String) \w+\([^)]*\)(?: async)? \{)", handlers_block
    )
]
funcs = [
    handlers_block[
        func_starts[i] : func_starts[i + 1] if i + 1 < len(func_starts) else len(handlers_block)
    ]
    for i in range(len(func_starts))
]


def transform(func: str) -> str:
    b = re.sub(r"^    ", "", func, flags=re.M)
    for f in sorted(fields, key=len, reverse=True):
        b = re.sub(rf"(?<![.\w]){f}\b", f"this.{f}", b)
    b = b.replace("this.this.", "this.")
    b = b.replace("this.targetLanguage", "targetLanguage")
    return b


methods = [transform(f) for f in funcs]
chunks: list[str] = []
cur: list[str] = []
cur_len = 0
for m in methods:
    ml = len(m.splitlines())
    if cur_len + ml > 340 and cur:
        chunks.append("".join(cur))
        cur = [m]
        cur_len = ml
    else:
        cur.append(m)
        cur_len += ml
if cur:
    chunks.append("".join(cur))

header = text.split("class PolieWorkspaceBuildHost")[0]
header += "import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_runtime.dart';\n\n"

bh = ROOT / "lib/features/polie_workspace/build_host"
for i, chunk in enumerate(chunks):
    name = f"polie_workspace_host_handlers_{i + 1}.dart"
    (bh / name).write_text(
        header + f"extension PolieWorkspaceHostHandlers{i + 1} on PolieWorkspaceHostRuntime {{\n{chunk}}}\n"
    )
    print(name, len(chunk.splitlines()))
