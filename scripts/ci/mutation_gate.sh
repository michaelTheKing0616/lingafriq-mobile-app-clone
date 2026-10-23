#!/usr/bin/env bash
# charter: v2
# FSRS mutation gate. The score floor is 80 percent. A lower yaml threshold cannot weaken it.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
export MUTATION_ROOT="$root"
exec python3 - "$@" <<'PY'
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

FLOOR = 0.80
MIN_COUNTED = 20
ROOT = Path(os.environ["MUTATION_ROOT"])
GEN = ROOT / "test" / "learning" / "mutation_run"
BUILTIN_TYPES = {
    "int", "double", "num", "bool", "void", "dynamic", "var", "final",
    "List", "Map", "Set", "Future", "Stream", "Iterable", "String",
    "Duration", "Object", "Null",
}
NUMBER = re.compile(r"(?<![A-Za-z0-9_])\d[\d_]*(?:\.\d[\d_]*)?(?:[eE][+-]?\d+)?")
WORD = re.compile(r"(?<![A-Za-z0-9_])(true|false)(?![A-Za-z0-9_])")


class Mutant:
    def __init__(self, index, start, end, old, new, line, col):
        self.index = index
        self.start = start
        self.end = end
        self.old = old
        self.new = new
        self.line = line
        self.col = col

    def apply(self, source):
        if source[self.start:self.end] != self.old:
            raise SystemExit(f"mutant {self.index} no longer matches the scheduler")
        return source[:self.start] + self.new + source[self.end:]

    def describe(self, module):
        shown = self.new if self.new != "" else "deleted"
        return f"{module}:{self.line}:{self.col} {self.old!r} -> {shown!r}"


def unquote(value):
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
        return value[1:-1]
    return value


def split_kv(line):
    if ":" not in line:
        raise SystemExit(f"bad yaml line: {line}")
    key, value = line.split(":", 1)
    return unquote(key.strip()), value.strip()


def parse_yaml(text):
    lines = text.splitlines()
    data = {}
    index = 0
    while index < len(lines):
        raw = lines[index]
        if not raw.strip() or raw.strip().startswith("#"):
            index += 1
            continue
        if raw[0].isspace():
            raise SystemExit(f"yaml value outside a block: {raw}")
        key, value = split_kv(raw)
        if value != "":
            data[key] = unquote(value)
            index += 1
            continue
        look = index + 1
        while look < len(lines) and not lines[look].strip():
            look += 1
        if look < len(lines) and lines[look].strip().startswith("- "):
            items = []
            index += 1
            while index < len(lines) and lines[index].strip().startswith("- "):
                items.append(unquote(lines[index].strip()[2:]))
                index += 1
            data[key] = items
            continue
        block = {}
        index += 1
        while index < len(lines) and lines[index].startswith("  ") and lines[index].strip():
            item_key, item_value = split_kv(lines[index].strip())
            block[item_key] = unquote(item_value)
            index += 1
        data[key] = block
    return data


def load_config():
    path = ROOT / "tool" / "mutation" / "fsrs_mutation.yaml"
    config = parse_yaml(path.read_text())
    for key in ("module", "tests", "replace", "literals"):
        if key not in config:
            raise SystemExit(f"fsrs_mutation.yaml is missing {key}")
    raw = float(config.get("threshold", FLOOR))
    config["threshold"] = raw if raw > FLOOR else FLOOR
    config["module_path"] = ROOT / config["module"]
    if not config["module_path"].is_file():
        raise SystemExit(f"missing module {config['module']}")
    return config


def mask_non_code(source):
    chars = list(source)
    length = len(chars)
    index = 0

    def blank(start, end):
        for cursor in range(start, end):
            if chars[cursor] != "\n":
                chars[cursor] = " "

    while index < length:
        if chars[index] == "/" and index + 1 < length and chars[index + 1] == "/":
            end = index
            while end < length and chars[end] != "\n":
                end += 1
            blank(index, end)
            index = end
            continue
        if chars[index] == "/" and index + 1 < length and chars[index + 1] == "*":
            end = index + 2
            while end + 1 < length and not (chars[end] == "*" and chars[end + 1] == "/"):
                end += 1
            end = min(length, end + 2)
            blank(index, end)
            index = end
            continue
        if chars[index] in ("'", '"'):
            quote = chars[index]
            if index + 2 < length and chars[index + 1] == quote and chars[index + 2] == quote:
                end = index + 3
                while end + 2 < length and not (
                    chars[end] == quote and chars[end + 1] == quote and chars[end + 2] == quote
                ):
                    end += 1
                end = min(length, end + 3)
                blank(index, end)
                index = end
                continue
            end = index + 1
            while end < length and chars[end] != quote:
                if chars[end] == "\\":
                    end += 2
                    continue
                if chars[end] == "\n":
                    break
                end += 1
            end = min(length, end + 1)
            blank(index, end)
            index = end
            continue
        index += 1
    return "".join(chars)


def mask_numbers(masked):
    chars = list(masked)
    for match in NUMBER.finditer(masked):
        for cursor in range(match.start(), match.end()):
            if chars[cursor] != "\n":
                chars[cursor] = " "
    return "".join(chars)


def previous_identifier(masked, index):
    cursor = index - 1
    while cursor >= 0 and masked[cursor].isspace():
        cursor -= 1
    if cursor < 0 or not (masked[cursor].isalnum() or masked[cursor] == "_"):
        return ""
    end = cursor + 1
    while cursor >= 0 and (masked[cursor].isalnum() or masked[cursor] == "_"):
        cursor -= 1
    return masked[cursor + 1:end]


def left_is_operand(masked, index):
    cursor = index - 1
    while cursor >= 0 and masked[cursor].isspace():
        cursor -= 1
    return cursor >= 0 and (masked[cursor].isalnum() or masked[cursor] in "_)]")


def line_col(source, index):
    line = source.count("\n", 0, index) + 1
    previous = source.rfind("\n", 0, index)
    return line, index - previous


def build_mutants(source, config):
    comment_masked = mask_non_code(source)
    operator_masked = mask_numbers(comment_masked)
    replace = config["replace"]
    operators = sorted(replace, key=len, reverse=True)
    found = []
    index = 0
    while index < len(operator_masked):
        matched = None
        for operator in operators:
            if operator_masked.startswith(operator, index):
                matched = operator
                break
        if matched is None:
            index += 1
            continue
        end = index + len(matched)
        if matched in ("<", ">"):
            previous = previous_identifier(comment_masked, index)
            if previous[:1].isupper() or previous in BUILTIN_TYPES:
                index = end
                continue
        unary = matched == "-" and not left_is_operand(comment_masked, index)
        if unary:
            if config.get("unary_minus") == "drop":
                found.append((index, end, matched, ""))
            index = end
            continue
        if matched in ("+", "-", "*", "/", "<", ">", "<=", ">=", "==", "!=", "&&", "||"):
            if not left_is_operand(comment_masked, index):
                index = end
                continue
        found.append((index, end, matched, replace[matched]))
        index = end

    occupied = [(start, end) for start, end, _old, _new in found]
    literals = config["literals"]

    def free(start, end):
        return all(end <= left or start >= right for left, right in occupied)

    for match in NUMBER.finditer(source):
        if comment_masked[match.start():match.end()].strip() == "":
            continue
        token = match.group(0)
        if token in literals and free(match.start(), match.end()):
            found.append((match.start(), match.end(), token, literals[token]))
    for match in WORD.finditer(source):
        if comment_masked[match.start():match.end()].strip() == "":
            continue
        token = match.group(1)
        if token in literals and free(match.start(), match.end()):
            found.append((match.start(), match.end(), token, literals[token]))

    found.sort(key=lambda item: item[0])
    mutants = []
    for start, end, old, new in found:
        if source[start:end] != old or new == old:
            continue
        line, col = line_col(source, start)
        mutants.append(Mutant(len(mutants), start, end, old, new, line, col))
    return mutants


def ratio_passes(killed, counted, threshold):
    if counted <= 0:
        return False
    return (killed / counted) + 1e-12 >= threshold


def effective_passes(killed, counted, threshold):
    return counted >= MIN_COUNTED and ratio_passes(killed, counted, threshold)


def self_test(config, source, mutants):
    if len(mutants) < MIN_COUNTED:
        raise SystemExit(f"self-test expected at least {MIN_COUNTED} mutants, found {len(mutants)}")
    if config["threshold"] < FLOOR:
        raise SystemExit("threshold dropped below the 80 percent floor")
    if not ratio_passes(8, 10, FLOOR):
        raise SystemExit("80 percent must pass")
    if ratio_passes(7, 10, FLOOR):
        raise SystemExit("70 percent must fail")
    if effective_passes(19, 19, FLOOR):
        raise SystemExit("fewer than 20 counted mutants must fail")
    applied = [mutant.apply(source) for mutant in mutants]
    if not any("elapsedDays <= 0" in text for text in applied):
        raise SystemExit("self-test did not build the elapsedDays boundary mutant")
    if any(mutant.old == "1e-9" or mutant.new == "1e-9" for mutant in mutants):
        raise SystemExit("self-test mutated inside the 1e-9 literal")
    for mutant in mutants:
        if 5 <= mutant.line <= 9:
            raise SystemExit(f"self-test mutated a comment: {mutant.describe(config['module'])}")
        if mutant.old == "<":
            previous = previous_identifier(mask_numbers(mask_non_code(source)), mutant.start)
            if previous[:1].isupper() or previous in BUILTIN_TYPES:
                raise SystemExit(f"self-test mutated a generic: {mutant.describe(config['module'])}")
    before = hashlib.sha256(source.encode()).hexdigest()
    after = hashlib.sha256(config["module_path"].read_text().encode()).hexdigest()
    if before != after:
        raise SystemExit("self-test changed the scheduler on disk")


def flutter_bin():
    override = os.environ.get("FLUTTER_BIN")
    if override:
        return override
    found = shutil.which("flutter")
    if found:
        return found
    fallback = Path("/Users/temitopeolaitanmichael/flutter/bin/flutter")
    if fallback.exists():
        return str(fallback)
    raise SystemExit("flutter is not on PATH")


def write_generated(source, config, mutants):
    if GEN.exists():
        shutil.rmtree(GEN)
    GEN.mkdir(parents=True)
    for mutant in mutants:
        text = mutant.apply(source)
        text = text.replace(
            "import 'memory_state.dart';",
            "import 'package:lingafriq/services/learning/memory_state.dart';",
            1,
        )
        header = f"// Generated mutant {mutant.index:03d} for the FSRS mutation gate.\n"
        (GEN / f"mutant_{mutant.index:03d}.dart").write_text(header + text)
    imports = [
        "import 'package:flutter_test/flutter_test.dart';",
        "import 'package:lingafriq/services/learning/fsrs6_scheduler.dart' as real;",
        "import '../fsrs6_oracle.dart';",
    ]
    for mutant in mutants:
        imports.append(f"import 'mutant_{mutant.index:03d}.dart' as m{mutant.index:03d};")
    body = ["", "void main() {", "  test('baseline', () {", calls("real"), "  });"]
    for mutant in mutants:
        prefix = f"m{mutant.index:03d}"
        body.append(f"  test('mutant-{mutant.index:03d}', () {{")
        body.append(calls(prefix))
        body.append("  }, timeout: const Timeout(Duration(seconds: 20)));")
    body.append("}")
    body.append("")
    (GEN / "gate_test.dart").write_text("\n".join(imports + body))


def calls(prefix):
    return "\n".join([
        f"    verifyFsrs6({prefix}.Fsrs6Scheduler());",
        f"    verifyFsrs6OneStep({prefix}.Fsrs6Scheduler(learningSteps: const [Duration(minutes: 5)]));",
        f"    verifyFsrs6Days({prefix}.Fsrs6Scheduler.days());",
        f"    verifyFsrs6Rounding({prefix}.pythonRound);",
        f"    verifyFsrs6Ease({prefix}.Fsrs6Scheduler.difficultyFromEase, {prefix}.Fsrs6Scheduler.easeFromDifficulty);",
    ])


def cleanup():
    if GEN.exists() and GEN.name == "mutation_run":
        shutil.rmtree(GEN)


def run_flutter(paths):
    command = [flutter_bin(), "test", "--reporter", "json", "--no-pub", *paths]
    print("running " + " ".join(paths), flush=True)
    completed = subprocess.run(
        command,
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=1800,
        check=False,
    )
    return completed.returncode, completed.stdout


def parse_results(output):
    names = {}
    results = {}
    for line in output.splitlines():
        stripped = line.strip()
        if not stripped.startswith("{"):
            continue
        try:
            event = json.loads(stripped)
        except json.JSONDecodeError:
            continue
        kind = event.get("type")
        if kind == "testStart":
            test = event.get("test") or {}
            names[test.get("id")] = test.get("name", "")
        elif kind == "testDone" and not event.get("hidden"):
            name = names.get(event.get("testID"), "")
            results[name] = event.get("result")
    return results


def compile_errors(output):
    return sorted(set(re.findall(r"mutant_(\d+)\.dart", output)))


def run_gate(config, source, mutants):
    alive = list(mutants)
    stillborn = []
    output = ""
    results = {}
    for _attempt in range(8):
        if len(alive) < MIN_COUNTED:
            raise SystemExit("not enough mutants left after compile failures")
        write_generated(source, config, alive)
        unit_tests = [str(ROOT / path) for path in config["tests"]]
        code, output = run_flutter([*unit_tests, str(GEN / "gate_test.dart")])
        results = parse_results(output)
        mutant_names = [name for name in results if "mutant-" in name]
        if mutant_names:
            break
        broken = compile_errors(output)
        if not broken:
            tail = "\n".join(output.splitlines()[-60:])
            raise SystemExit("mutation suite did not run\n" + tail)
        broken_ids = {int(item) for item in broken}
        print(f"stillborn: {sorted(broken_ids)}", flush=True)
        stillborn.extend(mutant for mutant in alive if mutant.index in broken_ids)
        alive = [mutant for mutant in alive if mutant.index not in broken_ids]
    else:
        raise SystemExit("mutation suite still does not compile")

    failures = []
    for name, result in results.items():
        if "mutant-" in name:
            continue
        if result != "success":
            failures.append(f"{name}: {result}")
    if failures:
        tail = "\n".join(output.splitlines()[-40:])
        raise SystemExit("FSRS tests failed before a score could be trusted\n" + "\n".join(failures) + "\n" + tail)

    survived = []
    killed = 0
    seen = set()
    for mutant in alive:
        matches = [name for name in results if f"mutant-{mutant.index:03d}" in name]
        if len(matches) != 1:
            raise SystemExit(f"missing result for mutant {mutant.index:03d}")
        seen.add(mutant.index)
        if results[matches[0]] == "success":
            survived.append(mutant)
        elif results[matches[0]] in ("failure", "error"):
            killed += 1
        else:
            raise SystemExit(f"unexpected result for mutant {mutant.index:03d}: {results[matches[0]]}")
    if seen != {mutant.index for mutant in alive}:
        raise SystemExit("mutant results did not cover the run")
    counted = killed + len(survived)
    ratio = killed / counted
    print(f"mutation score: {killed}/{counted} = {ratio:.4f}")
    print(f"threshold: {config['threshold']:.2f}")
    print(f"killed: {killed}")
    print(f"survived: {len(survived)}")
    print(f"stillborn: {len(stillborn)}")
    if survived:
        print("survivors:")
        for mutant in survived:
            print(mutant.describe(config["module"]))
    else:
        print("survivors: none")
    for mutant in stillborn:
        print(f"stillborn {mutant.describe(config['module'])}")
    if not effective_passes(killed, counted, config["threshold"]):
        raise SystemExit("mutation score is below the floor")
    return 0


def main():
    config = load_config()
    source = config["module_path"].read_text()
    mutants = build_mutants(source, config)
    if "--list" in sys.argv[1:]:
        for mutant in mutants:
            print(mutant.describe(config["module"]))
        print(f"{len(mutants)} mutants")
        return 0
    self_test(config, source, mutants)
    if "--self-test" in sys.argv[1:]:
        print("self-test passed")
        return 0
    try:
        return run_gate(config, source, mutants)
    finally:
        cleanup()
        if hashlib.sha256(config["module_path"].read_text().encode()).hexdigest() != hashlib.sha256(source.encode()).hexdigest():
            config["module_path"].write_text(source)
            raise SystemExit("the scheduler was modified and has been restored")


if __name__ == "__main__":
    try:
        sys.exit(main())
    except subprocess.TimeoutExpired:
        cleanup()
        raise SystemExit("mutation run timed out")
PY
