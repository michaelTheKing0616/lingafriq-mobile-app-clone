import json,os,hashlib,glob,unicodedata as U
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TY={"culture_note":"culture_note","proverb":"proverb"}
GR={"relative_clause","conditional","verbal_extension","tense_aspect","serial_verb","focus","ideophone","grammar_complex","discourse_marker","politeness","register"}
cnt={}
import sys
for f in (sys.argv[1:] or sorted(glob.glob(R+"/synth/v2/*.tsv"))):
  lang=os.path.basename(f)[:-4].split("_")[0]; new={}
  for l in open(f):
    L,cat,t,g=l.rstrip("\n").split("|"); t=U.normalize("NFC",t)
    typ=TY.get(cat,"pattern" if cat in GR else "sentence")
    new.setdefault(L,[]).append({"id":f"{lang}.{'prv' if typ=='proverb' else 'syn'}.{hashlib.sha1(('v2'+t).encode()).hexdigest()[:12]}","lang":lang,"type":typ,"category":cat,"cefr":L,
     "can_do":[f"{L}.{cat.upper()}"],"text":t,"source_type":"synthesized","translation_en":{"text":g,"alignment":"sentence","status":"needs-review"},
     "pattern":{"description":None},"provenance":{"sources":[{"source_id":"synth-v2","licence":"original (LingAfriq)","locator":"synth/v2/"+os.path.basename(f),"role":"shipped_text"}],"created_at":"2026-10-21","ai_assisted":True},
     "claims":[],"confidence":0.5 if lang in("yo","ig") else 0.6,"risk_tags":["synthesized","unattested_forms_allowed"]+(["tone_unverified"] if lang in("yo","ig") else []),
     "status":"needs-review","label":"beta","audio":[],"feature_hooks":{"lessons":[f"{lang}.{L}.{cat}"],"games":["translate","cloze"],"point_and_say":False,"living_dictionary":typ=="proverb","personas":{"level":L}}})
  for L,its in new.items():
    p=f"{R}/packs/{lang}/{L}.synth.json"
    pk=json.load(open(p)) if os.path.exists(p) else {"lang":lang,"level":L,"built":"2026-10-21","items":[]}
    old=pk["items"]
    seen={x["text"].lower() for x in old}; add=[x for x in its if x["text"].lower() not in seen and not seen.add(x["text"].lower())]
    pk["items"]=old+add; json.dump(pk,open(p+".tmp","w"),ensure_ascii=False,indent=0); os.replace(p+".tmp",p); cnt[f"{lang}/{L}"]=len(add)
print(cnt)
