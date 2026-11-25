charter: v2

# ADR-020 — One soft currency (Cowries)

Status: **Accepted** (Tope, 2026-10-27). Records EP-§12.2-07 and unblocks P10-902+ monetisation cards.

## Context

Elevation §12.2 names three in-app currencies (ngwenya, cowries, ancestral_beads) with unclear sinks. §12.2 recommends keeping **Cowries** as the single soft currency with explicit sinks.

## Decision

- **Cowries** is the only learner-facing soft currency. **ngwenya** and **ancestral_beads** are retired from new earns and spends.
- **Migration (existing balances):** on first post-migration sync, `ngwenya` and `ancestral_beads` convert to Cowries at **1:1** each; one ledger row per balance records `currency_migration` with the prior amounts. After conversion, legacy fields read zero for spend purposes.
- **Allowed Cowries sinks:** cosmetic avatar items, streak repair inside the repair window, reviewed persona chapter early access, and donations to the community language-preservation fund (Heritage Fund).
- **Minors:** learners under 18 (child or teen bands per D11) may not complete **real-money** purchases (subscriptions, IAP, marketplace fiat). Cowries earned in-app remain spendable only on allowed sinks; Cowries are not sold for real money to minors.

## Consequences

- P10-902 migrates balances; P10-903 implements sinks; P10-912 enforces monetisation guardrails in `purchase-guard.service.ts` and `sinks.service.ts`.
