# Socket load-test report (P9-907)

charter: v2

## Scope

Soak **10,000 authenticated Socket.IO connections per production-sized node** for **30 minutes** with realistic `presence:lookup` traffic. Script: `scripts/loadtest/socket_10k.js`.

## Thresholds (EP-§9.5-08 / §9.5-09)

| Metric | Pass |
|--------|------|
| Message delivery p95 | < 500 ms |
| Error rate (connect + message) | < 0.5% |
| Peak CPU (node) | ≤ 80% |
| Peak memory (node) | ≤ 80% |
| Connections held | = target (10k) |

Failed runs must record **FAIL** with the failing metric; no pass is recorded when any threshold fails.

## Staging run

```bash
cd lingafriq-mobile-app-clone
npm install socket.io@4.8.1 socket.io-client@4.8.1 --no-save --prefix scripts/loadtest

export LOADTEST_BASE_URL=https://staging-api.lingafriq.dev
export LOADTEST_BEARER_TOKEN=…   # JWT accepted by socket auth
export LOADTEST_NODE_CPU_PEAK=0.55   # from node exporter / cloud monitor peak during soak
export LOADTEST_NODE_MEM_PEAK=0.62
export LOADTEST_RESULTS_PATH=build/loadtest/socket_10k.json

node scripts/loadtest/socket_10k.js
```

Optional profile override: `LOADTEST_SOCKET_PROFILE=scripts/loadtest/profiles/socket_10k.json` (same keys as `DEFAULT_PROFILE` in the script).

Large soak may require **multiple load-generator hosts**; split `target_connections` per generator only if each client uses distinct auth and staging ops approve fan-out.

## CI / local verification

```bash
node scripts/loadtest/socket_10k.js --self-test
```

Uses a local mock server (scaled connections/duration) and exercises PASS/FAIL evaluation.

## Latest recorded run

| Date | Environment | Verdict | connections_held | p95 ms | error_rate | cpu_peak | mem_peak | Artifact |
|------|-------------|---------|------------------|--------|------------|----------|----------|----------|
| _pending staging soak_ | — | — | — | — | — | — | — | `build/loadtest/socket_10k.json` |

Update this table after the first staging 10k/30m soak; attach the JSON artifact to release evidence for G9.
