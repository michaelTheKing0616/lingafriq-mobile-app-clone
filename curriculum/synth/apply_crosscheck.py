import json,glob,os,unicodedata as U,collections
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
res={}
for f in glob.glob(R+"/synth/crosscheck_results/*.jsonl"):
  for l in open(f):
    l=l.strip()
    if l:
      try: r=json.loads(l); res[r["id"]]=r
      except Exception: pass
c=collections.Counter()
for f in glob.glob(R+"/packs/*/*.synth.json"):
  pk=json.load(open(f))
  for it in pk["items"]:
    r=res.get(it["id"])
    if not r: continue
    it["crosscheck"]="sonnet-5.5"; it["crosscheck_score"]=r.get("score"); it["crosscheck_ok"]=r.get("ok"); c["scored"]+=1
    fx=r.get("fix")
    if not r.get("ok") and fx:
      if fx.startswith("GLOSS:"):
        it.setdefault("translation_en",{})["text"]=fx[6:].strip(); it["translation_en"]["status"]="needs-review"
      else:
        it["text_original"]=it["text"]; it["text"]=U.normalize("NFC",fx)
      it["fix_source"]="sonnet"; it["status"]="needs-review"; c["fixed"]+=1
      if it["lang"] in("yo","ha","ig") and (it["type"]=="proverb" or it.get("category") in("proverb","idiom")):
        it["native_check_priority"]=True; c["priority"]+=1
    elif not r.get("ok"): c["notok_nofix"]+=1
  json.dump(pk,open(f+".tmp","w"),ensure_ascii=False,indent=0); os.replace(f+".tmp",f)
print(dict(c),"results",len(res))
