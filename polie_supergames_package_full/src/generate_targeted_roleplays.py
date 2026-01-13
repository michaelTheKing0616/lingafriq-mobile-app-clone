# generate_targeted_roleplays.py - full generator for targeted roleplays (10 languages)
import json, os, random
OUT = 'data/roleplay_targeted_native_review.jsonl'
os.makedirs('data', exist_ok=True)
languages = {
 'yoruba': ['market','greeting','doctor','school'],
 'igbo': ['market','greeting','family','transport'],
 'hausa': ['market','greeting','bank','police'],
 'swahili': ['market','hotel','directions','restaurant'],
 'zulu': ['greeting','market','hospital','family'],
 'xhosa': ['greeting','market','transport','school'],
 'amharic': ['greeting','market','directions','temple'],
 'wolof': ['greeting','market','transport','festival'],
 'somali': ['greeting','clinic','market','family'],
 'hausa_n': ['dialect','food','greeting','numbers']
}
templates = [
 "Roleplay: scenario '{scenario}' in {lang}. Create a 3-turn conversation, list target phrases and provide one cultural note.",
 "Tutor: Teach the phrase '{eng}' in {lang}. Provide phrase with diacritics, phonetics, one cultural note, and two practice activities.",
 "Translate: Translate '{eng}' to {lang} with usage notes and an example sentence."
]
eng_phrases = ['hello','thank you','good morning','how are you','where is the market','I need help','please','excuse me']

entries = []
for lang, scenarios in languages.items():
    for sc in scenarios:
        for i in range(25):  # 25 per scenario per language -> ~2500 entries
            mode_template = random.choice(templates)
            eng = random.choice(eng_phrases)
            prompt = mode_template.format(eng=eng, lang=lang.capitalize(), scenario=sc)
            entry = {'id':f'{lang}_{sc}_{i:03d}','language':lang,'mode':'auto','scenario':sc,'prompt':prompt,'needs_native_review':True}
            entries.append(entry)
with open(OUT,'w',encoding='utf-8') as f:
    for e in entries:
        f.write(json.dumps(e, ensure_ascii=False)+'\n')
print('Wrote', len(entries),'entries to', OUT)
