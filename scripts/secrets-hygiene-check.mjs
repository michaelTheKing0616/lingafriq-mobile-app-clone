import { execSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import path from 'node:path';

const args = new Set(process.argv.slice(2));
const strict = args.has('--strict');

const SENSITIVE_NAME_RE =
  /(secret|api[_-]?key|access[_-]?key|private[_-]?key|password|passwd|client[_-]?secret)$/i;
const PLACEHOLDER_RE =
  /(changeme|replace_me|placeholder|example|sample|dummy|test|local|localhost|your_|xxxx|<.*>|\$?\{.*\})/i;
const BINARY_EXT_RE = /\.(png|jpg|jpeg|gif|webp|ico|pdf|woff2?|ttf|zip|tar|gz|mp4|mp3|wav)$/i;
const CANDIDATE_PATH_RE = /(\.env($|\.)|config|secrets?|credentials?|settings)/i;

// Already tracked. Values are never printed. End-of-build purge removes the file.
const KNOWN = new Set([
  'JWT_SECRET_EXPLANATION.md\tJWT_SECRET',
  'JWT_SECRET_EXPLANATION.md\tSCRAPER_SECRET',
]);

const trackedFiles = execSync('git ls-files', { encoding: 'utf8' })
  .split('\n')
  .map((value) => value.trim())
  .filter(Boolean)
  .filter((file) => CANDIDATE_PATH_RE.test(file))
  .filter((file) => !BINARY_EXT_RE.test(file));

const findings = [];

for (const file of trackedFiles) {
  let content = '';
  try {
    content = readFileSync(file, 'utf8');
  } catch {
    continue;
  }

  const lines = content.split(/\r?\n/);
  for (let index = 0; index < lines.length; index += 1) {
    const trimmed = lines[index].trim();
    if (!trimmed || trimmed.startsWith('#') || trimmed.startsWith('//')) {
      continue;
    }

    const assignment = trimmed.match(/^([A-Za-z_][A-Za-z0-9_\-.]*)\s*(=|:)\s*(.+)$/);
    if (!assignment) continue;

    const key = assignment[1];
    const rawValue = assignment[3].replace(/^['"]|['"]$/g, '').trim();
    if (!SENSITIVE_NAME_RE.test(key)) continue;
    if (!rawValue || PLACEHOLDER_RE.test(rawValue)) continue;
    if (/[.\s()]/.test(rawValue) || /^(true|false|null|\d+)$/i.test(rawValue)) continue;

    findings.push({
      file: path.normalize(file),
      line: index + 1,
      key,
      known: KNOWN.has(`${file}\t${key}`),
    });
  }
}

const fresh = findings.filter((finding) => !finding.known);

if (findings.length === 0) {
  console.log('secrets-hygiene-check: no obvious tracked secret leaks found');
  process.exit(0);
}

for (const finding of findings) {
  const state = finding.known ? 'known' : 'new';
  console.warn(`- ${state} ${finding.file}:${finding.line} ${finding.key}=[REDACTED]`);
}

if (strict && fresh.length > 0) {
  console.warn(`secrets-hygiene-check: ${fresh.length} new secret-like assignment(s)`);
  process.exit(1);
}

console.log('secrets-hygiene-check: no new secret-like assignments');
process.exit(0);
