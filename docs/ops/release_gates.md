charter: v2

# Release gates

A staged rollout stops when either line is crossed:

- crash-free users below 0.995
- ANR rate above 0.0047

`scripts/ci/crash_gate.py` reads a JSON report with `crash_free_users` and `anr_rate` and exits 1 when promotion is blocked. The report comes from the store metrics for that rollout stage. The script does not invent those numbers.

Crash reports carry the release and the operating system. Email addresses and bearer tokens are removed before the report is logged.
