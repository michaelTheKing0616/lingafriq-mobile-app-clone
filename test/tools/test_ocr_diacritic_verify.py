import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "tools/lens/ocr_diacritic_verify.py"


def test_aggregate_fixture_ledger_reports_high_mark_loss():
    out = subprocess.check_output(
        [sys.executable, str(SCRIPT)],
        cwd=REPO,
        text=True,
    )
    summary = json.loads(out)
    assert summary["overall_mean_per_mark_error_rate"] >= 0.8
    assert summary["by_language"]["yo"]["mean_per_mark_error_rate"] >= 0.9
    assert summary["by_platform"]["ios"]["fixture_count"] == 6


def test_per_mark_rate_for_stripped_yoruba_minimal_pair():
    code = """
import json
from tools.lens.ocr_diacritic_verify import per_mark_error_rate
print(json.dumps(per_mark_error_rate("ọkọ́", "Oko")))
"""
    out = subprocess.check_output(
        [sys.executable, "-c", code],
        cwd=REPO,
        text=True,
    )
    stats = json.loads(out)
    assert stats["reference_marks"] >= 2
    assert stats["per_mark_error_rate"] == 1.0
