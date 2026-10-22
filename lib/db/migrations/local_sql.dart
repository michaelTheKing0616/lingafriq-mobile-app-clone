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
