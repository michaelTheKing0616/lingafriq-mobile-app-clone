"""AI bootstrap stage for week 1–3 curriculum drafting (P4-121, ELEVATION §6.4.1).

Injectable LLM/MT/Spitch clients only. Outputs use the P4-100 envelope (ai_assisted,
label beta). No invented language data.
"""

from __future__ import annotations

import json
import os
from collections.abc import Mapping, Sequence
from pathlib import Path
from typing import Any, Protocol

from tools.content_engine.pipeline.backtranslate import mt_provider_for_language
from tools.content_engine.pipeline.generate import (
    EXT01_CITATION,
    read_model_routing,
)
from tools.content_engine.pipeline.generation_guard import (
    allowed_form_set,
    validate_claims_lexicon_and_citations,
)
from tools.content_pipeline.coverage_check import load_stage1_coverage
from tools.content_pipeline.language_kit import assert_ai_bootstrap_allowed
from tools.content_pipeline.tone_suggest import (
    LlmToneClient,
    finalize_tone_suggestion,
    nfc,
    suggest_via_llm,
    suggest_yoruba_via_spitch,
    tone_suggester_for_language,
)

CARD_ID = "P4-121"
STACK_SECTION = "§3.9 Content and curriculum bootstrapping"
_STACK_DOC_REL = "docs/plan/LINGAFRIQ_AI_MODEL_STACK.md"
_STACK_SECTION_MARKER = "### 3.9 Content and curriculum bootstrapping"
_SPITCH_MODEL_ENV = "CONTENT_ENGINE_SPITCH_DIACRITICS_MODEL"
_BOOTSTRAP_PROMPT_ID = "content-bootstrap-v1"

_REPO_ROOT = Path(__file__).resolve().parents[2]

_DRAFT_SECTIONS = frozenset(
    {
        "lexicon_entry",
        "gloss",
        "example",
        "dialogue_line",
        "distractor",
        "cultural_note",
        "eval_item",
        "ui_string",
    },
)


class BootstrapError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


class BootstrapLlmClient(Protocol):
    def complete(self, model: str, payload: Mapping[str, Any]) -> str:
        """Return JSON bootstrap draft text."""


class BootstrapMtClient(Protocol):
    def translate_gloss(
        self,
        provider: str,
        model: str,
        language: str,
        text: str,
    ) -> str:
        """Return MT gloss draft for a lexeme or phrase."""


class BootstrapSpitchClient(Protocol):
    def restore(self, language: str, text: str) -> str:
        """Spitch diacritics restoration for Yoruba tone QA."""


class _LlmToneAdapter:
    """Map bootstrap LLM client to tone_suggest.LlmToneClient."""

    def __init__(self, client: BootstrapLlmClient) -> None:
        self._client = client

    def suggest(self, language: str, text: str, *, model: str) -> str:
        raw = self._client.complete(
            model,
            {"language": language, "text": text, "task": "tone_mark"},
        )
        try:
            data = json.loads(raw)
        except json.JSONDecodeError:
            return raw.strip()
        if isinstance(data, Mapping):
            marked = data.get("marked")
            if isinstance(marked, str) and marked.strip():
                return marked.strip()
        return raw.strip()


def stack_doc_path() -> Path:
    return _REPO_ROOT / _STACK_DOC_REL


def coverage_file_path() -> Path:
    return _REPO_ROOT / "assets/content/stage1_coverage.json"


def seed_lexicon_forms(kit: Mapping[str, Any]) -> frozenset[str]:
    seed = kit.get("seed_lexicon")
    if not isinstance(seed, list):
        raise BootstrapError("KIT_INVALID", "seed_lexicon must be a list")
    forms: set[str] = set()
    for index, row in enumerate(seed):
        if not isinstance(row, Mapping):
            raise BootstrapError("KIT_INVALID", f"seed_lexicon[{index}] must be a mapping")
        lemma = row.get("lemma")
        if not isinstance(lemma, str) or not lemma.strip():
            raise BootstrapError("KIT_INVALID", f"seed_lexicon[{index}].lemma required")
        forms.add(nfc(lemma.strip()))
    return frozenset(forms)


def _bootstrap_matrix_from_coverage(coverage: Mapping[str, Any]) -> dict[str, Any]:
    return {
        "draft_llm_env": "CONTENT_ENGINE_GENERATION_MODEL",
        "crosscheck_llm_env": "CONTENT_ENGINE_CROSSCHECK_MODEL",
        "tone_yoruba_vendor": "spitch",
        "spitch_model_env": _SPITCH_MODEL_ENV,
        "mt_google_env": "CONTENT_ENGINE_GOOGLE_MT_MODEL",
        "mt_madlad_env": "CONTENT_ENGINE_MADLAD_MT_MODEL",
        "coverage_card_id": coverage.get("card_id"),
        "coverage_sources": list(coverage.get("sources", [])),
    }


def resolve_vendor_matrix(
    *,
    stack_path: Path | None = None,
    coverage_path: Path | None = None,
) -> dict[str, Any]:
    """AC5: prefer stack doc; fall back to stage-1 coverage and report EXT-01."""
    stack = stack_path or stack_doc_path()
    coverage_p = coverage_path or coverage_file_path()
    warnings: list[dict[str, str]] = []
    if stack.is_file():
        text = stack.read_text(encoding="utf-8")
        if _STACK_SECTION_MARKER not in text:
            raise BootstrapError(
                "STACK_SECTION_MISSING",
                f"{STACK_SECTION} not found in {_STACK_DOC_REL}",
            )
        routing = read_model_routing()
        return {
            "card_id": CARD_ID,
            "source": "stack_doc",
            "ext01_citation": routing["ext01_citation"],
            "stack_section": routing["stack_section"],
            "draft_model": routing["model"],
            "matrix": {
                "tone_yoruba_vendor": "spitch",
                "draft_llm": routing["model"],
            },
            "warnings": warnings,
        }
    coverage = load_stage1_coverage(coverage_p)
    warnings.append(
        {
            "code": "EXT-01",
            "message": f"companion doc missing at {_STACK_DOC_REL}; vendor matrix from coverage file",
        },
    )
    return {
        "card_id": CARD_ID,
        "source": "stage1_coverage",
        "ext01_citation": EXT01_CITATION,
        "stack_section": STACK_SECTION,
        "matrix": _bootstrap_matrix_from_coverage(coverage),
        "warnings": warnings,
    }


def read_spitch_model() -> str:
    model = os.environ.get(_SPITCH_MODEL_ENV, "").strip()
    if not model:
        raise BootstrapError(
            "MODEL_NOT_CONFIGURED",
            f"set {_SPITCH_MODEL_ENV} per {EXT01_CITATION} ({STACK_SECTION})",
        )
    return model


def bootstrap_provenance(*, model_id: str) -> dict[str, Any]:
    return {
        "author": "content-bootstrap",
        "created_at": "2026-10-26",
        "ai_assisted": True,
        "model_id": model_id,
        "prompt_id": _BOOTSTRAP_PROMPT_ID,
        "sources": [
            {
                "name": "AI bootstrap stage",
                "licence": "internal-draft",
                "uri_or_citation": f"{CARD_ID}:{STACK_SECTION}",
                "retrieved_at": "2026-10-26",
            },
        ],
    }


def wrap_bootstrap_asset(
    body: Mapping[str, Any],
    *,
    model_id: str,
    asset_kind: str,
) -> dict[str, Any]:
    """AC1: every bootstrap output is ai_assisted with label beta."""
    return {
        "card_id": CARD_ID,
        "asset_kind": asset_kind,
        "label": "beta",
        "confidence": 0.5,
        "claims": [],
        "risk_tags": ["tone"] if asset_kind in {"lexicon_entry", "example", "dialogue_line"} else [],
        "audio": [],
        "provenance": bootstrap_provenance(model_id=model_id),
        "body": dict(body),
    }


def validate_cultural_note_draft(note: Mapping[str, Any]) -> dict[str, Any]:
    """AC4: reject drafts without citations."""
    if not isinstance(note, Mapping):
        raise BootstrapError("ITEM_INVALID", "cultural note must be a mapping")
    text = note.get("text")
    if not isinstance(text, str) or not text.strip():
        raise BootstrapError("ITEM_INVALID", "cultural note text required")
    citation = note.get("citation")
    if not isinstance(citation, Mapping):
        raise BootstrapError("CITATION_MISSING", "cultural note citation required")
    source_id = citation.get("source_id")
    locator = citation.get("locator")
    if not isinstance(source_id, str) or not source_id.strip():
        raise BootstrapError("CITATION_MISSING", "cultural note source_id required")
    if not isinstance(locator, str) or not locator.strip():
        raise BootstrapError("CITATION_MISSING", "cultural note locator required")
    return {
        "section": "cultural_note",
        "text": text.strip(),
        "citation": {
            "source_id": source_id.strip(),
            "locator": locator.strip(),
        },
    }


def parse_bootstrap_draft(raw: str | Mapping[str, Any]) -> dict[str, Any]:
    if isinstance(raw, Mapping):
        data: Mapping[str, Any] = raw
    elif isinstance(raw, str):
        try:
            loaded = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise BootstrapError("DRAFT_INVALID", f"draft is not valid JSON: {exc}") from exc
        if not isinstance(loaded, Mapping):
            raise BootstrapError("DRAFT_INVALID", "draft root must be an object")
        data = loaded
    else:
        raise BootstrapError("DRAFT_INVALID", "draft must be JSON text or a mapping")

    assets = data.get("assets")
    if not isinstance(assets, list) or not assets:
        raise BootstrapError("DRAFT_INVALID", "assets must be a non-empty list")
    parsed: list[dict[str, Any]] = []
    for index, asset in enumerate(assets):
        if not isinstance(asset, Mapping):
            raise BootstrapError("DRAFT_INVALID", f"assets[{index}] must be a mapping")
        kind = asset.get("kind")
        if kind not in _DRAFT_SECTIONS:
            raise BootstrapError("DRAFT_INVALID", f"assets[{index}].kind unsupported")
        parsed.append(dict(asset))
    tone_plain = data.get("tone_plain")
    tone_rows: list[str] = []
    if tone_plain is not None:
        if isinstance(tone_plain, str) and tone_plain.strip():
            tone_rows.append(tone_plain.strip())
        elif isinstance(tone_plain, list):
            for row in tone_plain:
                if isinstance(row, str) and row.strip():
                    tone_rows.append(row.strip())
    return {"assets": parsed, "tone_plain": tone_rows}


def build_bootstrap_request(kit: Mapping[str, Any]) -> dict[str, Any]:
    assert_ai_bootstrap_allowed(kit)
    language = str(kit.get("language_id", "")).strip().lower()
    if not language:
        raise BootstrapError("KIT_INVALID", "language_id required")
    matrix_info = resolve_vendor_matrix()
    seed_forms = seed_lexicon_forms(kit)
    allowed = [{"form": form} for form in sorted(seed_forms)]
    return {
        "card_id": CARD_ID,
        "language_id": language,
        "seed_lexicon_forms": sorted(seed_forms),
        "allowed_lexicon": allowed,
        "vendor_matrix": matrix_info,
        "tone_suggester": tone_suggester_for_language(language),
        "mt_provider": mt_provider_for_language(language),
    }


def _process_assets(
    draft: Mapping[str, Any],
    kit: Mapping[str, Any],
    *,
    model_id: str,
) -> list[dict[str, Any]]:
    language = str(kit.get("language_id", "")).strip().lower()
    allowed_forms = allowed_form_set(
        [{"form": f} for f in seed_lexicon_forms(kit)],
    )
    outputs: list[dict[str, Any]] = []
    for asset in draft["assets"]:
        kind = asset["kind"]
        if kind == "cultural_note":
            claim = validate_cultural_note_draft(asset)
            wrapped = wrap_bootstrap_asset(claim, model_id=model_id, asset_kind=kind)
            outputs.append(wrapped)
            continue
        if kind == "dialogue_line":
            text = asset.get("text")
            if not isinstance(text, str) or not text.strip():
                raise BootstrapError("DRAFT_INVALID", "dialogue_line text required")
            validate_claims_lexicon_and_citations(
                [{"section": "dialogue_line", "text": text}],
                allowed_forms,
            )
            wrapped = wrap_bootstrap_asset(
                {"text": text.strip()},
                model_id=model_id,
                asset_kind=kind,
            )
            outputs.append(wrapped)
            continue
        body = {k: v for k, v in asset.items() if k != "kind"}
        wrapped = wrap_bootstrap_asset(body, model_id=model_id, asset_kind=kind)
        outputs.append(wrapped)
    return outputs


def _process_tone_suggestions(
    tone_plain: Sequence[str],
    kit: Mapping[str, Any],
    *,
    matrix_info: Mapping[str, Any],
    spitch: BootstrapSpitchClient | None,
    llm: BootstrapLlmClient | None,
) -> list[dict[str, Any]]:
    if not tone_plain:
        return []
    language = str(kit.get("language_id", "")).strip().lower()
    seed_forms = seed_lexicon_forms(kit)
    suggester = tone_suggester_for_language(language)
    model_id = str(matrix_info.get("draft_model") or os.environ.get("CONTENT_ENGINE_GENERATION_MODEL", "bootstrap"))
    out: list[dict[str, Any]] = []
    for plain in tone_plain:
        if suggester == "spitch":
            if spitch is None:
                raise BootstrapError("SPITCH_UNAVAILABLE", "Spitch client required for Yoruba tone QA")
            read_spitch_model()
            suggestion = suggest_yoruba_via_spitch(plain, spitch)
        else:
            if llm is None:
                raise BootstrapError("LLM_UNAVAILABLE", "LLM client required for tone suggestions")
            routing = read_model_routing()
            tone_client: LlmToneClient = _LlmToneAdapter(llm)
            suggestion = suggest_via_llm(
                language,
                plain,
                kit,
                tone_client,
                model=routing["model"],
            )
        finalized = finalize_tone_suggestion(suggestion, seed_forms)
        wrapped = wrap_bootstrap_asset(
            finalized,
            model_id=model_id,
            asset_kind="tone_suggestion",
        )
        out.append(wrapped)
    return out


def run_ai_bootstrap(
    kit: Mapping[str, Any],
    draft: str | Mapping[str, Any],
    *,
    llm: BootstrapLlmClient | None = None,
    mt: BootstrapMtClient | None = None,
    spitch: BootstrapSpitchClient | None = None,
) -> dict[str, Any]:
    """Run bootstrap on a complete kit and a grounded draft payload (AC1–AC5)."""
    request = build_bootstrap_request(kit)
    matrix_info = request["vendor_matrix"]
    model_id = str(matrix_info.get("draft_model") or "bootstrap-unconfigured")
    parsed = parse_bootstrap_draft(draft)
    assets = _process_assets(parsed, kit, model_id=model_id)
    tones = _process_tone_suggestions(
        parsed.get("tone_plain", []),
        kit,
        matrix_info=matrix_info,
        spitch=spitch,
        llm=llm,
    )
    mt_glosses: list[dict[str, Any]] = []
    if mt is not None and matrix_info.get("source") == "stack_doc":
        routing = read_model_routing()
        provider = request["mt_provider"]
        env_key = (
            "CONTENT_ENGINE_GOOGLE_MT_MODEL"
            if provider == "google_cloud"
            else "CONTENT_ENGINE_MADLAD_MT_MODEL"
        )
        mt_model = os.environ.get(env_key, "").strip() or routing["model"]
        language = str(kit.get("language_id", "")).strip().lower()
        for form in sorted(seed_lexicon_forms(kit))[:3]:
            gloss = mt.translate_gloss(provider, mt_model, language, form)
            mt_glosses.append(
                wrap_bootstrap_asset(
                    {"lemma": form, "gloss_draft": gloss, "mt_provider": provider},
                    model_id=mt_model,
                    asset_kind="gloss",
                ),
            )
    all_outputs = assets + tones + mt_glosses
    for row in all_outputs:
        prov = row.get("provenance")
        if not isinstance(prov, Mapping) or prov.get("ai_assisted") is not True:
            raise BootstrapError("AI_FLAG_MISSING", "bootstrap output missing ai_assisted")
        if row.get("label") != "beta":
            raise BootstrapError("LABEL_INVALID", "bootstrap output must be label beta")
    return {
        "card_id": CARD_ID,
        "language_id": kit.get("language_id"),
        "vendor_matrix": matrix_info,
        "outputs": all_outputs,
        "warnings": list(matrix_info.get("warnings", [])),
    }
