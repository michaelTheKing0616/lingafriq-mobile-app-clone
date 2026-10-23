"""The exercise item schema stores type, stimulus, answer rules, IRT, and skill tags."""

from __future__ import annotations

import json
import unittest
from pathlib import Path

from jsonschema import Draft202012Validator
from jsonschema.exceptions import ValidationError

ROOT = Path(__file__).resolve().parents[2]
SCHEMA = json.loads((ROOT / "content" / "schema" / "item.v1.json").read_text(encoding="utf-8"))
VALIDATOR = Draft202012Validator(SCHEMA)


def item(**overrides: object) -> dict:
    body = {
        "id": "yo.item.tone.aar",
        "language": "yo",
        "type": "multiple_choice",
        "stimulus": {"refs": ["audio/yo/aar.ogg"], "text": "àárọ̀"},
        "answer": {
            "correct": "àárọ̀",
            "variants": ["aaro"],
            "matching": {"diacritic_insensitive": True},
        },
        "distractors": [
            {"text": "ọkọ̀", "rationale": "That word is a vehicle, not morning."},
        ],
        "irt": {"a": 1.2, "b": -0.4},
        "skill_tags": ["yo.lex.aaro.morning"],
        "review": {"status": "approved"},
    }
    body.update(overrides)
    return body


def fails(document: dict) -> list[ValidationError]:
    return list(VALIDATOR.iter_errors(document))


class ItemSchemaTest(unittest.TestCase):
    def test_schema_itself_is_valid(self) -> None:
        Draft202012Validator.check_schema(SCHEMA)

    def test_a_complete_item_stores_the_bank_fields(self) -> None:
        self.assertEqual(fails(item()), [])
        stored = item()
        self.assertIn("diacritic_insensitive", stored["answer"]["matching"])
        self.assertEqual(stored["irt"]["a"], 1.2)
        self.assertEqual(stored["skill_tags"], ["yo.lex.aaro.morning"])

    def test_a_missing_distractor_rationale_fails(self) -> None:
        broken = item()
        broken["distractors"] = [{"text": "ọkọ̀"}]
        messages = [error.message for error in fails(broken)]
        self.assertTrue(any("rationale" in message for message in messages))

    def test_multiple_choice_without_distractors_fails(self) -> None:
        broken = item()
        del broken["distractors"]
        self.assertTrue(fails(broken))

    def test_a_draft_is_stored_and_stays_unapproved(self) -> None:
        draft = item(review={"status": "draft"})
        self.assertEqual(fails(draft), [])
        self.assertEqual(draft["review"]["status"], "draft")

    def test_missing_irt_or_skill_tags_fail(self) -> None:
        missing_irt = item()
        del missing_irt["irt"]
        missing_tags = item(skill_tags=[])
        self.assertTrue(fails(missing_irt))
        self.assertTrue(fails(missing_tags))


if __name__ == "__main__":
    unittest.main()
