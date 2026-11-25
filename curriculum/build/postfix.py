"""Deterministic post-pass after build.py (run before validators): drop lexemes outside the language's
orthography charset, de-duplicate identical texts across levels (keep lowest level), and demote Beta nouns
whose prefix contradicts their tagged noun class. Rewrites packs atomically."""
import json,glob,os,sys,collections
sys.path.insert(0,os.path.dirname(os.path.dirname(os.path.abspath(__file__)))+"/validators")
import importlib.util
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src=open(R+"/validators/validate.py").read().split("E=collections.defaultdict")[0]; g={"__file__":R+"/validators/validate.py"}; exec(src,g)
L=["A1","A2","B1","B2","C1","C2"]; seen=set(); log=collections.Counter()
for lang in ["yo","ig","ha","pcm","sw","zu","xh"]:
  for lv in L:
    f=f"{R}/packs/{lang}/{lv}.json"
    if not os.path.exists(f): continue
    pk=json.load(open(f)); keep=[]
    for it in pk["items"]:
      k=(lang,it["type"],it["text"].lower())
      if k in seen: log["dup_dropped"]+=1; continue
      if g["PH"].search(it["text"]): log["placeholder_dropped"]+=1; continue
      if it["type"]=="lexeme" and set(g["nfd"](it["text"].lower()))-g["CH"][lang]-{"-","’"}: log["charset_dropped"]+=1; continue
      nc=it.get("noun_class")
      if it["status"]=="Beta" and nc and nc.get("sg") and lang in g["NP"]:
        pre=g["NP"][lang].get(nc["sg"])
        if pre and not any(it["text"].lower().startswith(p) for p in pre):
          it["status"]="needs-review"; it["risk_tags"].append("noun_class_prefix_mismatch"); it["senses"][0]["gloss_status"]="needs-review"; log["demoted"]+=1
      seen.add(k); keep.append(it)
    pk["items"]=keep; json.dump(pk,open(f+".tmp","w"),ensure_ascii=False,indent=0); os.replace(f+".tmp",f)
print(dict(log))
