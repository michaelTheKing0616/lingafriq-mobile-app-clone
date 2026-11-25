#!/usr/bin/env python3
"""Calibrate 2PL item parameters from pilot responses.

The model is the logistic 2PL, P(correct | theta) = 1 / (1 + exp(-a * (theta - b))).
The person distribution is standard normal, so difficulty stays on that scale.
An item with fewer than min_responses unique persons, or with no variance, stays
uncalibrated. Scoring must ignore those rows.

Fit is the root-mean-square residual of each response against the model
probability at that person's EAP ability. It is null when the item is not calibrated.
"""

from __future__ import annotations

import json
import math
import sys
from collections import defaultdict

MIN_RESPONSES = 200
QUAD_POINTS = 21
EM_ITERATIONS = 40
A_MIN = 0.25
A_MAX = 3.0
B_MIN = -4.0
B_MAX = 4.0


def sigmoid(x: float) -> float:
    if x >= 0:
        z = math.exp(-x)
        return 1.0 / (1.0 + z)
    z = math.exp(x)
    return z / (1.0 + z)


def standard_normal_quadrature(count: int) -> tuple[list[float], list[float]]:
    """Gauss-Hermite nodes and weights for a standard normal integral."""
    if count < 1:
        raise ValueError("quadrature count must be positive")
    matrix = [[0.0] * count for _ in range(count)]
    for index in range(count - 1):
        off = math.sqrt(index + 1)
        matrix[index][index + 1] = off
        matrix[index + 1][index] = off
    values, vectors = _jacobi(matrix)
    order = sorted(range(count), key=lambda index: values[index])
    nodes = [values[index] for index in order]
    weights = [vectors[0][index] ** 2 for index in order]
    total = sum(weights)
    if total <= 0:
        raise RuntimeError("quadrature weights collapsed")
    return nodes, [weight / total for weight in weights]


def _jacobi(matrix: list[list[float]]) -> tuple[list[float], list[list[float]]]:
    count = len(matrix)
    vectors = [[1.0 if row == col else 0.0 for col in range(count)] for row in range(count)]
    for _ in range(count * 8):
        off = 0.0
        for left in range(count):
            for right in range(left + 1, count):
                off += matrix[left][right] ** 2
        if off < 1e-24:
            break
        for left in range(count):
            for right in range(left + 1, count):
                coupling = matrix[left][right]
                if abs(coupling) < 1e-18:
                    continue
                diag_left = matrix[left][left]
                diag_right = matrix[right][right]
                tau = (diag_right - diag_left) / (2.0 * coupling)
                if tau >= 0:
                    tangent = 1.0 / (tau + math.sqrt(1.0 + tau * tau))
                else:
                    tangent = -1.0 / (-tau + math.sqrt(1.0 + tau * tau))
                cosine = 1.0 / math.sqrt(1.0 + tangent * tangent)
                sine = tangent * cosine
                matrix[left][left] = diag_left - tangent * coupling
                matrix[right][right] = diag_right + tangent * coupling
                matrix[left][right] = 0.0
                matrix[right][left] = 0.0
                for row in range(count):
                    if row == left or row == right:
                        continue
                    left_value = matrix[row][left]
                    right_value = matrix[row][right]
                    matrix[row][left] = cosine * left_value - sine * right_value
                    matrix[left][row] = matrix[row][left]
                    matrix[row][right] = sine * left_value + cosine * right_value
                    matrix[right][row] = matrix[row][right]
                for row in range(count):
                    left_value = vectors[row][left]
                    right_value = vectors[row][right]
                    vectors[row][left] = cosine * left_value - sine * right_value
                    vectors[row][right] = sine * left_value + cosine * right_value
    return [matrix[index][index] for index in range(count)], vectors


def _as_bit(value: object) -> int:
    if value is True or value == 1:
        return 1
    if value is False or value == 0:
        return 0
    raise ValueError("correct must be boolean")


def _dedupe(responses: list[dict]) -> dict[str, dict[str, int]]:
    """Last response wins for a person and item."""
    by_item: dict[str, dict[str, int]] = defaultdict(dict)
    for row in responses:
        item_id = row.get("item_id")
        person_id = row.get("person_id")
        if not isinstance(item_id, str) or not item_id:
            raise ValueError("item_id is required")
        if not isinstance(person_id, str) or not person_id:
            raise ValueError("person_id is required")
        by_item[item_id][person_id] = _as_bit(row.get("correct"))
    return by_item


def _empty_row(item_id: str, sample_size: int) -> dict:
    return {
        "item_id": item_id,
        "sample_size": sample_size,
        "fit": None,
        "calibrated": False,
        "a": None,
        "b": None,
    }


def parameters_for_scoring(row: dict) -> dict | None:
    if row.get("calibrated") is not True:
        return None
    a = row.get("a")
    b = row.get("b")
    if not isinstance(a, (int, float)) or not isinstance(b, (int, float)):
        return None
    if a <= 0 or not math.isfinite(a) or not math.isfinite(b):
        return None
    return {"a": float(a), "b": float(b)}


def calibrate(responses: list[dict], min_responses: int = MIN_RESPONSES) -> dict:
    if min_responses < 1:
        raise ValueError("min_responses must be at least 1")
    by_item = _dedupe(responses)
    kept: dict[str, dict[str, int]] = {}
    report_rows: dict[str, dict] = {}
    for item_id, persons in by_item.items():
        sample_size = len(persons)
        correct = sum(persons.values())
        if sample_size < min_responses or correct == 0 or correct == sample_size:
            report_rows[item_id] = _empty_row(item_id, sample_size)
            continue
        kept[item_id] = persons

    if not kept:
        return {"items": [report_rows[item_id] for item_id in sorted(report_rows)]}

    item_ids = sorted(kept)
    nodes, weights = standard_normal_quadrature(QUAD_POINTS)
    quad = len(nodes)
    log_weights = [math.log(weight) for weight in weights]
    answers: list[list[tuple[int, int]]] = []
    person_index: dict[str, int] = {}
    item_persons: list[list[tuple[int, int]]] = []
    for item_id in item_ids:
        pairs: list[tuple[int, int]] = []
        for person_id, correct in kept[item_id].items():
            index = person_index.get(person_id)
            if index is None:
                index = len(answers)
                person_index[person_id] = index
                answers.append([])
            answers[index].append((len(item_persons), correct))
            pairs.append((index, correct))
        item_persons.append(pairs)

    difficulty = []
    discrimination = []
    for pairs in item_persons:
        proportion = sum(correct for _, correct in pairs) / len(pairs)
        proportion = min(0.98, max(0.02, proportion))
        difficulty.append(-math.log(proportion / (1.0 - proportion)))
        discrimination.append(1.0)

    person_count = len(answers)
    posterior = [[0.0] * quad for _ in range(person_count)]
    for _ in range(EM_ITERATIONS):
        previous = list(zip(discrimination, difficulty))
        log_p = []
        log_q = []
        for item in range(len(item_ids)):
            item_log_p = []
            item_log_q = []
            a = discrimination[item]
            b = difficulty[item]
            for node in nodes:
                probability = min(1.0 - 1e-12, max(1e-12, sigmoid(a * (node - b))))
                item_log_p.append(math.log(probability))
                item_log_q.append(math.log(1.0 - probability))
            log_p.append(item_log_p)
            log_q.append(item_log_q)

        for person, rows in enumerate(answers):
            log_post = []
            for point in range(quad):
                total = log_weights[point]
                for item, correct in rows:
                    total += log_p[item][point] if correct else log_q[item][point]
                log_post.append(total)
            peak = max(log_post)
            scaled = [math.exp(value - peak) for value in log_post]
            scale = sum(scaled)
            posterior[person] = [value / scale for value in scaled]

        largest_shift = 0.0
        for item in range(len(item_ids)):
            expected_n = [0.0] * quad
            expected_r = [0.0] * quad
            for person, correct in item_persons[item]:
                for point in range(quad):
                    mass = posterior[person][point]
                    expected_n[point] += mass
                    if correct:
                        expected_r[point] += mass
            new_a, new_b = _fisher(discrimination[item], difficulty[item], nodes, expected_n, expected_r)
            largest_shift = max(
                largest_shift,
                abs(new_a - discrimination[item]),
                abs(new_b - difficulty[item]),
            )
            discrimination[item] = new_a
            difficulty[item] = new_b
        if largest_shift < 0.005 and previous:
            break

    eap = []
    for person in range(person_count):
        eap.append(sum(posterior[person][point] * nodes[point] for point in range(quad)))

    for item, item_id in enumerate(item_ids):
        pairs = item_persons[item]
        squared = 0.0
        for person, correct in pairs:
            probability = sigmoid(discrimination[item] * (eap[person] - difficulty[item]))
            residual = correct - probability
            squared += residual * residual
        report_rows[item_id] = {
            "item_id": item_id,
            "sample_size": len(kept[item_id]),
            "fit": math.sqrt(squared / len(pairs)),
            "calibrated": True,
            "a": discrimination[item],
            "b": difficulty[item],
        }
    return {"items": [report_rows[item_id] for item_id in sorted(report_rows)]}


def _fisher(
    a: float,
    b: float,
    nodes: list[float],
    expected_n: list[float],
    expected_r: list[float],
) -> tuple[float, float]:
    def loglik(next_a: float, next_b: float) -> float:
        total = 0.0
        for point, node in enumerate(nodes):
            count = expected_n[point]
            if count <= 0:
                continue
            probability = min(1.0 - 1e-12, max(1e-12, sigmoid(next_a * (node - next_b))))
            correct = expected_r[point]
            total += correct * math.log(probability) + (count - correct) * math.log(1.0 - probability)
        return total

    for _ in range(12):
        score_a = 0.0
        score_b = 0.0
        info_aa = 1e-4
        info_bb = 1e-4
        info_ab = 0.0
        for point, node in enumerate(nodes):
            count = expected_n[point]
            if count <= 0:
                continue
            probability = min(1.0 - 1e-12, max(1e-12, sigmoid(a * (node - b))))
            residual = expected_r[point] - count * probability
            distance = node - b
            score_a += residual * distance
            score_b += residual * (-a)
            information = count * probability * (1.0 - probability)
            info_aa += information * distance * distance
            info_bb += information * a * a
            info_ab += information * distance * (-a)
        determinant = info_aa * info_bb - info_ab * info_ab
        if determinant <= 1e-12:
            break
        step_a = (info_bb * score_a - info_ab * score_b) / determinant
        step_b = (info_aa * score_b - info_ab * score_a) / determinant
        current = loglik(a, b)
        accepted = False
        scale = 1.0
        while scale >= 1.0 / 64.0:
            trial_a = min(A_MAX, max(A_MIN, a + scale * step_a))
            trial_b = min(B_MAX, max(B_MIN, b + scale * step_b))
            if loglik(trial_a, trial_b) >= current - 1e-9:
                a, b = trial_a, trial_b
                accepted = True
                break
            scale *= 0.5
        if not accepted or (abs(scale * step_a) < 1e-4 and abs(scale * step_b) < 1e-4):
            break
    return a, b


def main() -> int:
    raw = sys.stdin.read()
    if not raw.strip():
        print("pilot responses are required", file=sys.stderr)
        return 2
    try:
        payload = json.loads(raw)
        responses = payload["responses"]
        minimum = int(payload.get("min_responses", MIN_RESPONSES))
        if not isinstance(responses, list):
            raise ValueError("responses must be a list")
        result = calibrate(responses, minimum)
    except (KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
        print(str(error), file=sys.stderr)
        return 2
    json.dump(result, sys.stdout)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
