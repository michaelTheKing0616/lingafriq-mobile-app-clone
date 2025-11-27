import os, json
from pymongo import MongoClient
MONGO_URI = os.environ.get('MONGO_URI','mongodb://localhost:27017')
client = MongoClient(MONGO_URI)
db = client['curriculumdb']
for root, dirs, files in os.walk(os.path.join(os.path.dirname(__file__), '..')):
    for f in files:
        if f.endswith('_expanded.json'):
            with open(os.path.join(root,f), 'r', encoding='utf-8') as fh:
                data = json.load(fh)
            db.curricula.replace_one({'meta.code': data['meta']['code'], 'meta.level': data['meta']['level']}, data, upsert=True)
print('Mongo import complete')
