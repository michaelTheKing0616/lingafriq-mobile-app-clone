#!/usr/bin/env node
// charter: v2
// P12-015: Chat send-to-receive delivery p95 < 500 ms, drops/out-of-order reporting, prod host refused.

'use strict';

const fs = require('fs');
const http = require('http');
const path = require('path');
const { isProductionHost, percentile, summarizeLatencies } = require('./api_read_p95.js');

function loadSocketIo() {
  const candidates = [
    'socket.io',
    path.join(__dirname, 'node_modules', 'socket.io'),
    path.join(__dirname, '..', '..', 'node_modules', 'socket.io'),
  ];
  for (const mod of candidates) {
    try {
      return require(mod);
    } catch {
      /* try next */
    }
  }
  throw new Error('socket.io is required for chat delivery load test (install in scripts/loadtest)');
}

function loadSocketIoClient() {
  const candidates = [
    'socket.io-client',
    path.join(__dirname, 'node_modules', 'socket.io-client'),
    path.join(__dirname, '..', '..', 'node_modules', 'socket.io-client'),
  ];
  for (const mod of candidates) {
    try {
      return require(mod);
    } catch {
      /* try next */
    }
  }
  throw new Error('socket.io-client is required for chat delivery load test (install in scripts/loadtest)');
}

function loadProfile(profilePath) {
  const raw = fs.readFileSync(profilePath, 'utf8');
  return JSON.parse(raw);
}

function evaluateDeliveryReport(stats, p95LimitMs) {
  const failures = [];
  if (stats.drops > 0) {
    failures.push({ reason: 'drops', drops: stats.drops, sent: stats.sent });
  }
  if (stats.p95_ms >= p95LimitMs) {
    failures.push({
      reason: 'p95_exceeded',
      p95_ms: stats.p95_ms,
      limit_ms: p95LimitMs,
    });
  }
  return failures;
}

function waitForSocket(socket, event, timeoutMs) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`timeout waiting for ${event}`)), timeoutMs);
    socket.once(event, (...args) => {
      clearTimeout(timer);
      resolve(args);
    });
    socket.once('connect_error', (err) => {
      clearTimeout(timer);
      reject(err);
    });
  });
}

function joinRoom(socket, room, timeoutMs = 10_000) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('join_room timeout')), timeoutMs);
    socket.emit('join_room', { room }, (ack) => {
      clearTimeout(timer);
      if (ack && ack.ok) {
        resolve(ack);
        return;
      }
      if (ack && ack.code === 'not_a_member') {
        reject(new Error(`join_room forbidden for room ${room}`));
        return;
      }
      resolve(ack ?? { ok: true });
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
    timeout: 15_000,
  });
}

async function runChatDeliveryTest(baseUrl, profile, options = {}) {
  if (isProductionHost(baseUrl)) {
    const err = new Error(`refused: production host not allowed (${baseUrl})`);
    err.code = 'PROD_HOST_REFUSED';
    throw err;
  }

  const senderToken =
    options.senderToken ??
    process.env.LOADTEST_CHAT_SENDER_TOKEN ??
    process.env.LOADTEST_BEARER_TOKEN ??
    '';
  const receiverToken =
    options.receiverToken ?? process.env.LOADTEST_CHAT_RECEIVER_TOKEN ?? senderToken;

  if (!senderToken || !receiverToken) {
    const err = new Error('LOADTEST_CHAT_SENDER_TOKEN and LOADTEST_CHAT_RECEIVER_TOKEN are required');
    err.code = 'MISSING_TOKENS';
    throw err;
  }

  const room = profile.room ?? 'global';
  const chatType = profile.chat_type ?? 'global';
  const socketPath = profile.socket_path ?? '/socket.io';
  const concurrency = profile.concurrency ?? 8;
  const durationMs = (profile.duration_seconds ?? 30) * 1000;
  const warmupMs = (profile.warmup_seconds ?? 5) * 1000;
  const deliveryTimeoutMs = profile.delivery_timeout_ms ?? 5000;
  const messagePrefix = profile.message_prefix ?? 'loadtest-delivery';
  const p95Limit = profile.p95_limit_ms ?? 500;

  const sender = connectClient(baseUrl, senderToken, socketPath);
  const receiver = connectClient(baseUrl, receiverToken, socketPath);

  await Promise.all([
    waitForSocket(sender, 'connect', 15_000),
    waitForSocket(receiver, 'connect', 15_000),
  ]);

  await Promise.all([joinRoom(sender, room), joinRoom(receiver, room)]);

  const pending = new Map();
  let lastSeq = 0;
  let outOfOrder = 0;

  receiver.on('new_message', (payload) => {
    const clientMessageId = payload?.clientMessageId?.toString();
    if (!clientMessageId || !pending.has(clientMessageId)) {
      return;
    }
    const entry = pending.get(clientMessageId);
    const latency = performance.now() - entry.startedAt;
    const seq = entry.seq;
    if (seq < lastSeq) {
      outOfOrder += 1;
    } else {
      lastSeq = seq;
    }
    latencies.push(latency);
    pending.delete(clientMessageId);
  });

  const latencies = [];
  let sent = 0;
  let drops = 0;
  const startedAt = Date.now();
  const measureStart = startedAt + warmupMs;
  const measureEnd = measureStart + durationMs;

  const workers = Array.from({ length: concurrency }, async (_, workerIdx) => {
    let localSeq = workerIdx * 1_000_000;
    while (Date.now() < measureEnd) {
      const now = Date.now();
      if (now < measureStart) {
        await new Promise((r) => setTimeout(r, 20));
        continue;
      }

      localSeq += 1;
      const clientMessageId = `${messagePrefix}-${workerIdx}-${localSeq}-${Date.now()}`;
      const startedAtPerf = performance.now();

      pending.set(clientMessageId, { startedAt: startedAtPerf, seq: localSeq, latencies: [] });
      sent += 1;

      await new Promise((resolve) => {
        const timer = setTimeout(() => {
          if (pending.has(clientMessageId)) {
            pending.delete(clientMessageId);
            drops += 1;
          }
          resolve();
        }, deliveryTimeoutMs);

        sender.emit(
          'send_message',
          {
            room,
            chatType,
            message: `${messagePrefix} ${clientMessageId}`,
            clientMessageId,
            timestamp: new Date().toISOString(),
          },
          () => {
            if (!pending.has(clientMessageId)) {
              clearTimeout(timer);
              resolve();
            }
          },
        );

        const check = setInterval(() => {
          if (!pending.has(clientMessageId)) {
            clearInterval(check);
            clearTimeout(timer);
            resolve();
          }
        }, 5);
      });
    }
  });

  await Promise.all(workers);

  drops += pending.size;
  pending.clear();

  sender.close();
  receiver.close();

  const summary = summarizeLatencies(latencies);
  const stats = {
    sent,
    received: latencies.length,
    drops,
    out_of_order: outOfOrder,
    p50_ms: summary.p50_ms,
    p95_ms: summary.p95_ms,
    count: summary.count,
  };

  const failures = evaluateDeliveryReport(stats, p95Limit);
  return {
    base_url: baseUrl,
    profile: path.basename(options.profilePath || 'chat.json'),
    p95_limit_ms: p95Limit,
    room,
    concurrency,
    duration_seconds: profile.duration_seconds ?? 30,
    delivery: stats,
    passed: failures.length === 0,
    failures,
    finished_at: new Date().toISOString(),
  };
}

function writeResults(report, outPath) {
  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, `${JSON.stringify(report, null, 2)}\n`, 'utf8');
}

async function runMockRelaySelfTest() {
  const { Server } = loadSocketIo();
  const { io: ioClient } = loadSocketIoClient();

  const server = http.createServer();
  const io = new Server(server, {
    cors: { origin: '*' },
    transports: ['websocket'],
  });

  io.on('connection', (socket) => {
    socket.on('join_room', (data, ack) => {
      const room = data?.room?.toString();
      if (room) {
        socket.join(room);
      }
      ack?.({ ok: true });
    });
    socket.on('send_message', (payload, ack) => {
      const room = payload?.room?.toString();
      const clientMessageId = payload?.clientMessageId?.toString();
      if (!room || !clientMessageId) {
        ack?.({ status: 'failed' });
        return;
      }
      setTimeout(() => {
        socket.to(room).emit('new_message', {
          clientMessageId,
          room,
          message: payload.message,
        });
        ack?.({ status: 'delivered', clientMessageId });
      }, 12);
    });
  });

  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const port = server.address().port;
  const base = `http://127.0.0.1:${port}`;

  const miniProfile = {
    p95_limit_ms: 500,
    concurrency: 3,
    duration_seconds: 2,
    warmup_seconds: 0,
    delivery_timeout_ms: 2000,
    room: 'mock-room',
    chat_type: 'global',
    message_prefix: 'mock',
  };

  const report = await runChatDeliveryTest(base, miniProfile, {
    profilePath: 'self-test',
    senderToken: 'mock-sender',
    receiverToken: 'mock-receiver',
  });

  server.close();
  return report;
}

async function selfTest() {
  const failures = [];
  const assert = (cond, msg) => {
    if (!cond) failures.push(msg);
  };

  assert(isProductionHost('https://api.lingafriq.com'), 'prod api host');
  assert(!isProductionHost('https://staging-api.lingafriq.dev'), 'staging allowed');

  const latencies = [50, 80, 100, 120, 400, 450, 480, 520];
  const stats = {
    sent: 8,
    drops: 0,
    p95_ms: summarizeLatencies(latencies).p95_ms,
  };
  assert(evaluateDeliveryReport(stats, 500).length === 1, 'p95 fail at 500+');
  stats.p95_ms = 400;
  assert(evaluateDeliveryReport(stats, 500).length === 0, 'p95 pass under 500');
  assert(evaluateDeliveryReport({ drops: 1, p95_ms: 10 }, 500)[0].reason === 'drops', 'drop fail');

  try {
    await runChatDeliveryTest('https://api.lingafriq.com', { p95_limit_ms: 500 });
    failures.push('prod run should throw');
  } catch (e) {
    assert(e.code === 'PROD_HOST_REFUSED', 'prod refusal code');
  }

  const mockReport = await runMockRelaySelfTest();
  assert(mockReport.passed, `mock delivery should pass: ${JSON.stringify(mockReport.failures)}`);
  assert(mockReport.delivery.received > 0, 'mock received messages');
  assert(mockReport.delivery.drops === 0, 'mock no drops');

  if (failures.length) {
    console.error('self-test failures:', failures);
    process.exit(1);
  }
  console.log('chat_delivery_p95 self-test ok');
}

async function main() {
  const args = process.argv.slice(2);
  if (args.includes('--self-test')) {
    await selfTest();
    return;
  }

  const profilePath =
    process.env.LOADTEST_CHAT_PROFILE || path.join(__dirname, 'profiles', 'chat.json');
  const baseUrl = process.env.LOADTEST_BASE_URL;
  if (!baseUrl) {
    console.error('LOADTEST_BASE_URL is required (staging socket origin, not production)');
    process.exit(2);
  }

  const profile = loadProfile(profilePath);
  const outPath =
    process.env.LOADTEST_RESULTS_PATH ||
    path.join(process.cwd(), 'build', 'loadtest', 'chat_delivery_p95.json');

  const report = await runChatDeliveryTest(baseUrl, profile, { profilePath });
  writeResults(report, outPath);
  console.log(
    JSON.stringify({
      passed: report.passed,
      out: outPath,
      delivery: report.delivery,
    }),
  );

  if (!report.passed) {
    console.error('FAILED:', report.failures);
    process.exit(1);
  }
}

const isMain = require.main === module;
if (isMain) {
  main().catch((err) => {
    console.error(err);
    const code = err.code === 'PROD_HOST_REFUSED' ? 3 : err.code === 'MISSING_TOKENS' ? 4 : 1;
    process.exit(code);
  });
}

module.exports = {
  evaluateDeliveryReport,
  runChatDeliveryTest,
  loadSocketIoClient,
};
