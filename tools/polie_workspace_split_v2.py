#!/usr/bin/env python3
"""Split polie_workspace_build_host_impl.dart into <=500-line modules (P12-005)."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IMPL = ROOT / "lib/features/polie_workspace/build_host/polie_workspace_build_host_impl.dart"
BH = ROOT / "lib/features/polie_workspace/build_host"
text = IMPL.read_text()
lines = text.splitlines(keepends=True)

# Shared imports header (through line 48, before class)
header_end = next(i for i, l in enumerate(lines) if l.startswith("class PolieWorkspaceBuildHost"))
HEADER = "".join(lines[:header_end])

# Find handler region: after `final gateway = ...` through loadReview's closing brace
gateway_line = next(i for i, l in enumerate(lines) if "final gateway = AiGatewayClient" in l)
# End before pending voice useEffect after loadReview
end_marker = "    useEffect(() {\n      final init = screen.conversationOnly"
end_idx = text.index(end_marker)
handlers_text = text[text.index("    Future<void> refreshTutorSavedCards", gateway_line):end_idx]

# Top-level handler functions only (4-space indent Future or String)
func_pat = re.compile(
    r"(    ((?:Future<[^>]+>|String) \w+\([^)]*\)(?: async)? \{))",
    re.MULTILINE,
)
starts = [m.start() for m in func_pat.finditer(handlers_text)]
funcs = [
    handlers_text[starts[i] : starts[i + 1] if i + 1 < len(starts) else len(handlers_text)]
    for i in range(len(starts))
]

FIELDS = """context ref screen isCompactTopBar activeMode activeTargetLanguage isBusy modeResponse modeError
translationInput conversationInput tutorInput roleplayInput autoTranslate translationTone translationOutput
translationHistoryQuery translationHistory translationTrayOpen translationTimer translationSourceLang translationTargetLang
tutorLesson tutorFeedback tutorDifficulty tutorFlipped tutorAutoLoadInFlight tutorSeenConcepts tutorSavedCards tutorIsCurrentSaved
roleplayDifficulty roleplayScene roleplayMessages conversationMessages languageRatio conversationIncludeEnglishTranslations
conversationResponseStyle conversationStreamingTarget conversationStreamingActive conversationId voiceService voiceListening
voiceErrorMessage pendingVoiceConversationText persistence conversationRestored vocabCard vocabReveal vocabDeckCount vocabSetName
vocabDifficultyTarget vocabSrsChoice vocabShownWords reviewPayload reviewPeriod modeIntroDismissed chat gateway
translationHistoryService tutorProgress vocabProgress vocabularyService reviewProgress streakDays""".split()


def demote(func: str) -> str:
    body = re.sub(r"^    ", "", func, flags=re.MULTILINE)
    for f in sorted(set(FIELDS), key=len, reverse=True):
        body = re.sub(rf"(?<![.\w]){f}\b", f"this.{f}", body)
    body = body.replace("this.this.", "this.")
    body = re.sub(r"this\.targetLanguage\b", "targetLanguage", body)
    body = re.sub(r"\bthis\.(\w+):", r"\1:", body)
    return body


def chunk_methods(methods: list[str], max_lines: int = 480) -> list[list[str]]:
    chunks: list[list[str]] = []
    cur: list[str] = []
    cur_n = 0
    for m in methods:
        n = len(m.splitlines())
        if cur_n + n > max_lines and cur:
            chunks.append(cur)
            cur = [m]
            cur_n = n
        else:
            cur.append(m)
            cur_n += n
    if cur:
        chunks.append(cur)
    return chunks


methods = [demote(f) for f in funcs]
# sendConversation alone must not exceed 500 lines — isolate it.
named = []
for m in methods:
    first = m.strip().split("(")[0].split()[-1]
    named.append((first, m))
big = next((m for n, m in named if n == "sendConversation"), None)
rest = [m for n, m in named if n != "sendConversation"]
chunks = chunk_methods(rest, max_lines=450)
if big:
    chunks.append([big])

RUNTIME_IMPORT = "import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_runtime.dart';\n\n"
handler_header = HEADER + RUNTIME_IMPORT

for i, chunk in enumerate(chunks):
    body = "\n".join(chunk)
    name = f"polie_workspace_host_handlers_{i + 1}.dart"
    (BH / name).write_text(
        handler_header
        + f"extension PolieWorkspaceHostHandlers{i + 1} on PolieWorkspaceHostRuntime {{\n{body}\n}}\n"
    )
    print(name, len(body.splitlines()))

# Scaffold: from `return Scaffold` to before closing `  }\n}`
scaffold_start = next(i for i, l in enumerate(lines) if l.strip() == "return Scaffold(")
scaffold_end = len(lines) - 2  # before `  }\n}`
scaffold_body = "".join(lines[scaffold_start:scaffold_end])
# Replace return Scaffold with function body
scaffold_inner = re.sub(r"^    ", "  ", scaffold_body, flags=re.MULTILINE)
for f in sorted(set(FIELDS + ["viewportWidth"]), key=len, reverse=True):
    scaffold_inner = re.sub(rf"(?<![.\w]){f}\b", f"host.{f}", scaffold_inner)
scaffold_inner = scaffold_inner.replace("host.host.", "host.")
scaffold_inner = re.sub(r"host\.targetLanguage\b", "host.targetLanguage", scaffold_inner)
scaffold_fn = (
    HEADER
    + RUNTIME_IMPORT
    + "import 'package:lingafriq/features/polie_workspace/polie_workspace_mode_surface.dart';\n\n"
    + "Widget polieWorkspaceBuildHostScaffold(PolieWorkspaceHostRuntime host) {\n"
    + scaffold_inner
    + "}\n"
)
(BH / "polie_workspace_build_host_scaffold.dart").write_text(scaffold_fn)
print("scaffold", len(scaffold_fn.splitlines()))

print("funcs", len(funcs), [f.split("(")[0].strip()[-30:] for f in funcs])
