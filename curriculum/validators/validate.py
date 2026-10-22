#!/usr/bin/env python3
"""Run all validators over packs/*/*.json; write validators/reports/report.{json,md}. Exit 1 on errors."""
import json,glob,os,re,sys,collections,unicodedata as U
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
import jsonschema
SCH=json.load(open(ROOT+"/schema/item.schema.json")); V=jsonschema.Draft202012Validator(SCH)
def nfd(s): return U.normalize("NFD",s)
def strip(s): return "".join(c for c in nfd(s) if not U.combining(c))
TONE={"\u0300","\u0301","\u0304","\u0302","\u030c"}
def has_tone(s): return any(c in TONE for c in nfd(s))
# allowed letters after NFD (base + combining), per standard orthographies
CH={"yo":set("abdefghijklmnoprstuwy'")|{"\u0323","\u0300","\u0301","\u0304"},
    "ig":set("abcdefghijklmnoprstuvwyz'")|{"\u0323","\u0307","\u0300","\u0301","\u0304"},
    "ha":set("abcdefghijklmnorstuwyzɓɗƙƴ'"),
    "sw":set("abcdefghijklmnoprstuvwyz'"),
    "zu":set("abcdefghijklmnopqrstuvwxyz'"),"xh":set("abcdefghijklmnopqrstuvwxyz'"),"pcm":set("abcdefghijklmnopqrstuvwxyz'")|{"\u0323"}}
PH=re.compile(r"\bword\d|\bexample\b|\bsample\b|lorem|ipsum|TODO|TBD|xxx|\?\?\?",re.I)
WORD=re.compile(r"[^\W\d_](?:[^\W\d_]|[\u0300-\u036f]|['’-](?=[^\W\d_]))*")
# Bantu class -> allowed noun prefixes (standard orthography)
NP={"zu":{"1":("umu","um"),"1a":("u",),"2":("aba","abe"),"2a":("o",),"3":("umu","um","u"),"4":("imi",),"5":("i","ili"),"6":("ama","ame"),"7":("isi","is"),"8":("izi","iz"),"9":("in","im","i"),"10":("izin","izim","izi","i"),"11":("u","ulu","ulw"),"14":("ubu","ub","utshw","utsh","ut"),"15":("uku","uk"),"17":("uku",)},
    "sw":{"1":("m","mw","mu",""),"2":("wa","w",""),"3":("m","mw","mu"),"4":("mi","m"),"5":("",),"6":("ma","me","mw"),"7":("ki","ch"),"8":("vi","vy"),"9":("",),"10":("",),"11":("u","w"),"14":("u",),"15":("ku",),"16":("pa",),"17":("ku",),"18":("mu",)}}
NP["xh"]=dict(NP["zu"]); NP["xh"].update({"10":("izin","izim","izi","iin","ii"),"8":("izi","iz"),"9":("in","im","i"),"14":("ubu","ub","utyw","uty"),"5":("i","ili","ilu")})
SC={"zu":{"1":("u","w","ka"),"2":("ba","b"),"3":("u","w"),"4":("i","y"),"5":("li","l"),"6":("a","w"),"7":("si","s"),"8":("zi","z"),"9":("i","y"),"10":("zi","z"),"11":("lu","lw"),"14":("bu","b"),"15":("ku","kw")}}
SC["xh"]=SC["zu"]
KK={"yo":"Yoruba","ha":"Hausa","sw":"Swahili","zu":"Zulu","xh":"Xhosa"}
def kk_forms(lang):
  f=f"{ROOT}/sources/crosscheck_only/kaikki/{KK[lang]}.jsonl"; s=set()
  for l in open(f): s.add(U.normalize("NFC",json.loads(l)["word"]).lower())
  return s
REG={r["id"]:r for r in json.load(open(ROOT+"/sources/licence_register.json"))}
SHIPOK={"african_voices","cv27_pcm","cv27_xh","synth-v2","cv_sentences","leipzig","asp","sadilar_morph","sadilar_xhmono","fsi"}
E=collections.defaultdict(list); W=collections.defaultdict(list); stats=collections.defaultdict(collections.Counter)
ids={}; texts={}
for f in sorted(glob.glob(ROOT+"/packs/*/*.json")):
  pk=json.load(open(f)); lang=pk["lang"]; lvl=pk["level"]
  kf=kk_forms(lang) if lang in KK else None
  for it in pk["items"]:
    k=f"{lang}/{lvl}/{it['id']}"; st=stats[f"{lang}/{lvl}"]; st["items"]+=1; st[it["status"]]+=1
    for e in V.iter_errors(it): E["schema"].append(f"{k}: {e.message[:120]}")
    strs=[it["text"]]+[t["text"] for t in it.get("turns",[])]
    for s in strs:
      if s!=U.normalize("NFC",s): E["nfc"].append(k)
      if PH.search(s): E["placeholder"].append(f"{k}: {s[:60]}")
    if it["id"] in ids: E["duplicate_id"].append(f"{k} also {ids[it['id']]}")
    ids[it["id"]]=k
    tk=(lang,it["type"],it["text"].lower())
    if tk in texts and it["type"]!="pattern": E["duplicate_text"].append(f"{k} == {texts[tk]}")
    texts[tk]=k
    # policy
    if it["type"] in("pattern","culture_note") and it["status"]=="Beta": E["policy_grammar_culture_beta"].append(k)
    for s in it["provenance"]["sources"]:
      if s.get("role")=="shipped_text" and s["source_id"] not in SHIPOK: E["licence_not_shippable"].append(f"{k}: {s['source_id']}")
      if s["source_id"] not in REG: E["unregistered_source"].append(f"{k}: {s['source_id']}")
    if it["status"]=="Beta" and it["confidence"]<0.9: E["beta_low_confidence"].append(k)
    # orthography
    toks=[it["text"]] if it["type"]=="lexeme" else WORD.findall(" ".join(strs))
    bad=[t for t in toks if set(nfd(t.lower()))-CH[lang]-{"-","’"}]
    if bad:
      if it["type"]=="lexeme": E["orthography_lexeme"].append(f"{k}: {it['text']}")
      else: st["sent_foreign_char_items"]+=1; 
      if it["status"]=="Beta" and it["type"]!="lexeme": W["orthography_beta_sentence"].append(f"{k}: {bad[:3]}")
    # tone marks
    if it["type"]=="lexeme":
      w=it["text"]
      if lang in("ha","sw","zu","xh") and has_tone(w): E["tone_in_untoned_orthography"].append(f"{k}: {w}")
      if lang=="yo":
        if w.lower() in kf: st["tone_lexicon_match"]+=1
        else: st["tone_lexicon_nomatch"]+=1; (E if it["status"]=="Beta" else W)["yo_tone_not_in_lexicon"].append(f"{k}: {w}")
      if lang=="ig" and it["status"]=="Beta": E["ig_beta_without_lexicon"].append(k)
      if kf is not None and it["status"]=="Beta" and w.lower() not in kf: E["beta_not_lexicon_anchored"].append(f"{k}: {w}")
      # Bantu noun-class prefix concord
      nc=it.get("noun_class")
      if nc and nc.get("sg") and lang in NP:
        pre=NP[lang].get(nc["sg"])
        if pre is None: st["nc_unknown_class"]+=1
        elif any(w.lower().startswith(p) for p in pre): st["nc_prefix_ok"]+=1
        else: st["nc_prefix_bad"]+=1; (E if it["status"]=="Beta" else W)["noun_class_prefix"].append(f"{k}: {w} class {nc['sg']}")
        if nc.get("sadilar_agrees") is True: st["nc_sadilar_agree"]+=1
        if nc.get("sadilar_agrees") is False: st["nc_sadilar_disagree"]+=1
# sentence-level subject concord (zu/xh): noun of known class directly followed by a word = informational rate
for lang in ("zu","xh"):
  cls={}
  for f in glob.glob(f"{ROOT}/packs/{lang}/*.json"):
    for it in json.load(open(f))["items"]:
      if it.get("noun_class") and it["noun_class"].get("sg"): cls[it["text"].lower()]=it["noun_class"]["sg"]
  ok=tot=0
  for f in glob.glob(f"{ROOT}/packs/{lang}/*.json"):
    for it in json.load(open(f))["items"]:
      if it["type"]!="sentence": continue
      t=[x.lower() for x in WORD.findall(it["text"])]
      for a,b in zip(t,t[1:]):
        c=cls.get(a)
        if c in SC[lang] and len(b)>3 and not b.startswith(("u","i","a","o","e")) or (c in SC[lang] and b[:2] in ("ya","ba","za","sa","la","wa","ka")):
          tot+=1; ok+=any(b.startswith(p) or b.startswith("a"+p) for p in SC[lang][c]) or b.startswith(("ka","ya","ba","za","sa","la","wa","lwa","bwa","kwa"))
  stats[f"{lang}/_concord"].update({"noun_verb_pairs_checked":tot,"subject_concord_consistent":ok})
rep={"errors":{k:len(v) for k,v in E.items()},"warnings":{k:len(v) for k,v in W.items()},"stats":{k:dict(v) for k,v in stats.items()},
     "error_samples":{k:v[:15] for k,v in E.items()},"warning_samples":{k:v[:10] for k,v in W.items()}}
os.makedirs(ROOT+"/validators/reports",exist_ok=True)
json.dump(rep,open(ROOT+"/validators/reports/report.json","w"),ensure_ascii=False,indent=1)
with open(ROOT+"/validators/reports/report.md","w") as f:
  f.write("# Validator report\n\nErrors: "+json.dumps(rep["errors"],ensure_ascii=False)+"\n\nWarnings: "+json.dumps(rep["warnings"],ensure_ascii=False)+"\n\n| pack | stats |\n|---|---|\n")
  for k,v in sorted(rep["stats"].items()): f.write(f"| {k} | {json.dumps(v)} |\n")
  for k,v in rep["error_samples"].items(): f.write(f"\n## ERROR {k}\n"+"\n".join("- "+x for x in v)+"\n")
  for k,v in rep["warning_samples"].items(): f.write(f"\n## warn {k}\n"+"\n".join("- "+x for x in v)+"\n")
print(json.dumps({"errors":rep["errors"],"warnings":rep["warnings"]},ensure_ascii=False))
sys.exit(1 if E else 0)
