import os, json, psycopg2
from psycopg2.extras import execute_values
CUR_DIR = os.path.dirname(__file__)
CURR_DIR = os.path.join(CUR_DIR, '..')
DB_DSN = os.environ.get('CURR_DB_DSN', 'postgresql://user:pass@localhost:5432/curriculumdb')

conn = psycopg2.connect(DB_DSN)
cur = conn.cursor()

def create_tables():
    cur.execute("""
    CREATE TABLE IF NOT EXISTS languages (
        code TEXT PRIMARY KEY,
        name TEXT
    );
    CREATE TABLE IF NOT EXISTS curriculum (
        id SERIAL PRIMARY KEY,
        lang_code TEXT REFERENCES languages(code),
        level TEXT,
        unit INT,
        lesson_id TEXT,
        lesson_title TEXT,
        vocab JSONB,
        dialogue JSONB,
        exercises JSONB
    );
    """)
    conn.commit()

def import_json_file(json_path):
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    lang = data['meta']['code']
    level = data['meta']['level']
    units = data.get('units', [])
    rows = []
    for unit in units:
        for lesson in unit.get('lessons', []):
            rows.append((lang, level, unit.get('unit'), lesson.get('id'), lesson.get('title'),
                         json.dumps(lesson.get('vocab', [])), json.dumps(lesson.get('dialogue', {})), json.dumps(lesson.get('exercises', []))))
    sql = "INSERT INTO curriculum (lang_code, level, unit, lesson_id, lesson_title, vocab, dialogue, exercises) VALUES %s"
    execute_values(cur, sql, rows)
    conn.commit()

if __name__ == '__main__':
    create_tables()
    # iterate curriculum json files
    for root, dirs, files in os.walk(CURR_DIR):
        for f in files:
            if f.endswith('_expanded.json'):
                import_json_file(os.path.join(root, f))
    print('Import complete')
