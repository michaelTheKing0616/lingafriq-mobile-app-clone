"""Apply hand-written (AI-assisted) English glosses to pcm items; all needs-review. No source translations exist (CV/African Voices have none)."""
import json,glob,os
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W=json.load(open(R+"/synth/pcm/word_gloss.json")); G={}
for f in glob.glob(R+"/synth/pcm/gloss_*.txt"):
  for l in open(f):
    if "|" in l: k,v=l.rstrip("\n").split("|",1); G[k]=v
n=0
for f in glob.glob(R+"/packs/pcm/[ABC][12].json"):
  pk=json.load(open(f))
  for it in pk["items"]:
    if it["type"]=="lexeme" and it["text"] in W: it["senses"]=[{"gloss_en":W[it["text"]],"gloss_status":"needs-review"}]; n+=1
    elif it["type"]=="sentence" and it["id"][-12:] in G: it["translation_en"]={"text":G[it["id"][-12:]],"alignment":"sentence","status":"needs-review"}; n+=1
    else: continue
    it["provenance"]["ai_assisted"]=True
    if "gloss_ai_written" not in it["risk_tags"]: it["risk_tags"].append("gloss_ai_written")
  json.dump(pk,open(f+".tmp","w"),ensure_ascii=False,indent=0); os.replace(f+".tmp",f)
print("pcm glosses",n)
