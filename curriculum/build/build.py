#!/usr/bin/env python3
"""Source-grounded curriculum pack builder. Never invents words/tones: every target-language
string is copied verbatim (NFC) from a shipped CC BY / PD source; Kaikki (CC BY-SA) is anchor/cross-check only.
Usage: build.py [LEVEL ...]   (default all levels; writes packs/<lang>/<LEVEL>.json per level = checkpoint)"""
import json,re,os,sys,glob,hashlib,unicodedata as U,collections,datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); S=ROOT+"/sources"
NOW=datetime.date(2026,10,21).isoformat()
LEVELS=["A1","A2","B1","B2","C1","C2"]
# anchored-lemma frequency bands (cumulative rank among anchored lemmas)
BANDS={"A1":(0,800),"A2":(800,1600),"B1":(1600,3200),"B2":(3200,5200),"C1":(5200,8200),"C2":(8200,12000)}
SENT_LEN={"A1":(3,8),"A2":(5,11),"B1":(7,15),"B2":(9,20),"C1":(12,28),"C2":(15,40)}
SENT_PER={"A1":600,"A2":900,"B1":1500,"B2":1500,"C1":1500,"C2":1500}
CFG={
 "yo":dict(leip=["yor_community_2017","yor_wikipedia_2021_10K"],kk="Yoruba",asp="yo",fsi="yo",tonal_written=True),
 "ig":dict(leip=["ibo_community_2017","ibo_wikipedia_2021_10K"],kk=None,asp=None,fsi="ig",tonal_written=True),
 "ha":dict(leip=["hau_community_2017"],kk="Hausa",asp="ha",fsi="ha",tonal_written=False),
 "pcm":dict(leip=["pcm_community_2017"],kk=None,asp=None,fsi=None,tonal_written=False),
 "sw":dict(leip=["swa_community_2017","swa_wikipedia_2021_100K"],kk="Swahili",asp="sw",fsi="sw",tonal_written=False,bantu=True),
 "zu":dict(leip=["zul_community_2017","zul_mixed_2014_100K"],kk="Zulu",asp="zu",fsi=None,tonal_written=False,bantu=True,sad="zu"),
 "xh":dict(leip=["xho_community_2017","xho-za_web_2018_30K"],kk="Xhosa",asp="xh",fsi=None,tonal_written=False,bantu=True,sad="xh"),
}
EXCL=re.compile(r"wikipedia|wiki|bible|jw\.org|jw-|watchtower|biblica|ebible|bibles\.|scripture|church|dating|sex|porn|casino|loan",re.I)
WORD=re.compile(r"[^\W\d_](?:[^\W\d_]|[\u0300-\u036f]|['’-](?=[^\W\d_]))*")
PCM=re.compile(r"\b(dey|wey|wetin|una|pikin|sabi|abeg|wahala|naim|dem go|don go|na im|oga|sef|abi|chop|comot|waka|wan|una|e don|no be|go dey)\b",re.I)
N=lambda s:U.normalize("NFC",s)
def strip(s): return "".join(c for c in U.normalize("NFD",s) if not U.combining(c)).replace("’","'")
def hid(lang,t,key): return f"{lang}.{t}.{hashlib.sha1(key.encode()).hexdigest()[:12]}"
TONE={"\u0300","\u0301","\u0304","\u0302","\u030c"}
def has_tone(s): return any(c in TONE for c in U.normalize("NFD",s))
CANDO={
 "lex":"{L}.LEX: Recognise and use high-frequency words of band {L}",
 "Family":"A1.FAM: Talk about family members","Colors":"A1.COL: Name colours","Body parts":"A1.BODY: Name parts of the body",
 "Foods":"A1.FOOD: Name common foods and drinks","Animals":"A1.ANI: Name common animals","Days of the week":"A1.TIME: Say days and times",
 "Times of day":"A1.TIME: Say days and times","Time":"A1.TIME: Say days and times","cardinal numbers":"A1.NUM: Count and use numbers",
 "greetings":"A1.GREET: Greet people and take leave","sen":"{L}.READ: Understand authentic sentences of level {L}",
 "pat":"{L}.GRAM: Recognise and use grammar pattern","dlg":"{L}.INT: Follow a short exchange","cul":"{L}.CULT: Understand a cultural practice",
 "idiom":"{L}.IDIOM: Understand idioms and proverbs in context"}
TOPICAL_A1=[k for k in CANDO if k[0].isupper() or k in("cardinal numbers","greetings")]
REG={r["id"]:r for r in json.load(open(S+"/licence_register.json"))}
def src(i,loc,role="shipped_text"): return {"source_id":i,"licence":REG[i]["licence"].split(" (")[0].split(";")[0],"locator":loc,"role":role}

def load(lang):
  c=CFG[lang]; R=dict(av=[],cv=[],cvfreq=collections.Counter(),freq=collections.Counter(),sents=[],kk={},kk_ascii=collections.defaultdict(set),asp=[],sad={})
  for name in c["leip"]:
    d=f"{S}/raw/leipzig/{name}/{name}"
    srcurl={}
    for l in open(d+"-sources.txt",encoding="utf-8",errors="replace"):
      p=l.rstrip("\n").split("\t"); srcurl[p[0]]=p[1] if len(p)>1 else ""
    s2src={}
    for l in open(d+"-inv_so.txt"):
      a,b=l.split("\t")[:2]; s2src.setdefault(b.strip(),a)
    for l in open(d+"-sentences.txt",encoding="utf-8",errors="replace"):
      p=l.rstrip("\n").split("\t")
      if len(p)<2: continue
      t=re.sub(r"\s+"," ",N(p[1])).strip(); t=re.sub(r"^\(?\d+[.)]\s*","",t); url=srcurl.get(s2src.get(p[0],""),"")
      if lang=="pcm" and not PCM.search(t): continue
      for w in WORD.findall(t): R["freq"][w.lower()]+=1
      if url.startswith("http") and not EXCL.search(url): R["sents"].append((t,f"{name}#s{p[0]} <{url}>"))
  if c["kk"]:
    for l in open(f"{S}/crosscheck_only/kaikki/{c['kk']}.jsonl"):
      d=json.loads(l); w=N(d["word"]); R["kk"].setdefault(w.lower(),[]).append(d); R["kk_ascii"][strip(w).lower()].add(w.lower())
  if c["asp"]:
    en={os.path.basename(f).split("_")[0]:f for f in glob.glob(f"{S}/raw/asp/en/*.md")}
    for f in sorted(glob.glob(f"{S}/raw/asp/{c['asp']}/*.md")):
      txt=N(open(f).read()); 
      if "License: [CC-BY]" not in txt and "License: [CC BY]" not in txt: continue
      pages=[p.strip() for p in txt.split("\n##")[1:] if p.strip() and not p.strip().startswith("*")]
      title=txt.split("\n",1)[0].lstrip("# ").strip(); credits=re.findall(r"^\* (Text|Illustration|Translation): (.*)$",txt,re.M)
      enp=None; sid=os.path.basename(f).split("_")[0]
      if sid in en:
        et=open(en[sid]).read(); enp=[p.strip() for p in et.split("\n##")[1:] if p.strip() and not p.strip().startswith("*")]
        if len(enp)!=len(pages): enp=None
      R["asp"].append(dict(file=os.path.relpath(f,S),title=title,pages=pages,en=enp,credits="; ".join(f"{a}: {b}" for a,b in credits)))
      for p in pages:
        for w in WORD.findall(p): R["freq"][w.lower()]+=1
  cvf=f"{S}/raw/commonvoice/{lang}_sentence-collector.txt"
  if os.path.exists(cvf):
    for i,l in enumerate(open(cvf,encoding="utf-8",errors="replace"),1):
      t=re.sub(r"\s+"," ",N(l)).strip()
      if not t: continue
      for w in WORD.findall(t): R["freq"][w.lower()]+=1; R["cvfreq"][w.lower()]+=1
      R["cv"].append((t,f"{lang}_sentence-collector.txt line {i}"))
  AV={"pcm":"naija_african_voices","yo":"yoruba_african_voices","ha":"hausa_african_voices","ig":"igbo_african_voice"}
  avf=f"{S}/raw/african_voices/{lang}_transcripts.jsonl"
  if lang in AV:
    seen_av=set()
    import itertools
    for l in itertools.chain(*(open(x) for x in [avf]*os.path.exists(avf)+sorted(glob.glob(f"{S}/raw/african_voices/parts/{lang}/*.jsonl")))):
      try: r=json.loads(l)
      except Exception: continue
      if r.get("type")!="read" and lang not in("yo","ig"): continue
      t=re.sub(r"\s+"," ",N(r.get("transcript") or "")).strip()
      if not t or "[" in t or t.lower() in seen_av: continue
      seen_av.add(t.lower())
      for w in WORD.findall(t): R["freq"][w.lower()]+=1
      R["av"].append((t,f"{AV[lang]} audio_id={r['audio_id']} type={r.get('type')}"))
  if lang=="xh":
    f=glob.glob(f"{S}/raw/sadilar/xhmono_*.txt")[0]
    for i,l in enumerate(open(f,encoding="utf-8",errors="replace"),1):
      t=N(l.strip()); t=re.sub(r"\s+([.,!?;:])",r"\1",t)
      for w in WORD.findall(t): R["freq"][w.lower()]+=1
      if t[:1].isupper() and t[-1:] in ".!?" and "'" not in t: R["sents"].append((t,f"SADILAR_XHMONO line {i}"))
  if c.get("sad"):
    for l in open(glob.glob(f"{S}/raw/sadilar/{c['sad']}_SADII*.txt")[0],encoding="utf-8",errors="replace"):
      p=l.rstrip("\n").split("\t")
      if len(p)==2:
        m=re.match(r"[^\[\]-]+\[NPrePre(\d+a?)\]|[^\[\]-]+\[BPre(\d+a?)\]",p[1])
        if m and "[NStem]" in p[1]: R["sad"].setdefault(N(p[0]).lower(),collections.Counter())[m.group(1) or m.group(2)]+=1
  return R

GOODPOS={"noun","verb","adj","adv","pron","num","conj","prep","postp","particle","det","intj","phrase","prep_phrase","proverb","adv_phrase","name"}
def gloss(d):
  for s in d.get("senses",[]):
    if "form-of" in s.get("tags",[]) or "alt-of" in s.get("tags",[]): return None,s.get("glosses",[""])[0]
    g=s.get("glosses",[None])[0]
    if g: g=re.sub(r"\s*\([^)]*\)","",g).strip().rstrip("."); return (g if 0<len(g.split())<=3 else None),g
  return None,None
def nclass(d):
  sg=pl=pf=None
  for f in d.get("forms",[]):
    for t in f.get("tags",[]):
      if t.startswith("class-"):
        if "plural" in f.get("tags",[]): pl=t[6:]; pf=N(f["form"])
        elif sg is None: sg=t[6:]
  for s in d.get("senses",[]):
    for t in s.get("tags",[]):
      if t.startswith("class-") and sg is None: sg=t[6:]
  return (dict(sg=sg,pl=pl,plural_form=pf) if sg else None)
ROMAN={"i":"1","ii":"2","iii":"3","iv":"4","v":"5","vi":"6","vii":"7","viii":"8","ix":"9","x":"10","xi":"11","xii":"12","xiv":"14","xv":"15","xvi":"16","xvii":"17","xviii":"18"}
def cnum(c): return ROMAN.get(c,c) if c else None

def lexemes(lang,R):
  """all anchored candidates ranked by corpus frequency; cached"""
  out=[]; c=CFG[lang]; seen=set()
  for rank,(w,n) in enumerate(R["freq"].most_common(),1):
    if n<2 or len(strip(w))<2 or not re.search(r"[aeiouɛɔ]",strip(w)) or w in seen or not w.isalpha() and not re.fullmatch(r"[\w\u0300-\u036f'’-]+",w): continue
    seen.add(w); entries=R["kk"].get(w,[]) if R["kk"] else []
    entries=[e for e in entries if e.get("pos") in GOODPOS and e.get("pos")!="name"]
    if R["kk"] and not entries:
      # Hausa Kaikki headwords are plain standard spelling; Yoruba requires exact toned form
      continue
    out.append((w,n,entries))
    if len(out)>=(12000 if R["kk"] else {"ig":300,"pcm":1500}[lang]): break
  if lang in("yo","ig"):
    have={w for w,_,_ in out}; cap={"yo":8000,"ig":5000}[lang]
    for w,n in R["freq"].most_common():
      if len(out)>=cap: break
      if n>=3 and w not in have and R["cvfreq"][w]>=2 and len(strip(w))>=2 and (lang!="yo" or has_tone(w)) and re.search(r"[aeiouɛɔ]",strip(w)): out.append((w,n,[])); have.add(w)
  if R["sad"]:
    have={w for w,_,_ in out}
    for w,n in R["freq"].most_common():
      if len(out)>=12000: break
      if n>=3 and w not in have and w in R["sad"] and sum(R["sad"][w].values())>=2: out.append((w,n,[]))
  return out

def lex_item(lang,R,w,n,entries,rank,level):
  c=CFG[lang]; risk=[]; claims=[]; srcs=[]
  e=entries[0] if entries else None
  g,raw=gloss(e) if e else (None,None)
  pos=e.get("pos") if e else None
  nc=nclass(e) if (e and c.get("bantu") and pos=="noun") else None
  if not e and R["sad"].get(w): pos="noun"; nc={"sg":R["sad"][w].most_common(1)[0][0],"pl":None,"plural_form":None}
  agrees=None
  if nc and c.get("sad") and w in R["sad"]:
    agrees=R["sad"][w].most_common(1)[0][0]==cnum(nc["sg"]); nc["sadilar_agrees"]=agrees
    srcs.append(src("sadilar_morph",f"token '{w}' noun class {R['sad'][w].most_common(1)[0][0]}","anchor"))
  if nc: nc={"sg":cnum(nc["sg"]),"pl":cnum(nc["pl"]),"plural_form":nc["plural_form"] if nc["plural_form"] and not has_tone(nc["plural_form"]) else (strip(nc["plural_form"]) if nc["plural_form"] and lang in("zu","xh") else nc["plural_form"]),"sadilar_agrees":agrees}
  srcs.insert(0,src("leipzig",f"corpus frequency {n} (combined {'+'.join(c['leip'])}{' + ASP CC BY stories' if c['asp'] else ''})"))
  claims.append({"text":f"'{w}' attested {n}x in CC BY corpus","source_id":"leipzig","locator":"words.txt"})
  if e:
    srcs.append(src("kaikki",f"en.wiktionary '{e['word']}' ({pos})","cross_check"))
    if raw: claims.append({"text":f"gloss: {raw}","source_id":"kaikki","locator":f"wiktionary:{e['word']}#{pos}"})
  if len({x.get('pos') for x in entries})>1 or sum(len(x.get('senses',[])) for x in entries)>3: risk.append("polysemous")
  if pos in("intj","phrase","proverb"): risk.append("idiom_or_formula" if pos!="intj" else "pragmatic_use")
  if lang=="yo" and len(R["kk_ascii"].get(strip(w),()))>1: risk.append("tone_homograph")
  if lang=="ig": risk+=["tone_unverified","no_lexicon_source"]
  if lang=="pcm": risk+=["no_lexicon_source","orthography_variable"]
  if raw and g is None: risk.append("gloss_needs_editing")
  if not e and (R["sad"].get(w) or lang=="yo"): risk.append("no_gloss_source")
  if agrees is False: risk.append("noun_class_conflict")
  conf=0.0
  if e: conf+=0.35
  conf+=0.3 if n>=20 else (0.25 if n>=3 else 0.1)
  if g: conf+=0.2
  if "polysemous" not in risk: conf+=0.1
  conf+=0.05 if (agrees is not False) else 0
  conf=round(min(conf,1.0),2)
  HIGH={"no_gloss_source","tone_homograph","idiom_or_formula","pragmatic_use","tone_unverified","no_lexicon_source","noun_class_conflict","gloss_needs_editing"}
  beta=conf>=0.9 and not (set(risk)&HIGH) and (lang!="yo" or True)
  # Hausa: standard orthography (no tone marks) shipped; tones withheld
  tw=None
  if lang=="ha": tw="Hausa standard orthography does not mark tone/length; source tone data is CC BY-SA cross-check only"
  if lang in("zu","xh","sw"): tw="standard orthography does not mark tone"
  cd=[CANDO["lex"].format(L=level)]
  if e:
    for s in e.get("senses",[]):
      for k in s.get("categories",[]):
        for t in TOPICAL_A1:
          if t in k["name"] and CANDO[t] not in cd: cd.append(CANDO[t])
  if "idiom_or_formula" in risk: cd.append(CANDO["idiom"].format(L=level))
  games=["flashcards","listen_and_choose" if False else "spelling"]+(["match_meaning"] if g else [])
  return {"id":hid(lang,"lex",w+"|"+(pos or "")),"lang":lang,"type":"lexeme","cefr":level,"can_do":cd,"text":w,
   "orthography":{"standard":w,"ascii_fallback":strip(w),"script":"Latn","tone_marked":has_tone(w),"tones_withheld_reason":tw},
   "pos":pos,"noun_class":nc,"senses":[{"gloss_en":g,"gloss_status":"beta" if (g and beta) else "needs-review"}],
   "frequency_rank":rank,"corpus_count":n,"examples":[],
   "provenance":{"sources":srcs,"created_at":NOW,"ai_assisted":False},"claims":claims,"confidence":conf,"risk_tags":risk,
   "status":"Beta" if beta else "needs-review","label":"beta","audio":[],
   "feature_hooks":{"lessons":[f"{lang}.{level}.vocab"],"games":games,"point_and_say":bool(pos=="noun" and any("CANDO" for _ in [0]) and len(cd)>1),
     "living_dictionary":True,"personas":{"vocab_whitelist":beta,"level":level}}}

def sent_items(lang,R,level,lexset,used):
  lo,hi=SENT_LEN[level]; out=[]
  pool=[]
  for st in R["asp"]:
    for i,p in enumerate(st["pages"]):
      for s in re.split(r"(?<=[.!?])\s+",p) if level in("A1","A2") else [p]:
        pool.append((re.sub(r"\s+"," ",s).strip(),"asp",f"{st['file']} p{i+1}; {st['credits']}",(st["en"][i] if st["en"] else None),st))
  for t,loc in R["cv"]: pool.append((t,"cv_sentences",loc,None,None))
  for t,loc in R["av"]: pool.append((t,"african_voices",loc,None,None))
  for t,loc in R["sents"]: pool.append((t,"sadilar_xhmono" if loc.startswith("SADILAR_XHMONO") else "leipzig",loc,None,None))
  for t,sid,loc,en,st in pool:
    toks=WORD.findall(t)
    if lang=="pcm" and sid=="leipzig" and len(out)>=40: break
    if not(lo<=len(toks)<=hi) or t in used or re.search(r"https?:|@|\d{4,}|[<>{}|]",t): continue
    known=sum(1 for x in toks if x.lower() in lexset)/len(toks)
    if known<(0.6 if level in("A1","A2") else 0.4): continue
    used.add(t); risk=[]; tr=None
    if en: tr={"text":N(en),"alignment":"page","status":"needs-review"}
    if sid in("leipzig","sadilar_xhmono"): risk.append("web_text_unreviewed")
    if CFG[lang]["tonal_written"] and lang=="yo" and not has_tone(t): risk.append("missing_tone_marks")
    if lang=="ig": risk.append("tone_unverified")
    if lang=="pcm": risk.append("orthography_variable")
    if "type=spontaneous" in loc: risk.append("spontaneous_speech")
    conf=round(0.6+0.3*known+(0.1 if sid in("asp","cv_sentences","african_voices") else 0),2)
    beta=sid in("asp","cv_sentences","african_voices") and not risk and conf>=0.9
    out.append({"id":hid(lang,"sen",t),"lang":lang,"type":"sentence","cefr":level,"can_do":[CANDO["sen"].format(L=level)],"text":t,
      "translation_en":tr,"provenance":{"sources":[src(sid,loc)],"created_at":NOW,"ai_assisted":False},
      "claims":[{"text":"verbatim source sentence","source_id":sid,"locator":loc}],"confidence":min(conf,1.0),"risk_tags":risk,
      "status":"Beta" if beta else "needs-review","label":"beta","audio":[],
      "feature_hooks":{"lessons":[f"{lang}.{level}.reading"],"games":["word_order","cloze"],"point_and_say":False,"living_dictionary":True,"personas":{"example_bank":beta,"level":level}},
      "_toks":[x.lower() for x in toks]})
    if len(out)>=SENT_PER[level]: break
  return out

def dialogues(lang,R,level):
  out=[]
  if level not in("A1","A2","B1"): return out
  for st in R["asp"]:
    q=[(i,m) for i,p in enumerate(st["pages"]) for m in re.findall(r"[“\"]([^”\"]{3,160})[”\"]",p)]
    if len(q)<2: continue
    n=len(" ".join(st["pages"]).split()); lv="A1" if n<250 else ("A2" if n<600 else "B1")
    if lv!=level: continue
    out.append({"id":hid(lang,"dlg",st["file"]),"lang":lang,"type":"dialogue","cefr":level,"can_do":[CANDO["dlg"].format(L=level)],
     "text":st["title"],"turns":[{"speaker":None,"text":m.strip()} for _,m in q[:12]],
     "translation_en":None,"provenance":{"sources":[src("asp",f"{st['file']} pages {sorted({i+1 for i,_ in q[:12]})}; {st['credits']}")],"created_at":NOW,"ai_assisted":False},
     "claims":[{"text":"quoted speech copied verbatim from CC BY story","source_id":"asp","locator":st["file"]}],
     "confidence":0.7,"risk_tags":["speaker_attribution_unverified","narrative_dialogue"],"status":"needs-review","label":"beta","audio":[],
     "feature_hooks":{"lessons":[f"{lang}.{level}.dialogue"],"games":["role_play"],"point_and_say":False,"living_dictionary":False,"personas":{"scene_seed":True,"level":level}}})
  return out[:25]

def fsi_items(lang,level):
  c=CFG[lang]; f=f"{S}/raw/fsi/{c['fsi']}_basic.ocr.txt" if c["fsi"] else None
  if not f or not os.path.exists(f): return []
  pages=re.split(r"=====PAGE (\d+)\n",open(f,errors="replace").read())[1:]
  pages=list(zip(pages[0::2],pages[1::2])); tot=len(pages); out=[]
  rng={"A1":(0,.3),"A2":(.3,.6),"B1":(.6,1.01)}.get(level)
  if not rng: return []
  for pg,txt in pages:
    pos=int(pg)/tot
    if not(rng[0]<=pos<rng[1]): continue
    for m in re.finditer(r"(?m)^\s*(?:\w{1,3}\s)?((?:NOTES?S?|Notes?s?|GRAMMATICAL [A-Z]+|Grammar[^\n]{0,60}|GRAMMAR[^\n]{0,60}|Key Word Pattern|Pronunciation Structure|Structure[^\n]{0,40}))\.?\s*\n((?:.*\n){1,12})",txt):
      body=re.sub(r"\s+"," ",m.group(2)).strip()[:700]; head=re.sub(r"\s+"," ",m.group(1)).strip().title()+": "+body[:70]
      if len(body)<60: continue
      out.append({"id":hid(lang,"pat",f"{pg}|{head}"),"lang":lang,"type":"pattern","cefr":level,"can_do":[CANDO["pat"].format(L=level)],
       "text":head,"pattern":{"form":None,"description":None,"examples":[],"evidence_excerpt_en_ocr":body},
       "provenance":{"sources":[src("fsi",f"{c['fsi']}_basic.pdf page {pg}")],"created_at":NOW,"ai_assisted":False},
       "claims":[{"text":"grammar topic located in FSI Basic Course (OCR, English model)","source_id":"fsi","locator":f"page {pg}"}],
       "confidence":0.5,"risk_tags":["grammar_explanation","ocr_text","target_diacritics_unreliable"],"status":"needs-review","label":"beta","audio":[],
       "feature_hooks":{"lessons":[f"{lang}.{level}.grammar"],"games":[],"point_and_say":False,"living_dictionary":False,"personas":{"grammar_focus":True,"level":level}}})
    for m in re.finditer(r"(?im)^([^\n]{0,60}\b(?:custom|customs|culture|cultural|etiquette|greeting|respect|polite)\b[^\n]{0,60})\n((?:.*\n){1,6})",txt):
      body=re.sub(r"\s+"," ",m.group(1)+" "+m.group(2)).strip()[:600]
      if len(body)<120: continue
      out.append({"id":hid(lang,"cul",f"{pg}|{body[:40]}"),"lang":lang,"type":"culture_note","cefr":level,"can_do":[CANDO["cul"].format(L=level)],
       "text":f"FSI cultural note p{pg}: {body[:60]}","pattern":{"evidence_excerpt_en_ocr":body},
       "provenance":{"sources":[src("fsi",f"{c['fsi']}_basic.pdf page {pg}")],"created_at":NOW,"ai_assisted":False},
       "claims":[{"text":"cultural statement in FSI course (1960s-era)","source_id":"fsi","locator":f"page {pg}"}],
       "confidence":0.4,"risk_tags":["culture_claim","dated_source","ocr_text"],"status":"needs-review","label":"beta","audio":[],
       "feature_hooks":{"lessons":[f"{lang}.{level}.culture"],"games":[],"point_and_say":False,"living_dictionary":False,"personas":{"culture_context":True,"level":level}}})
  return out[:150]

def noun_class_patterns(lang,lex,level):
  if not CFG[lang].get("bantu") or level not in("A1","A2"): return []
  g=collections.defaultdict(list)
  for it in lex:
    nc=it.get("noun_class")
    if nc and nc["sg"] and it["status"]=="Beta": g[(nc["sg"],nc["pl"])].append(it)
  out=[]
  for (sg,pl),its in sorted(g.items(),key=lambda x:-len(x[1])):
    if len(its)<3: continue
    ex=[f"{i['text']} → {i['noun_class']['plural_form']}" if i['noun_class']['plural_form'] else i['text'] for i in its[:8]]
    out.append({"id":hid(lang,"pat",f"nc{sg}/{pl}|{level}"),"lang":lang,"type":"pattern","cefr":level,"can_do":[CANDO["pat"].format(L=level)],
     "text":f"Noun class {sg}" + (f"/{pl}" if pl else ""),"pattern":{"form":f"class {sg} singular"+(f", class {pl} plural" if pl else ""),"description":None,"examples":ex,"example_ids":[i["id"] for i in its[:8]]},
     "provenance":{"sources":[src("leipzig","attested forms"),src("kaikki","noun class tags","cross_check")]+([src("sadilar_morph","class annotations","anchor")] if CFG[lang].get("sad") else []),"created_at":NOW,"ai_assisted":False},
     "claims":[{"text":f"{len(its)} pack nouns tagged class {sg}","source_id":"kaikki","locator":"forms[].tags class-*"}],
     "confidence":0.75,"risk_tags":["grammar_explanation"],"status":"needs-review","label":"beta","audio":[],
     "feature_hooks":{"lessons":[f"{lang}.{level}.grammar"],"games":["sort_by_class"],"point_and_say":False,"living_dictionary":False,"personas":{"grammar_focus":True,"level":level}}})
  return out

CACHE={}
def build(level):
  li=LEVELS.index(level); summary={}
  for lang in [l for l in CFG if l in os.environ.get("LANGS",",".join(CFG)).split(",")]:
    if lang not in CACHE:
      R=load(lang); CACHE[lang]=(R,lexemes(lang,R),set())
    R,cands,used=CACHE[lang]
    a,b=BANDS[level]
    lex=[lex_item(lang,R,w,n,e,a+i+1,level) for i,(w,n,e) in enumerate(cands[a:b])]
    known={w for w,_,_ in cands[:b]}
    sents=sent_items(lang,R,level,known,used)
    idx={x["text"]:x for x in lex}
    for s in sents:
      for t in s.pop("_toks"):
        if t in idx and len(idx[t]["examples"])<3: idx[t]["examples"].append(s["id"])
    items=lex+sents+dialogues(lang,R,level)+fsi_items(lang,level)+noun_class_patterns(lang,lex,level)
    # dedupe by id
    seen=set(); items=[x for x in items if not(x["id"] in seen or seen.add(x["id"]))]
    os.makedirs(f"{ROOT}/packs/{lang}",exist_ok=True)
    tmp=f"{ROOT}/packs/{lang}/{level}.json.tmp"
    json.dump({"lang":lang,"level":level,"built":NOW,"items":items},open(tmp,"w"),ensure_ascii=False,indent=0)
    os.replace(tmp,f"{ROOT}/packs/{lang}/{level}.json")
    cnt=collections.Counter((x["type"],x["status"]) for x in items); summary[lang]={f"{t}:{s}":n for (t,s),n in sorted(cnt.items())}
    print(level,lang,len(items),dict(summary[lang]),flush=True)
  pass
if __name__=="__main__":
  for L in (sys.argv[1:] or LEVELS): build(L)
