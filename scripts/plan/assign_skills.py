#!/usr/bin/env python3
"""charter: v2 — T0. Deterministically assign ≤3 skills per card into `skills:` (list of SKILL.md paths).

Rules live here, not in any model's head. Re-run after adding cards; idempotent.
Paths are relative to SKILLS_ROOT so the repo stays machine-independent; briefs resolve them.
"""
from __future__ import annotations
import re, sys
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[2]
CARDS = ROOT / "docs/build/cards"
A = "adaptive/"
P = "prime/"

# role → always-on skill (one each; the brief loads it)
ROLE_SKILLS = {
    "orchestrator": [A + "00-adaptive-orchestrator", A + "02-model-routing", A + "03-cost-and-token-efficiency"],
    "worker": [A + "08-coding-and-debugging"],
    "tester": [A + "06-execution-and-verification"],
    "reviewer": [A + "06-execution-and-verification"],
}

# (predicate, skills) — first matches win until 3 collected
def _t(c): return (c.get("title") or "").lower()
def _tags(c): return set(c.get("tags") or [])
def _kind(c): return c.get("kind")
def _ph(c): return c.get("phase")

RULES = [
    # design workstream (P3 design cards) — by title keyword
    (lambda c: _kind(c) == "design" and re.search(r"dpia|privacy|consent|policy|casting", _t(c)), [A + "14-safety-and-high-stakes", A + "09-writing-and-communication"]),
    (lambda c: _kind(c) == "design" and re.search(r"gate|scorecard", _t(c)), [P + "design-critique", P + "critique-visual-hierarchy", P + "design-to-code-check"]),
    (lambda c: _kind(c) == "design" and re.search(r"motion|sound|haptic|animation", _t(c)), [P + "motion-system", P + "design-motion-principles", P + "microinteractions"]),
    (lambda c: _kind(c) == "design" and re.search(r"illustration|character bible|chip artboard", _t(c)), [P + "illustration-style", P + "design-dna", P + "rive"]),
    (lambda c: _kind(c) == "design" and re.search(r"autonomy|speaking-first|pedagog|flow with", _t(c)), [P + "hooked-ux", P + "feedback-patterns", P + "onboarding-ux"]),
    (lambda c: _kind(c) == "design" and (_ph(c) == "P13" or re.search(r"study|brief|marketplace|archive|corpus|hook for", _t(c))), [A + "10-analysis-and-decision-support", A + "09-writing-and-communication"]),
    (lambda c: _kind(c) == "design" and re.search(r"benchmark|competitive", _t(c)), [P + "design-audit", P + "critique-visual-hierarchy"]),
    (lambda c: _kind(c) == "design" and re.search(r"principle|journey", _t(c)), [P + "design-everyday-things", P + "design-brief"]),
    (lambda c: _kind(c) == "design" and re.search(r"art direction|direction", _t(c)), [P + "design-dna", P + "illustration-style", P + "no-ai-slop"]),
    (lambda c: _kind(c) == "design" and re.search(r"token", _t(c)), [P + "design-tokens", P + "spacing-system", P + "typography-scale"]),
    (lambda c: _kind(c) == "design" and re.search(r"colou?r|palette|dark", _t(c)), [P + "algorithmic-color-palette", P + "dark-mode-design", P + "status-colors-and-errors"]),
    (lambda c: _kind(c) == "design" and re.search(r"hi-fi|signature|screen", _t(c)), [P + "mobile-app-ui-design", P + "antislop-ui", P + "platform-conventions"]),
    (lambda c: _kind(c) == "design" and re.search(r"component|catalogue|widgetbook", _t(c)), [P + "design-system", P + "state-machine", P + "accessibility-per-component"]),
    (lambda c: _kind(c) == "design" and re.search(r"motion|sound|haptic|animation", _t(c)), [P + "motion-system", P + "design-motion-principles", P + "microinteractions"]),
    (lambda c: _kind(c) == "design" and re.search(r"copy|voice|tone of voice|strings", _t(c)), [P + "ux-writing", P + "antislop-copywriting", P + "localization-design"]),
    (lambda c: _kind(c) == "design" and re.search(r"wireflow|navigation|hub", _t(c)), [P + "navigation-patterns", P + "information-architecture", P + "user-flow-diagram"]),
    (lambda c: _kind(c) == "design" and re.search(r"usability|protocol|test", _t(c)), [P + "test-scenario", P + "click-test-plan", P + "accessibility-test-plan"]),
    (lambda c: _kind(c) == "design" and re.search(r"onboarding", _t(c)), [P + "onboarding-design", P + "onboarding-ux"]),
    (lambda c: _kind(c) == "design" and re.search(r"avatar|rive|persona", _t(c)), [P + "rive", P + "illustration-style", P + "conversational-ux"]),
    (lambda c: _kind(c) == "design", [P + "mobile-app-ui-design", P + "design-critique"]),
    # ADRs and epics
    (lambda c: _kind(c) == "adr", [A + "10-analysis-and-decision-support", P + "diagram-design"]),
    (lambda c: _kind(c) == "epic", [A + "13-agent-teams", A + "06-execution-and-verification"]),
    (lambda c: _kind(c) == "verification", [A + "07-research-and-fact-checking", A + "06-execution-and-verification"]),
    (lambda c: _kind(c) == "external", [A + "09-writing-and-communication"]),
    # feature cards (user-facing elevation) — by hub / tags
    (lambda c: _kind(c) == "feature" and "under18_social" in _tags(c), [P + "mobile-app-ui-design", P + "error-handling-ux", A + "14-safety-and-high-stakes"]),
    (lambda c: _kind(c) == "feature" and re.search(r"game|duel|arcade|quiz|ludo|whot|ayo|relay|drum|chain", _t(c)), [P + "mobile-app-ui-design", P + "microinteractions", P + "feedback-patterns"]),
    (lambda c: _kind(c) == "feature" and re.search(r"streak|goal|reminder|league|badge|xp|gift|quest", _t(c)), [P + "mobile-app-ui-design", P + "hooked-ux", P + "feedback-patterns"]),
    (lambda c: _kind(c) == "feature" and re.search(r"chat|tutor|polie|conversation|persona|coach", _t(c)), [P + "conversational-ux", P + "mobile-app-ui-design", P + "error-handling-ux"]),
    (lambda c: _kind(c) == "feature" and re.search(r"onboarding|placement|first", _t(c)), [P + "onboarding-ux", P + "mobile-app-ui-design"]),
    (lambda c: _kind(c) == "feature" and re.search(r"setting|privacy|subscription|plan|profile|about|policy", _t(c)), [P + "form-design", P + "mobile-app-ui-design", P + "ux-writing"]),
    (lambda c: _kind(c) == "feature", [P + "mobile-app-ui-design", P + "feedback-patterns", P + "error-handling-ux"]),
    # build cards: user-facing UI
    (lambda c: _kind(c) == "build" and c.get("user_facing") and re.search(r"theme|token|colou?r|font|typograph", _t(c)), [P + "token-compliance", P + "theme-audit", P + "typography-scale"]),
    (lambda c: _kind(c) == "build" and c.get("user_facing") and re.search(r"motion|animation|celebrat|haptic|rive|avatar", _t(c)), [P + "motion-system", P + "rive", P + "animation-principles"]),
    (lambda c: _kind(c) == "build" and c.get("user_facing") and re.search(r"a11y|accessib|semantic|reduced motion|200%", _t(c)), [P + "accessibility", P + "fixing-accessibility"]),
    (lambda c: _kind(c) == "build" and c.get("user_facing") and re.search(r"onboarding", _t(c)), [P + "onboarding-ux", P + "form-design"]),
    (lambda c: _kind(c) == "build" and c.get("user_facing") and re.search(r"state|empty|error|offline|skeleton", _t(c)), [P + "error-handling-ux", P + "feedback-patterns", P + "state-machine"]),
    (lambda c: _kind(c) == "build" and c.get("user_facing") and re.search(r"copy|arb|translat|string|i18n|locali", _t(c)), [P + "ux-writing", P + "localization-design"]),
    (lambda c: _kind(c) == "build" and c.get("user_facing") and re.search(r"nav|tab|shell|route|hub", _t(c)), [P + "navigation-patterns", P + "mobile-app-ui-design"]),
    (lambda c: _kind(c) == "build" and c.get("user_facing"), [P + "mobile-app-ui-design", P + "feedback-patterns"]),
    # build cards: non-UI
    (lambda c: _kind(c) == "build" and (c.get("p0_area") or c.get("security_dsp_crypto") or re.search(r"secret|auth|token|jwt|moderat|csam|guardian|minor|payment|webhook|credential|encrypt|e2ee|pii|privacy", _t(c))), [A + "14-safety-and-high-stakes", A + "08-coding-and-debugging"]),
    (lambda c: _kind(c) == "build" and re.search(r"eval|scorer|calibrat|benchmark|dataset|metric", _t(c)), [A + "11-data-and-quantitative-work", A + "07-research-and-fact-checking"]),
    (lambda c: _kind(c) == "build" and re.search(r"persona|dialogue|tutor|prompt", _t(c)), [P + "conversational-ux", A + "08-coding-and-debugging"]),
    (lambda c: _kind(c) == "build", [A + "08-coding-and-debugging"]),
]

# reviewer add-on for cards that produce visual evidence
VISUAL_REVIEW = [P + "critique-visual-hierarchy", P + "critique-typography", P + "design-to-code-check"]


def assign(c: dict) -> dict:
    skills: list[str] = []
    for pred, sk in RULES:
        if pred(c):
            for s in sk:
                if s not in skills and len(skills) < 3:
                    skills.append(s)
            break
    out = {"worker": skills}
    if c.get("visual_evidence_required"):
        out["reviewer_extra"] = VISUAL_REVIEW
    return out


def main(write: bool) -> int:
    n = 0
    for p in sorted(CARDS.rglob("*.yaml")):
        c = yaml.safe_load(p.read_text())
        new = assign(c)
        if c.get("skills") != new:
            c["skills"] = new
            if write:
                p.write_text(yaml.safe_dump(c, sort_keys=False, allow_unicode=True, width=120))
            n += 1
    print(f"assign_skills: {'updated' if write else 'would update'} {n} card(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main(write="--write" in sys.argv))
