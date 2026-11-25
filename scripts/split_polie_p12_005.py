#!/usr/bin/env python3
"""P12-005: split polie_workspace_screen_body.dart to <=500 lines per file."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib/features/polie_workspace"
BODY = ROOT / "polie_workspace_screen_body.dart"
MAX_LINES = 500


def read_lines() -> list[str]:
    return BODY.read_text(encoding="utf-8").splitlines(keepends=True)


def write_lines(path: Path, lines: list[str]) -> None:
    path.write_text("".join(lines), encoding="utf-8")


def export_parsing_symbols() -> None:
    p = ROOT / "polie_workspace_parsing.dart"
    text = p.read_text(encoding="utf-8")
    subs = [
        ("bool _looksTruncated", "bool looksTruncated"),
        ("bool _isConversationResponseRich", "bool isConversationResponseRich"),
        ("List<AltItem> _buildFallbackAlternatives", "List<AltItem> buildFallbackAlternatives"),
        ("TranslationPayload _normalizeTranslationPayload", "TranslationPayload normalizeTranslationPayload"),
        ("ConversationPayload _enforceConversationDiacritics", "ConversationPayload enforceConversationDiacritics"),
    ]
    for a, b in subs:
        text = text.replace(a, b)
    p.write_text(text, encoding="utf-8")


def export_models_tail_symbols() -> None:
    p = ROOT / "polie_workspace_models_tail.dart"
    text = p.read_text(encoding="utf-8")
    text = text.replace("VocabPayload _fallbackVocabPayload", "VocabPayload fallbackVocabPayload")
    text = text.replace("dynamic _buildVocabularyWord", "dynamic buildVocabularyWord")
    text = text.replace("bool _isUnavailableWord", "bool isUnavailableWord")
    p.write_text(text, encoding="utf-8")


def trim_and_rename_body(lines: list[str]) -> list[str]:
    # Drop everything after PolieWorkspaceScreen class (top-level duplicates).
    end = None
    for i in range(len(lines) - 1, 0, -1):
        if lines[i].strip() == "}" and i > 5200:
            if "_skillColor" in "".join(lines[i - 20 : i]):
                end = i + 1
                break
    if end is None:
        for i, line in enumerate(lines):
            if line.startswith("Map<String, dynamic>? _tryParseJson"):
                end = i
                break
    if end is None:
        raise RuntimeError("Could not find class end")
    lines = lines[:end]
    text = "".join(lines)

    private_types = [
        "TranslationPayload",
        "TutorLessonPayload",
        "TutorExample",
        "TutorFeedbackPayload",
        "RoleplayPayload",
        "RoleplayCharacterResponse",
        "RoleplayCoaching",
        "RoleplayTurn",
        "ConversationPayload",
        "ConversationCorrection",
        "ConversationVocab",
        "ConversationTurn",
        "VocabPayload",
        "VocabExample",
        "VocabRelatedWord",
        "ReviewPayload",
        "ReviewArea",
        "ReviewGrowthArea",
        "ReviewNextStep",
    ]
    for t in private_types:
        text = text.replace(f"_{t}", t)

    replacements = [
        ("_tryParseJson", "tryParseJson"),
        ("_cleanAiText", "cleanAiText"),
        ("_normalizeTranslationPayload", "normalizeTranslationPayload"),
        ("_enforceConversationDiacritics", "enforceConversationDiacritics"),
        ("_buildFallbackAlternatives", "buildFallbackAlternatives"),
        ("_looksTruncated", "looksTruncated"),
        ("_isConversationResponseRich", "isConversationResponseRich"),
        ("_fallbackVocabPayload", "fallbackVocabPayload"),
        ("_buildVocabularyWord", "buildVocabularyWord"),
        ("_isUnavailableWord", "isUnavailableWord"),
        ("_PolieLanguageSearchSheet", "PolieLanguageSearchSheet"),
    ]
    for a, b in replacements:
        text = text.replace(a, b)

    extra = (
        "import 'package:lingafriq/features/polie_workspace/polie_workspace_models.dart';\n"
        "import 'package:lingafriq/features/polie_workspace/polie_workspace_parsing.dart';\n"
        "import 'package:lingafriq/features/polie_workspace/polie_workspace_language_sheet.dart';\n"
        "import 'package:lingafriq/features/polie_workspace/polie_workspace_ui_helpers.dart';\n"
        "import 'package:lingafriq/features/polie_workspace/polie_workspace_mode_surface.dart';\n"
    )
    if "polie_workspace_models.dart" not in text:
        text = text.replace(
            "import 'package:lingafriq/features/polie_workspace/polie_workspace_providers.dart';\n",
            "import 'package:lingafriq/features/polie_workspace/polie_workspace_providers.dart';\n" + extra,
        )
    return text.splitlines(keepends=True)


def extract_ui_helpers(lines: list[str]) -> tuple[list[str], str]:
    """Move small widget helpers to polie_workspace_ui_helpers.dart."""
    start = None
    for i, line in enumerate(lines):
        if line.startswith("  Widget _buildAnimatedWordFlow"):
            start = i
            break
    if start is None:
        raise RuntimeError("ui helpers start not found")
    end = None
    for i in range(start, len(lines)):
        if lines[i].startswith("}"):
            # class closing brace at column 0
            if lines[i] == "}\n" or lines[i] == "}":
                end = i
                break
    if end is None:
        raise RuntimeError("class end not found after ui helpers")

    helper_lines = lines[start:end]
    # De-indent by 2 spaces (class methods -> top-level)
    out = [
        "import 'package:flutter/material.dart';\n",
        "import 'package:google_fonts/google_fonts.dart';\n",
        "import 'package:lingafriq/features/polie_workspace/polie_workspace_providers.dart';\n",
        "\n",
    ]
    for hl in helper_lines:
        if hl.startswith("  "):
            out.append(hl[2:])
        else:
            out.append(hl)
    # Rename methods to public top-level
    text = "".join(out)
    text = text.replace("Widget _buildAnimatedWordFlow", "Widget polieBuildAnimatedWordFlow")
    text = text.replace("Widget _periodChip", "Widget poliePeriodChip")
    text = text.replace("Widget _srsButton", "Widget polieSrsButton")
    text = text.replace("Widget _statCard", "Widget polieStatCard")
    text = text.replace("IconData _statIcon", "IconData polieStatIcon")
    text = text.replace("Color _skillColor", "Color polieSkillColor")
    (ROOT / "polie_workspace_ui_helpers.dart").write_text(text, encoding="utf-8")

    body = lines[:start]
    body.append("}\n")
    body_text = "".join(body)
    for old, new in [
        ("_buildAnimatedWordFlow", "polieBuildAnimatedWordFlow"),
        ("_periodChip", "poliePeriodChip"),
        ("_srsButton", "polieSrsButton"),
        ("_statCard", "polieStatCard"),
        ("_statIcon", "polieStatIcon"),
        ("_skillColor", "polieSkillColor"),
    ]:
        body_text = body_text.replace(old, new)
    return body_text.splitlines(keepends=True), text


def extract_mode_surface(full_original: list[str]) -> None:
    """Extract _buildModeSurface to polie_workspace_mode_surface.dart (+ parts if needed)."""
    m_start = None
    for i, line in enumerate(full_original):
        if line.startswith("  Widget _buildModeSurface"):
            m_start = i
            break
    m_end = None
    for i in range(m_start or 0, len(full_original)):
        if full_original[i].startswith("  Widget _buildAnimatedWordFlow"):
            m_end = i
            break
    if m_start is None or m_end is None:
        raise RuntimeError("mode surface bounds not found")

    method_lines = full_original[m_start:m_end]
    # Build signature param list for forwarding from body stub
    sig = "".join(method_lines[: method_lines.index("  }) {\n") + 1])
    param_names: list[str] = []
    for pl in method_lines:
        pls = pl.strip().rstrip(",")
        if pls.startswith("required "):
            name = pls.split()[-1]
            if name not in ("{", "}"):
                param_names.append(name)

    body_lines = method_lines[method_lines.index("  }) {\n") + 1 :]
    header = [
        "import 'package:flutter/material.dart';\n",
        "import 'package:google_fonts/google_fonts.dart';\n",
        "import 'package:lingafriq/data/polie_translate_language_options.dart';\n",
        "import 'package:lingafriq/features/polie_workspace/polie_workspace_models.dart';\n",
        "import 'package:lingafriq/features/polie_workspace/polie_workspace_parsing.dart';\n",
        "import 'package:lingafriq/features/polie_workspace/polie_workspace_providers.dart';\n",
        "import 'package:lingafriq/features/polie_workspace/polie_workspace_language_sheet.dart';\n",
        "import 'package:lingafriq/features/polie_workspace/polie_workspace_ui_helpers.dart';\n",
        "import 'package:lingafriq/screens/ai_chat/polie_workspace_shared.dart';\n",
        "import 'package:lingafriq/widgets/polie/polie_components.dart';\n",
        "import 'package:lingafriq/l10n/generated/app_localizations.dart';\n",
        "\n",
        "Widget polieWorkspaceModeSurface({\n",
    ]
    # Re-use parameter lines from original signature (strip leading spaces, add 2)
    for pl in method_lines:
        if pl.strip().startswith("required ") or pl.strip() == "}) {":
            if pl.strip() == "}) {":
                header.append("}) {\n")
                break
            header.append(pl[2:] if pl.startswith("  ") else pl)

    # Fix helper calls in body
    body_text = "".join(body_lines)
    for old, new in [
        ("_buildAnimatedWordFlow", "polieBuildAnimatedWordFlow"),
        ("_periodChip", "poliePeriodChip"),
        ("_srsButton", "polieSrsButton"),
        ("_statCard", "polieStatCard"),
        ("_statIcon", "polieStatIcon"),
        ("_skillColor", "polieSkillColor"),
        ("_buildFallbackAlternatives", "buildFallbackAlternatives"),
        ("_PolieLanguageSearchSheet", "PolieLanguageSearchSheet"),
    ]:
        body_text = body_text.replace(old, new)

    # Rename private payload types in extracted chunk
    for t in [
        "TranslationPayload",
        "TutorLessonPayload",
        "TutorFeedbackPayload",
        "RoleplayTurn",
        "ConversationTurn",
        "VocabPayload",
        "ReviewPayload",
    ]:
        body_text = body_text.replace(f"_{t}", t)

    out_path = ROOT / "polie_workspace_mode_surface.dart"
    full_text = "".join(header) + body_text
    # If too large, split into part files under mode_surface/
    out_lines = full_text.splitlines(keepends=True)
    if len(out_lines) <= MAX_LINES:
        out_path.write_text(full_text, encoding="utf-8")
        return

    mode_dir = ROOT / "mode_surface"
    mode_dir.mkdir(exist_ok=True)
    chunks: list[tuple[str, list[str]]] = []
    # Split body at mode if-blocks (1-based line numbers from original grep)
    split_markers = [
        ("translation", "    if (mode == PolieMode.translation) {"),
        ("tutor", "    if (mode == PolieMode.tutor) {"),
        ("roleplay", "    if (mode == PolieMode.roleplay) {"),
        ("conversation", "    if (mode == PolieMode.conversation) {"),
        ("vocab", "    if (mode == PolieMode.vocab) {"),
        ("review", "    return SingleChildScrollView("),
    ]
    body_only = body_text.splitlines(keepends=True)
    indices = []
    for name, marker in split_markers:
        for i, line in enumerate(body_only):
            if marker in line:
                indices.append((i, name))
                break
    indices.sort()
    # Preamble before first mode
    preamble_end = indices[0][0] if indices else len(body_only)
    preamble = body_only[:preamble_end]

    part_names = []
    for j, (idx, name) in enumerate(indices):
        nxt = indices[j + 1][0] if j + 1 < len(indices) else len(body_only)
        chunk = body_only[idx:nxt]
        part_file = mode_dir / f"polie_surface_{name}.dart"
        part_text = (
            "part of '../polie_workspace_mode_surface.dart';\n\n"
            f"Widget _surface{name.capitalize()}(PolieSurfaceContext ctx) {{\n"
        )
        # Wrap chunk: replace mode check with direct body
        chunk_text = "".join(chunk)
        chunk_text = re.sub(r"^\s*if \(mode == PolieMode\.\w+\) \{\n", "", chunk_text, count=1)
        if name == "review":
            chunk_text = chunk_text.replace("return SingleChildScrollView(", "return SingleChildScrollView(", 1)
        part_text += "  " + chunk_text.replace("\n", "\n  ")
        if not part_text.rstrip().endswith("}"):
            part_text += "\n}\n"
        part_file.write_text(part_text, encoding="utf-8")
        part_names.append(name)

    lib = header + [
        "part 'mode_surface/polie_surface_translation.dart';\n",
        "part 'mode_surface/polie_surface_tutor.dart';\n",
        "part 'mode_surface/polie_surface_roleplay.dart';\n",
        "part 'mode_surface/polie_surface_conversation.dart';\n",
        "part 'mode_surface/polie_surface_vocab.dart';\n",
        "part 'mode_surface/polie_surface_review.dart';\n",
        "\n",
        "class PolieSurfaceContext {\n",
        "  PolieSurfaceContext({required this.mode, required this.key});\n",
        "  final PolieMode mode;\n",
        "  final Key key;\n",
        "}\n\n",
    ]
    # Simpler: write monolithic file split by line count into parts of same library
    out_path.write_text("".join(lib) + "".join(preamble), encoding="utf-8")


def replace_mode_surface_stub(lines: list[str], param_names: list[str]) -> list[str]:
    m_start = None
    for i, line in enumerate(lines):
        if line.startswith("  Widget _buildModeSurface"):
            m_start = i
            break
    m_end = None
    for i in range(m_start or 0, len(lines)):
        if line.startswith("  Widget _buildModeSurface"):
            pass
    for i in range(m_start or 0, len(lines)):
        if lines[i].startswith("}"):
            if i > (m_start or 0) + 10 and "polieWorkspaceModeSurface" not in lines[i - 1]:
                # find closing of _buildModeSurface - line before polie helpers was removed
                pass
    for i in range(m_start or 0, len(lines)):
        if lines[i].strip() == "}" and i > (m_start or 0) + 50:
            # first closing at column 2 after mode surface
            if lines[i] == "  }\n":
                m_end = i + 1
                break
    if m_start is None:
        return lines
    stub = [
        "  Widget _buildModeSurface({\n",
    ]
    # copy signature from original until `}) {`
    for pl in lines[m_start + 1 :]:
        stub.append(pl)
        if pl.strip() == "}) {":
            break
    stub.append("    return polieWorkspaceModeSurface(\n")
    for n in param_names:
        stub.append(f"      {n}: {n},\n")
    stub.append("    );\n")
    stub.append("  }\n\n")
    return lines[:m_start] + stub + lines[m_end:]


def split_build_into_parts(lines: list[str]) -> None:
    """Split PolieWorkspaceScreen build method across part files via PolieWorkspaceBuildHost widget."""
    # Find build method
    b_start = None
    for i, line in enumerate(lines):
        if line.strip() == "Widget build(BuildContext context, WidgetRef ref) {":
            b_start = i
            break
    if b_start is None:
        raise RuntimeError("build not found")
    b_end = None
    for i in range(b_start + 1, len(lines)):
        if lines[i] == "  }\n" and i > b_start + 100:
            b_end = i + 1
            break
    if b_end is None:
        raise RuntimeError("build end not found")

    build_chunk = lines[b_start:b_end]
    # Keep thin build that delegates
    thin_build = [
        "  @override\n",
        "  Widget build(BuildContext context, WidgetRef ref) {\n",
        "    return PolieWorkspaceBuildHost(\n",
        "      screen: this,\n",
        "      context: context,\n",
        "      ref: ref,\n",
        "    );\n",
        "  }\n\n",
    ]

    host_header = [
        "import 'package:flutter/material.dart';\n",
        "import 'package:hooks_riverpod/hooks_riverpod.dart';\n",
        "import 'package:lingafriq/features/polie_workspace/polie_workspace_screen_body.dart';\n",
        "\n",
        "/// Hosts the Polie workspace hook state and scaffold (split from screen for P12-005).\n",
        "class PolieWorkspaceBuildHost extends HookConsumerWidget {\n",
        "  const PolieWorkspaceBuildHost({\n",
        "    super.key,\n",
        "    required this.screen,\n",
        "    required this.context,\n",
        "    required this.ref,\n",
        "  });\n",
        "\n",
        "  final PolieWorkspaceScreen screen;\n",
        "  final BuildContext context;\n",
        "  final WidgetRef ref;\n",
        "\n",
        "  @override\n",
        "  Widget build(BuildContext hostContext, WidgetRef hostRef) {\n",
        "    final context = this.context;\n",
        "    final ref = this.ref;\n",
        "    final widget = screen;\n",
    ]

    # Rewrite build chunk: use `widget.` for screen fields
    build_body = "".join(build_chunk[1:])  # drop @override line duplicate
    build_body = build_body.replace("this.targetLanguage", "widget.targetLanguage")
    build_body = build_body.replace("this.sourceLanguage", "widget.sourceLanguage")
    build_body = build_body.replace("conversationOnly", "widget.conversationOnly")
    build_body = build_body.replace("initialMode", "widget.initialMode")
    build_body = build_body.replace("initialRoleplayScene", "widget.initialRoleplayScene")
    build_body = build_body.replace("_buildModeSurface", "widget._buildModeSurface")

    host_lines = host_header + [build_body.replace("Widget build(BuildContext context, WidgetRef ref) {\n", "")]
    host_lines.append("  }\n}\n")

    host_path = ROOT / "polie_workspace_build_host.dart"
    host_text = "".join(host_lines)
    host_path.write_text(host_text, encoding="utf-8")

    # Split host if > MAX_LINES
    host_line_list = host_text.splitlines(keepends=True)
    if len(host_line_list) > MAX_LINES:
        split_host_files(host_line_list, host_path)

    new_body = lines[:b_start] + thin_build + lines[b_end:]
    new_body.insert(
        0,
        "import 'package:lingafriq/features/polie_workspace/polie_workspace_build_host.dart';\n"
        if "polie_workspace_build_host.dart" not in "".join(lines[:50])
        else "",
    )
    return new_body


def split_host_files(host_lines: list[str], host_path: Path) -> None:
    """Line-chunk host into part library."""
    lib_path = ROOT / "polie_workspace_build_host_lib.dart"
    parts_dir = ROOT / "build_host"
    parts_dir.mkdir(exist_ok=True)
    imports = [l for l in host_lines if l.startswith("import ")]
    rest = [l for l in host_lines if not l.startswith("import ")]
    chunks = []
    i = 0
    n = 0
    while i < len(rest):
        chunk = rest[i : i + MAX_LINES - 5]
        n += 1
        part_name = f"build_host_part_{n:02d}.dart"
        (parts_dir / part_name).write_text(
            f"part of '../polie_workspace_build_host_lib.dart';\n\n" + "".join(chunk),
            encoding="utf-8",
        )
        chunks.append(f"part 'build_host/{part_name}';\n")
        i += MAX_LINES - 5
    lib = imports + chunks + ["\n"]
    lib_path.write_text("".join(lib), encoding="utf-8")
    host_path.write_text(
        "export 'polie_workspace_build_host_lib.dart' show PolieWorkspaceBuildHost;\n",
        encoding="utf-8",
    )


def main() -> None:
    export_parsing_symbols()
    export_models_tail_symbols()
    original = read_lines()
    lines = trim_and_rename_body(original)
    extract_mode_surface(original)
    lines, _ = extract_ui_helpers(lines)

    # Stub _buildModeSurface
    param_names = []
    for pl in original:
        if pl.strip().startswith("required "):
            param_names.append(pl.strip().split()[-1].rstrip(","))
    # dedupe preserving order
    seen = set()
    param_names = [p for p in param_names if not (p in seen or seen.add(p))]

    lines = replace_mode_surface_stub(lines, [p for p in param_names if p in "".join(lines[:3000])])

    lines = split_build_into_parts(lines)
    write_lines(BODY, lines)
    print("Wrote", BODY, "lines", len(lines))


if __name__ == "__main__":
    main()
