"""Check synthesized drafts token-by-token against attested index; package survivors as needs-review items."""
import json,re,os,hashlib,unicodedata as U,collections
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORD=re.compile(r"[^\W\d_](?:[^\W\d_]|[\u0300-\u036f]|['’-](?=[^\W\d_]))*")
D=json.load(open(R+"/synth/drafts.json")); P=json.load(open(R+"/synth/proverbs.json")); H=json.load(open(R+"/synth/proverb_hits.json"))
REG={r["id"]:r for r in json.load(open(R+"/sources/licence_register.json"))}
SRCID=lambda loc:("sadilar_xhmono" if "xhmono" in loc else "sadilar_morph") if loc.startswith("sadilar") else loc.split(":")[0]
TYPE={"culture_note":"culture_note","relative_clause":"pattern","verbal_extension":"pattern","serial_verb":"pattern","conditional":"pattern","tense_aspect":"pattern","ideophone":"pattern","focus":"pattern","manner_clause":"pattern","politeness":"pattern","discourse_marker":"pattern"}
CD={"pattern":"{L}.GRAM: Use complex grammar ({c})","sentence":"{L}.PROD: Produce {c} text","culture_note":"{L}.CULT: Understand a cultural practice","proverb":"{L}.IDIOM: Understand and use proverbs in context"}
log={"accepted":collections.Counter(),"rejected":[]}
out=collections.defaultdict(list)
def check(lang,text):
  ix=IX[lang]; ev=[]; miss=[]
  for w in WORD.findall(U.normalize("NFC",text)):
    k=w.lower()
    if k in ix: ev.append({"token":w,"count":ix[k][0],"locator":ix[k][1]})
    else: miss.append(w)
  return ev,miss
def item(lang,L,typ,cat,text,en,note,ev,extra_src=None,risk=()):
  srcs={}
  for e in ev: srcs.setdefault(SRCID(e["locator"]),e["locator"])
  minc=min(e["count"] for e in ev) if ev else 0
  conf=round(min(0.75,0.45+0.05*min(5,len(ev)>0 and (minc>=5)*5)) - (0.1 if lang in("yo","ig") else 0),2)
  prov=[{"source_id":s,"licence":REG[s]["licence"].split(" (")[0].split(";")[0],"locator":l,"role":"anchor"} for s,l in srcs.items() if s in REG]
  if extra_src: prov.insert(0,extra_src)
  tag="prv" if typ=="proverb" else "syn"
  return {"id":f"{lang}.{tag}.{hashlib.sha1(text.encode()).hexdigest()[:12]}","lang":lang,"type":typ,"category":cat,"cefr":L,
    "can_do":[CD[typ].format(L=L,c=cat.replace('_',' '))],"text":U.normalize("NFC",text),"source_type":"synthesized" if typ!="proverb" else "attested",
    "translation_en":{"text":en,"alignment":"sentence","status":"needs-review"},"pattern":{"description":note,"description_status":"needs-review"} if note else {"description":None},
    "token_evidence":ev,"provenance":{"sources":prov or [{"source_id":"leipzig","licence":"CC BY","locator":"n/a","role":"anchor"}],"created_at":"2026-10-21","ai_assisted":True},
    "claims":[{"text":f"token '{e['token']}' attested {e['count']}x","source_id":SRCID(e["locator"]),"locator":e["locator"]} for e in ev[:12]],
    "confidence":conf,"risk_tags":["synthesized","naturalness_unverified"]+list(risk)+(["tone_pattern_unverified"] if lang in("yo","ig") else []),
    "status":"needs-review","label":"beta","audio":[],
    "feature_hooks":{"lessons":[f"{lang}.{L}.{cat}"],"games":["translate","cloze"] if typ!="culture_note" else [],"point_and_say":False,"living_dictionary":typ=="proverb","personas":{"register_model":cat in("politeness","culture_note","argumentative"),"level":L}}}
IX={l:json.load(open(f"{R}/synth/index/{l}.json")) for l in D}
for lang,rows in D.items():
  for L,cat,text,en,note in rows:
    ev,miss=check(lang,text)
    if miss: log["rejected"].append({"lang":lang,"level":L,"text":text,"unattested":miss}); continue
    typ=TYPE.get(cat,"sentence")
    out[(lang,L)].append(item(lang,L,typ,cat,text,en,note,ev)); log["accepted"][lang]+=1
for lang,rows in P.items():
  for text,en,L in rows:
    hit=next((v for k,v in H[lang].items() if v and U.normalize("NFC",text).lower().replace(",","") in re.sub(r"[“”‘’\",.;:]","",U.normalize("NFC",v[0])).lower()),None)
    ev,miss=check(lang,text)
    if not hit or miss: log["rejected"].append({"lang":lang,"level":L,"text":text,"unattested":miss or ["verbatim proverb not found"]}); continue
    s=SRCID(hit[1]); risk=["idiom_or_formula","meaning_gloss_unverified"]+(["cited_from_wikipedia_text"] if "wikipedia" in hit[1] else [])
    out[(lang,L)].append(item(lang,L,"proverb","proverb",text,en,None,ev,{"source_id":s,"licence":REG[s]["licence"].split(" (")[0],"locator":f"{hit[1]} :: {hit[0][:160]}","role":"shipped_text" if "wikipedia" not in hit[1] else "cross_check"},risk)); log["accepted"][lang]+=1
for (lang,L),its in out.items():
  f=f"{R}/packs/{lang}/{L}.synth.json"; json.dump({"lang":lang,"level":L,"built":"2026-10-21","source_type":"synthesized","items":its},open(f+".tmp","w"),ensure_ascii=False,indent=0); os.replace(f+".tmp",f)
json.dump({"accepted":log["accepted"],"rejected":log["rejected"]},open(R+"/synth/package_log.json","w"),ensure_ascii=False,indent=1)
print(dict(log["accepted"]))
for r in log["rejected"]: print("REJ",r["lang"],r["text"][:60],r["unattested"])
