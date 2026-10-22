charter: v2

# Balance reconciliation runbook

## Divergence threshold

The threshold is **0**. Any stored XP or currency balance that is not exactly the sum of its append-only ledger is a divergence and is flagged. There is no tolerance band.

XP is recomputed from `xpLedger` rows whose `validated` is not false. Ngwenya, cowries, and ancestral beads are recomputed from `rewardMovements` when that user has at least one movement for that currency. Points have no server ledger.

A balance with no ledger rows is **unbacked**, not a computed fraud number. The default run flags it and does not change it. `--include-unbacked` sets those balances to 0, because there is no server event to support them.

## Who may approve `--apply`

Production `--apply` is approved by **Tope**. The script refuses `--apply` unless `--approved-by` is a non-empty name. Dry-run needs no approver and writes nothing.

```
npx ts-node scripts/reconcile/reconcile_balances.ts --dry-run
npx ts-node scripts/reconcile/reconcile_balances.ts --apply --approved-by "Tope"
```

Run the dry-run first and read every flagged row. Apply writes the recomputed balance and a `rewardAdjustments` row that stores the prior value, the recomputed value, and the delta, so the change can be reversed. A second apply on the same data changes 0 balances.
