const createLessons = '''
CREATE TABLE lessons (
  id TEXT NOT NULL PRIMARY KEY,
  payload TEXT NOT NULL
)
''';

const createVocabulary = '''
CREATE TABLE vocabulary (
  id TEXT NOT NULL PRIMARY KEY,
  word TEXT NOT NULL,
  translation TEXT NOT NULL,
  language TEXT NOT NULL,
  payload TEXT NOT NULL
)
''';

const createProgress = '''
CREATE TABLE progress (
  id TEXT NOT NULL PRIMARY KEY,
  payload TEXT NOT NULL
)
''';

const createMediaCache = '''
CREATE TABLE media_cache (
  url TEXT NOT NULL PRIMARY KEY,
  payload TEXT NOT NULL
)
''';

const addReviewDue = 'ALTER TABLE vocabulary ADD COLUMN review_due INTEGER';

const createPointAndSay = '''
CREATE TABLE IF NOT EXISTS point_and_say (
  id TEXT NOT NULL PRIMARY KEY,
  payload TEXT NOT NULL
)
''';

const createOutbox = '''
CREATE TABLE IF NOT EXISTS outbox (
  id TEXT NOT NULL PRIMARY KEY,
  idempotency_key TEXT NOT NULL UNIQUE,
  state TEXT NOT NULL,
  next_attempt_at INTEGER,
  attempts INTEGER NOT NULL,
  payload TEXT NOT NULL
)
''';
