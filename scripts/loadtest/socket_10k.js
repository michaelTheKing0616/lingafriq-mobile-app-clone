#!/usr/bin/env node
// charter: v2
// P9-907: 10k concurrent socket soak — delivery p95, error rate, node CPU/memory peaks (staging).

'use strict';

const fs = require('fs');
const http = require('http');
const path = require('path');
const { isProductionHost, percentile, summarizeLatencies } = require('./api_read_p95.js');
const { loadSocketIoClient } = require('./chat_delivery_p95.js');

const DEFAULT_PROFILE = {
  target_connections: 10_000,
  soak_duration_seconds: 1800,
  warmup_seconds: 120,
  connect_storm_batch: 400,
  connect_storm_interval_ms: 150,
  lookup_interval_ms: 20_000,
  p95_limit_ms: 500,
  error_rate_limit: 0.005,
  cpu_peak_limit: 0.8,
  mem_peak_limit: 0.8,
  socket_path: '/socket.io',
};

function loadProfile(profilePath) {
  if (!profilePath || !fs.existsSync(profilePath)) {
    return { ...DEFAULT_PROFILE };
  }
  const raw = fs.readFileSync(profilePath, 'utf8');
  return { ...DEFAULT_PROFILE, ...JSON.parse(raw) };
}

function loadNodeMetrics(options = {}) {
  const fromEnv = {
    cpu_peak_ratio: parseFloat(process.env.LOADTEST_NODE_CPU_PEAK || '', 10),
    mem_peak_ratio: parseFloat(process.env.LOADTEST_NODE_MEM_PEAK || '', 10),
  };
  const metricsPath =
    options.metricsPath ||
    process.env.LOADTEST_NODE_METRICS_PATH ||
    process.env.LOADTEST_NODE_METRICS_JSON;
  let fromFile = {};
  if (metricsPath && fs.existsSync(metricsPath)) {
    fromFile = JSON.parse(fs.readFileSync(metricsPath, 'utf8'));
  }
  const cpu =
    Number.isFinite(fromEnv.cpu_peak_ratio) && fromEnv.cpu_peak_ratio >= 0
      ? fromEnv.cpu_peak_ratio
      : fromFile.cpu_peak_ratio;
  const mem =
    Number.isFinite(fromEnv.mem_peak_ratio) && fromEnv.mem_peak_ratio >= 0
      ? fromEnv.mem_peak_ratio
      : fromFile.mem_peak_ratio;
  return {
    cpu_peak_ratio: typeof cpu === 'number' && !Number.isNaN(cpu) ? cpu : null,
    mem_peak_ratio: typeof mem === 'number' && !Number.isNaN(mem) ? mem : null,
    source: metricsPath ? path.basename(metricsPath) : 'env',
  };
}

function evaluateSocketSoakReport(stats, limits) {
  const failures = [];
  if (stats.message_p95_ms >= limits.p95_limit_ms) {
    failures.push({
      reason: 'message_p95_exceeded',
      message_p95_ms: stats.message_p95_ms,
      limit_ms: limits.p95_limit_ms,
    });
  }
  if (stats.error_rate >= limits.error_rate_limit) {
    failures.push({
      reason: 'error_rate_exceeded',
      error_rate: stats.error_rate,
      limit: limits.error_rate_limit,
    });
  }
  if (stats.cpu_peak_ratio != null && stats.cpu_peak_ratio > limits.cpu_peak_limit) {
    failures.push({
      reason: 'cpu_peak_exceeded',
      cpu_peak_ratio: stats.cpu_peak_ratio,
      limit: limits.cpu_peak_limit,
    });
  }
  if (stats.mem_peak_ratio != null && stats.mem_peak_ratio > limits.mem_peak_limit) {
    failures.push({
      reason: 'mem_peak_exceeded',
      mem_peak_ratio: stats.mem_peak_ratio,
      limit: limits.mem_peak_limit,
    });
  }
  if (stats.connections_held < stats.target_connections) {
    failures.push({
      reason: 'connection_target_missed',
      connections_held: stats.connections_held,
      target_connections: stats.target_connections,
    });
  }
  return failures;
}

function buildReportPayload(baseUrl, profile, stats, failures, metrics) {
  const passed = failures.length === 0;
  return {
    card: 'P9-907',
    verdict: passed ? 'PASS' : 'FAIL',
    base_url: baseUrl,
    target_connections: profile.target_connections,
    soak_duration_seconds: profile.soak_duration_seconds,
    connections_held: stats.connections_held,
    connection_attempts: stats.connection_attempts,
    connect_errors: stats.connect_errors,
    messages_sent: stats.messages_sent,
    message_errors: stats.message_errors,
    error_rate: stats.error_rate,
    message_p50_ms: stats.message_p50_ms,
    message_p95_ms: stats.message_p95_ms,
    cpu_peak_ratio: stats.cpu_peak_ratio,
    mem_peak_ratio: stats.mem_peak_ratio,
    metrics_source: metrics.source,
    failures,
    finished_at: new Date().toISOString(),
  };
}

function waitForConnect(socket, timeoutMs) {
  return new Promise((resolve, reject) => {
    if (socket.connected) {
      resolve();
      return;
    }
    const timer = setTimeout(() => reject(new Error('connect timeout')), timeoutMs);
    socket.once('connect', () => {
      clearTimeout(timer);
      resolve();
    });
    socket.once('connect_error', (err) => {
      clearTimeout(timer);
      reject(err);
    });
  });
}

function presenceLookup(socket, targetUserId, timeoutMs = 5000) {
  return new Promise((resolve, reject) => {
    const started = performance.now();
    const timer = setTimeout(() => {
      reject(new Error('presence:lookup timeout'));
    }, timeoutMs);
    socket.emit('presence:lookup', { userId: targetUserId }, (ack) => {
      clearTimeout(timer);
      resolve(performance.now() - started);
    });
  });
}

function connectClient(baseUrl, token, socketPath) {
  const { io } = loadSocketIoClient();
  return io(baseUrl, {
    path: socketPath,
    transports: ['websocket'],
    auth: { token },
    reconnection: false,
    timeout: 20_000,
  });
}

async function runSocketSoakTest(baseUrl, profile, options = {}) {
  if (isProductionHost(baseUrl)) {
    const err = new Error(`refused: production host not allowed (${baseUrl})`);
    err.code = 'PROD_HOST_REFUSED';
    throw err;
  }

  const token =
    options.token ?? process.env.LOADTEST_BEARER_TOKEN ?? process.env.LOADTEST_SOCKET_TOKEN ?? '';
  if (!token) {
    const err = new Error('LOADTEST_BEARER_TOKEN (or LOADTEST_SOCKET_TOKEN) is required');
    err.code = 'MISSING_TOKEN';
    throw err;
  }

  const metrics = loadNodeMetrics(options);
  const target = profile.target_connections;
  const sockets = [];
  let connectionAttempts = 0;
  let connectErrors = 0;
  let messagesSent = 0;
  let messageErrors = 0;
  const latencies = [];

  const batch = profile.connect_storm_batch;
  const intervalMs = profile.connect_storm_interval_ms;
  const socketPath = profile.socket_path ?? '/socket.io';

  while (sockets.length < target) {
    const slice = Math.min(batch, target - sockets.length);
    const batchPromises = [];
    for (let i = 0; i < slice; i += 1) {
      connectionAttempts += 1;
      const sock = connectClient(baseUrl, token, socketPath);
      batchPromises.push(
        waitForConnect(sock, 25_000)
          .then(() => {
            sockets.push(sock);
          })
          .catch(() => {
            connectErrors += 1;
            try {
              sock.close();
            } catch {
              /* ignore */
            }
          }),
      );
    }
    await Promise.all(batchPromises);
    if (sockets.length < target) {
      await new Promise((r) => setTimeout(r, intervalMs));
    }
  }

  const soakMs = (profile.soak_duration_seconds ?? 1800) * 1000;
  const warmupMs = (profile.warmup_seconds ?? 120) * 1000;
  const measureStart = Date.now() + warmupMs;
  const measureEnd = measureStart + soakMs;
  const lookupEvery = profile.lookup_interval_ms ?? 20_000;
  const lookupTarget = options.lookupTargetUserId ?? process.env.LOADTEST_PRESENCE_TARGET ?? 'loadtest-peer';

  let running = true;
  const heartbeatTimers = sockets.map((sock, idx) => {
    const offset = (idx % 10) * 200;
    return setInterval(async () => {
      if (!running || Date.now() < measureStart || Date.now() > measureEnd) {
        return;
      }
      if (!sock.connected) {
        messageErrors += 1;
        return;
      }
      messagesSent += 1;
      try {
        const ms = await presenceLookup(sock, lookupTarget, profile.p95_limit_ms + 2000);
        latencies.push(ms);
      } catch {
        messageErrors += 1;
      }
    }, lookupEvery + offset);
  });

  await new Promise((r) => setTimeout(r, warmupMs + soakMs));

  running = false;
  for (const t of heartbeatTimers) {
    clearInterval(t);
  }

  const connectionsHeld = sockets.filter((s) => s.connected).length;

  for (const sock of sockets) {
    try {
      sock.close();
    } catch {
      /* ignore */
    }
  }

  const summary = summarizeLatencies(latencies);
  const denom = Math.max(1, connectionAttempts + messagesSent);
  const errorRate = (connectErrors + messageErrors) / denom;

  const stats = {
    target_connections: target,
    connections_held: connectionsHeld,
    connection_attempts: connectionAttempts,
    connect_errors: connectErrors,
    messages_sent: messagesSent,
    message_errors: messageErrors,
    error_rate: errorRate,
    message_p50_ms: summary.p50_ms,
    message_p95_ms: latencies.length ? summary.p95_ms : 0,
    cpu_peak_ratio: metrics.cpu_peak_ratio,
    mem_peak_ratio: metrics.mem_peak_ratio,
  };

  const limits = {
    p95_limit_ms: profile.p95_limit_ms ?? 500,
    error_rate_limit: profile.error_rate_limit ?? 0.005,
    cpu_peak_limit: profile.cpu_peak_limit ?? 0.8,
    mem_peak_limit: profile.mem_peak_limit ?? 0.8,
  };

  const failures = evaluateSocketSoakReport(stats, limits);
  if (metrics.cpu_peak_ratio == null || metrics.mem_peak_ratio == null) {
    failures.push({
      reason: 'node_metrics_missing',
      detail: 'Set LOADTEST_NODE_CPU_PEAK and LOADTEST_NODE_MEM_PEAK or LOADTEST_NODE_METRICS_PATH',
    });
  }

  return buildReportPayload(baseUrl, profile, stats, failures, metrics);
}

async function runMockSoakSelfTest(profileOverride = {}) {
  const tryRequire = (name) => {
    try {
      return require(name);
    } catch {
      return require(path.join(__dirname, 'node_modules', name));
    }
  };
  const { Server: MockServer } = tryRequire('socket.io');

  const server = http.createServer();
  const io = new MockServer(server, {
    cors: { origin: '*' },
    transports: ['websocket'],
  });

  io.on('connection', (socket) => {
    socket.on('presence:lookup', (payload, ack) => {
      setTimeout(() => {
        ack?.({ userId: payload?.userId?.toString() ?? '', isOnline: true });
      }, 8);
    });
  });

  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const port = server.address().port;
  const base = `http://127.0.0.1:${port}`;

  const miniProfile = {
    target_connections: 24,
    soak_duration_seconds: 2,
    warmup_seconds: 0,
    connect_storm_batch: 12,
    connect_storm_interval_ms: 10,
    lookup_interval_ms: 400,
    p95_limit_ms: 500,
    error_rate_limit: 0.005,
    cpu_peak_limit: 0.8,
    mem_peak_limit: 0.8,
    ...profileOverride,
  };

  const prevCpu = process.env.LOADTEST_NODE_CPU_PEAK;
  const prevMem = process.env.LOADTEST_NODE_MEM_PEAK;
  process.env.LOADTEST_NODE_CPU_PEAK = '0.42';
  process.env.LOADTEST_NODE_MEM_PEAK = '0.55';

  const report = await runSocketSoakTest(base, miniProfile, {
    token: 'mock-token',
    lookupTargetUserId: 'peer-1',
  });

  if (prevCpu === undefined) delete process.env.LOADTEST_NODE_CPU_PEAK;
  else process.env.LOADTEST_NODE_CPU_PEAK = prevCpu;
  if (prevMem === undefined) delete process.env.LOADTEST_NODE_MEM_PEAK;
  else process.env.LOADTEST_NODE_MEM_PEAK = prevMem;

  server.close();
  return report;
}

async function selfTest() {
  const failures = [];
  const assert = (cond, msg) => {
    if (!cond) failures.push(msg);
  };

  const limits = {
    p95_limit_ms: 500,
    error_rate_limit: 0.005,
    cpu_peak_limit: 0.8,
    mem_peak_limit: 0.8,
  };

  assert(
    evaluateSocketSoakReport(
      {
        message_p95_ms: 520,
        error_rate: 0.001,
        cpu_peak_ratio: 0.5,
        mem_peak_ratio: 0.5,
        connections_held: 10_000,
        target_connections: 10_000,
      },
      limits,
    )[0].reason === 'message_p95_exceeded',
    'p95 fail',
  );

  assert(
    evaluateSocketSoakReport(
      {
        message_p95_ms: 100,
        error_rate: 0.01,
        cpu_peak_ratio: 0.5,
        mem_peak_ratio: 0.5,
        connections_held: 10_000,
        target_connections: 10_000,
      },
      limits,
    )[0].reason === 'error_rate_exceeded',
    'error rate fail',
  );

  assert(
    evaluateSocketSoakReport(
      {
        message_p95_ms: 100,
        error_rate: 0.001,
        cpu_peak_ratio: 0.85,
        mem_peak_ratio: 0.5,
        connections_held: 10_000,
        target_connections: 10_000,
      },
      limits,
    )[0].reason === 'cpu_peak_exceeded',
    'cpu fail',
  );

  assert(
    evaluateSocketSoakReport(
      {
        message_p95_ms: 100,
        error_rate: 0.001,
        cpu_peak_ratio: 0.5,
        mem_peak_ratio: 0.5,
        connections_held: 9999,
        target_connections: 10_000,
      },
      limits,
    )[0].reason === 'connection_target_missed',
    'connection target fail',
  );

  try {
    await runSocketSoakTest('https://api.lingafriq.com', DEFAULT_PROFILE);
    failures.push('prod should refuse');
  } catch (e) {
    assert(e.code === 'PROD_HOST_REFUSED', 'prod code');
  }

  const mockReport = await runMockSoakSelfTest();
  assert(mockReport.verdict === 'PASS', `mock soak PASS: ${JSON.stringify(mockReport.failures)}`);
  assert(mockReport.connections_held >= 24, 'held connections');
  assert(mockReport.messages_sent > 0, 'messages sent');

  const failReport = evaluateSocketSoakReport(
    {
      message_p95_ms: 600,
      error_rate: 0.002,
      cpu_peak_ratio: 0.5,
      mem_peak_ratio: 0.5,
      connections_held: 10_000,
      target_connections: 10_000,
    },
    limits,
  );
  assert(failReport.length === 1 && failReport[0].reason === 'message_p95_exceeded', 'single fail reason');

  if (failures.length) {
    console.error('self-test failures:', failures);
    process.exit(1);
  }
  console.log('socket_10k self-test ok');
}

function writeResults(report, outPath) {
  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, `${JSON.stringify(report, null, 2)}\n`, 'utf8');
}

async function main() {
  const args = process.argv.slice(2);
  if (args.includes('--self-test')) {
    await selfTest();
    return;
  }

  const profilePath =
    process.env.LOADTEST_SOCKET_PROFILE || path.join(__dirname, 'profiles', 'socket_10k.json');
  const baseUrl = process.env.LOADTEST_BASE_URL;
  if (!baseUrl) {
    console.error('LOADTEST_BASE_URL is required (staging socket origin, not production)');
    process.exit(2);
  }

  const profile = loadProfile(profilePath);
  const outPath =
    process.env.LOADTEST_RESULTS_PATH ||
    path.join(process.cwd(), 'build', 'loadtest', 'socket_10k.json');

  const report = await runSocketSoakTest(baseUrl, profile, { profilePath });
  writeResults(report, outPath);
  console.log(JSON.stringify({ verdict: report.verdict, out: outPath, connections_held: report.connections_held }));

  if (report.verdict !== 'PASS') {
    console.error('FAILED:', report.failures);
    process.exit(1);
  }
}

const isMain = require.main === module;
if (isMain) {
  main().catch((err) => {
    console.error(err);
    const code =
      err.code === 'PROD_HOST_REFUSED' ? 3 : err.code === 'MISSING_TOKEN' ? 4 : 1;
    process.exit(code);
  });
}

module.exports = {
  DEFAULT_PROFILE,
  evaluateSocketSoakReport,
  loadNodeMetrics,
  runSocketSoakTest,
  buildReportPayload,
};
