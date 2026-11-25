#!/usr/bin/env node
// charter: v2
// P12-014: Staging read load profile — per-route p50/p95/error rate, p95 < 300 ms, prod host refused.

'use strict';

const fs = require('fs');
const http = require('http');
const path = require('path');

const PROD_HOST_PATTERNS = [
  /^api\.lingafriq\.com$/i,
  /^app\.lingafriq\.com$/i,
  /^www\.lingafriq\.com$/i,
  /^lingafriq\.com$/i,
  /production/i,
  /\.prod\./i,
];

function isProductionHost(input) {
  let hostname;
  try {
    const u = new URL(input.startsWith('http') ? input : `https://${input}`);
    hostname = u.hostname.toLowerCase();
  } catch {
    return true;
  }
  if (process.env.LOADTEST_ENV === 'production') {
    return true;
  }
  return PROD_HOST_PATTERNS.some((re) => re.test(hostname));
}

function percentile(sortedAsc, p) {
  if (!sortedAsc.length) {
    return 0;
  }
  const idx = Math.ceil((p / 100) * sortedAsc.length) - 1;
  return sortedAsc[Math.max(0, Math.min(sortedAsc.length - 1, idx))];
}

function summarizeLatencies(latenciesMs) {
  const sorted = [...latenciesMs].sort((a, b) => a - b);
  return {
    count: sorted.length,
    p50_ms: percentile(sorted, 50),
    p95_ms: percentile(sorted, 95),
  };
}

function evaluateRouteResults(routeSummaries, p95LimitMs) {
  const failures = [];
  for (const row of routeSummaries) {
    if (row.p95_ms >= p95LimitMs) {
      failures.push({
        route: row.route,
        reason: 'p95_exceeded',
        p95_ms: row.p95_ms,
        limit_ms: p95LimitMs,
      });
    }
    if (row.error_rate > 0) {
      failures.push({
        route: row.route,
        reason: 'errors',
        error_rate: row.error_rate,
      });
    }
  }
  return failures;
}

function loadProfile(profilePath) {
  const raw = fs.readFileSync(profilePath, 'utf8');
  return JSON.parse(raw);
}

async function timedFetch(baseUrl, route, bearerToken) {
  const url = new URL(route.path, baseUrl).toString();
  const headers = {};
  if (bearerToken) {
    headers.Authorization = `Bearer ${bearerToken}`;
  }
  const start = performance.now();
  try {
    const res = await fetch(url, {
      method: route.method || 'GET',
      headers,
      signal: AbortSignal.timeout(10_000),
    });
    const elapsed = performance.now() - start;
    const ok = res.status >= 200 && res.status < 400;
    if (!ok) {
      await res.text().catch(() => '');
    }
    return { ok, latency_ms: elapsed, status: res.status };
  } catch (err) {
    const elapsed = performance.now() - start;
    return { ok: false, latency_ms: elapsed, status: 0, error: String(err) };
  }
}

async function runLoadTest(baseUrl, profile, options = {}) {
  if (isProductionHost(baseUrl)) {
    const err = new Error(`refused: production host not allowed (${baseUrl})`);
    err.code = 'PROD_HOST_REFUSED';
    throw err;
  }

  const bearerToken = options.bearerToken ?? process.env.LOADTEST_BEARER_TOKEN ?? '';
  const concurrency = profile.concurrency ?? 10;
  const durationMs = (profile.duration_seconds ?? 30) * 1000;
  const warmupMs = (profile.warmup_seconds ?? 5) * 1000;
  const routes = profile.routes ?? [];
  const buckets = new Map(routes.map((r) => [r.id, { route: r.id, latencies: [], errors: 0, total: 0 }]));

  const startedAt = Date.now();
  const measureStart = startedAt + warmupMs;
  const measureEnd = measureStart + durationMs;
  const workers = Array.from({ length: concurrency }, async () => {
    let idx = 0;
    while (Date.now() < measureEnd) {
      const route = routes[idx % routes.length];
      idx += 1;
      const sample = await timedFetch(baseUrl, route, bearerToken);
      const now = Date.now();
      if (now < measureStart) {
        continue;
      }
      const bucket = buckets.get(route.id);
      bucket.total += 1;
      bucket.latencies.push(sample.latency_ms);
      if (!sample.ok) {
        bucket.errors += 1;
      }
    }
  });
  await Promise.all(workers);

  const routeSummaries = [];
  for (const b of buckets.values()) {
    const stats = summarizeLatencies(b.latencies);
    routeSummaries.push({
      route: b.route,
      requests: b.total,
      errors: b.errors,
      error_rate: b.total ? b.errors / b.total : 0,
      p50_ms: stats.p50_ms,
      p95_ms: stats.p95_ms,
    });
  }
  routeSummaries.sort((a, b) => a.route.localeCompare(b.route));

  const p95Limit = profile.p95_limit_ms ?? 300;
  const failures = evaluateRouteResults(routeSummaries, p95Limit);
  return {
    base_url: baseUrl,
    profile: path.basename(options.profilePath || 'reads.json'),
    p95_limit_ms: p95Limit,
    concurrency,
    duration_seconds: profile.duration_seconds ?? 30,
    routes: routeSummaries,
    passed: failures.length === 0,
    failures,
    finished_at: new Date().toISOString(),
  };
}

function writeResults(report, outPath) {
  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, `${JSON.stringify(report, null, 2)}\n`, 'utf8');
}

async function selfTest() {
  const failures = [];
  const assert = (cond, msg) => {
    if (!cond) failures.push(msg);
  };

  assert(isProductionHost('https://api.lingafriq.com'), 'prod api host');
  assert(isProductionHost('https://staging.lingafriq.com.production.local'), 'prod substring');
  assert(!isProductionHost('https://staging-api.lingafriq.dev'), 'staging allowed');

  const latencies = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 290, 310];
  const stats = summarizeLatencies(latencies);
  assert(stats.p50_ms === 60, `p50 expected 60 got ${stats.p50_ms}`);
  assert(stats.p95_ms >= 290, `p95 expected ~310 got ${stats.p95_ms}`);

  const bad = evaluateRouteResults(
    [{ route: 'slow', p95_ms: 301, error_rate: 0, p50_ms: 100 }],
    300,
  );
  assert(bad.length === 1 && bad[0].reason === 'p95_exceeded', 'p95 fail detection');

  const server = http.createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end('{"ok":true}');
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const port = server.address().port;
  const base = `http://127.0.0.1:${port}`;
  const miniProfile = {
    p95_limit_ms: 300,
    concurrency: 4,
    duration_seconds: 2,
    warmup_seconds: 0,
    routes: [{ id: 'root', method: 'GET', path: '/' }],
  };
  const report = await runLoadTest(base, miniProfile, { profilePath: 'self-test' });
  assert(report.passed, 'mock load should pass');
  assert(report.routes[0].requests > 0, 'mock requests recorded');
  server.close();

  try {
    await runLoadTest('https://api.lingafriq.com', miniProfile);
    failures.push('prod run should throw');
  } catch (e) {
    assert(e.code === 'PROD_HOST_REFUSED', 'prod refusal code');
  }

  if (failures.length) {
    console.error('self-test failures:', failures);
    process.exit(1);
  }
  console.log('api_read_p95 self-test ok');
}

async function main() {
  const args = process.argv.slice(2);
  if (args.includes('--self-test')) {
    await selfTest();
    return;
  }

  const profilePath =
    process.env.LOADTEST_READ_PROFILE ||
    path.join(__dirname, 'profiles', 'reads.json');
  const baseUrl = process.env.LOADTEST_BASE_URL;
  if (!baseUrl) {
    console.error('LOADTEST_BASE_URL is required (staging API, not production)');
    process.exit(2);
  }

  const profile = loadProfile(profilePath);
  const outPath =
    process.env.LOADTEST_RESULTS_PATH ||
    path.join(process.cwd(), 'build', 'loadtest', 'api_read_p95.json');

  const report = await runLoadTest(baseUrl, profile, { profilePath });
  writeResults(report, outPath);
  console.log(JSON.stringify({ passed: report.passed, out: outPath, routes: report.routes }));

  if (!report.passed) {
    console.error('FAILED routes:', report.failures);
    process.exit(1);
  }
}

const isMain = require.main === module;
if (isMain) {
  main().catch((err) => {
    console.error(err);
    process.exit(err.code === 'PROD_HOST_REFUSED' ? 3 : 1);
  });
}

module.exports = {
  isProductionHost,
  percentile,
  summarizeLatencies,
  evaluateRouteResults,
  runLoadTest,
};
