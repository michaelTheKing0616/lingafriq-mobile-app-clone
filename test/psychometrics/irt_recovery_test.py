import math
import random
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "psychometrics"))

from calibrate_irt import MIN_RESPONSES, calibrate, parameters_for_scoring, standard_normal_quadrature


def _normal(rng: random.Random) -> float:
    return math.sqrt(-2.0 * math.log(rng.random())) * math.cos(2.0 * math.pi * rng.random())


def _sigmoid(x: float) -> float:
    if x >= 0:
        z = math.exp(-x)
        return 1.0 / (1.0 + z)
    z = math.exp(x)
    return z / (1.0 + z)


def _pearson(left: list[float], right: list[float]) -> float:
    count = len(left)
    mean_left = sum(left) / count
    mean_right = sum(right) / count
    numerator = sum((x - mean_left) * (y - mean_right) for x, y in zip(left, right))
    left_scale = math.sqrt(sum((x - mean_left) ** 2 for x in left))
    right_scale = math.sqrt(sum((y - mean_right) ** 2 for y in right))
    return numerator / (left_scale * right_scale)


class IrtRecoveryTest(unittest.TestCase):
    def test_quadrature_matches_a_standard_normal(self):
        nodes, weights = standard_normal_quadrature(21)
        mean = sum(weight * node for weight, node in zip(weights, nodes))
        variance = sum(weight * node * node for weight, node in zip(weights, nodes))
        self.assertAlmostEqual(sum(weights), 1.0, places=6)
        self.assertAlmostEqual(mean, 0.0, places=6)
        self.assertAlmostEqual(variance, 1.0, places=2)

    def test_recovered_difficulty_correlates_with_truth(self):
        rng = random.Random(20261023)
        truth = {}
        for index in range(12):
            truth[f"item-{index:02d}"] = (
                0.8 + (index % 5) * 0.25,
                -2.0 + 4.0 * index / 11.0,
            )
        responses = []
        for person in range(1000):
            ability = _normal(rng)
            for item_id, (discrimination, difficulty) in truth.items():
                probability = _sigmoid(discrimination * (ability - difficulty))
                responses.append(
                    {
                        "item_id": item_id,
                        "person_id": f"p{person}",
                        "correct": rng.random() < probability,
                    }
                )
        for person in range(12):
            responses.append(
                {
                    "item_id": "item-short",
                    "person_id": f"s{person}",
                    "correct": person % 2 == 0,
                }
            )

        report = calibrate(responses, MIN_RESPONSES)
        by_id = {row["item_id"]: row for row in report["items"]}
        recovered = []
        actual = []
        for item_id, (_, difficulty) in truth.items():
            row = by_id[item_id]
            self.assertEqual(row["sample_size"], 1000)
            self.assertIsInstance(row["fit"], float)
            self.assertGreaterEqual(row["fit"], 0.0)
            self.assertLessEqual(row["fit"], 1.0)
            self.assertTrue(row["calibrated"])
            self.assertIsNotNone(parameters_for_scoring(row))
            recovered.append(row["b"])
            actual.append(difficulty)

        short = by_id["item-short"]
        self.assertEqual(short["sample_size"], 12)
        self.assertFalse(short["calibrated"])
        self.assertIsNone(short["a"])
        self.assertIsNone(short["b"])
        self.assertIsNone(parameters_for_scoring(short))
        self.assertGreaterEqual(_pearson(recovered, actual), 0.9)

    def test_report_lists_fit_and_sample_size_for_every_item(self):
        responses = [
            {"item_id": "only", "person_id": f"p{index}", "correct": index % 3 != 0}
            for index in range(40)
        ]
        report = calibrate(responses, min_responses=30)
        self.assertEqual(len(report["items"]), 1)
        row = report["items"][0]
        self.assertIn("fit", row)
        self.assertEqual(row["sample_size"], 40)
        self.assertTrue(row["calibrated"])


if __name__ == "__main__":
    unittest.main()
