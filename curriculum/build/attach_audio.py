"""Link CV27 CC0 clips (link-only, not re-hosted) to items whose text matches a validated clip sentence."""
import json,glob,os,re,unicodedata as U,collections
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
n=lambda s:re.sub(r"[^\w\s]","",U.normalize("NFC",s).lower()).split()
cnt=collections.Counter()
for lang in ("pcm","xh"):
  clips=collections.defaultdict(list)
  for l in list(open(f"{R}/sources/raw/commonvoice/cv27/{lang}/validated.tsv"))[1:]:
    p=l.rstrip("\n").split("\t"); clips[" ".join(n(p[3]))].append(p[1])
  for f in glob.glob(f"{R}/packs/{lang}/*.json"):
    pk=json.load(open(f)); ch=False
    for it in pk["items"]:
      k=" ".join(n(it["text"]))
      if k in clips:
        it["audio"]=[{"uri":f"cv27:{lang}/clips/{c}","licence":"CC0","kind":"human","source_id":f"cv27_{lang}"} for c in clips[k][:3]]; cnt[lang]+=len(it["audio"]); cnt[lang+"_items"]+=1; ch=True
    if ch: json.dump(pk,open(f+".tmp","w"),ensure_ascii=False,indent=0); os.replace(f+".tmp",f)
AV={"pcm":"naija_african_voices","yo":"yoruba_african_voices","ha":"hausa_african_voices","ig":"igbo_african_voice"}
for lang,ds in AV.items():
  f=f"{R}/sources/raw/african_voices/{lang}_transcripts.jsonl"
  clips=collections.defaultdict(list)
  for l in __import__("itertools").chain(*(open(x) for x in [f]*os.path.exists(f)+sorted(glob.glob(f"{R}/sources/raw/african_voices/parts/{lang}/*.jsonl")))):
    try: r=json.loads(l)
    except Exception: continue
    ap=r.get("audio_path"); ap=ap.get("path") if isinstance(ap,dict) else ap
    k=" ".join(n(r.get("transcript") or ""))
    if k and len(clips[k])<3: clips[k].append(ap or r["audio_id"])
  for pf in glob.glob(f"{R}/packs/{lang}/*.json"):
    pk=json.load(open(pf)); ch=False
    for it in pk["items"]:
      k=" ".join(n(it["text"]))
      if k in clips:
        have={a["uri"] for a in it.get("audio",[])}
        for c in clips[k]:
          u=f"hf://datasets/Africanvoice/{ds}/{c}"
          if u not in have: it.setdefault("audio",[]).append({"uri":u,"licence":"CC BY 4.0","kind":"human","source_id":"african_voices"}); cnt[lang+"_av"]+=1; ch=True
    if ch: json.dump(pk,open(pf+".tmp","w"),ensure_ascii=False,indent=0); os.replace(pf+".tmp",pf)
print(dict(cnt))
