"""Build attested-token index per language from shippable/attested sources (Leipzig all sentences, CV CC0, ASP CC BY, SADiLaR).
token(lower,NFC) -> [count, first locator]. Also used to grep proverb candidates."""
import json,glob,re,os,sys,unicodedata as U
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); S=R+"/sources/raw"
WORD=re.compile(r"[^\W\d_](?:[^\W\d_]|[\u0300-\u036f]|['’-](?=[^\W\d_]))*")
LEIP={"yo":"yor","ig":"ibo","ha":"hau","pcm":"pcm","sw":"swa","zu":"zul","xh":"xho"}
def texts(lang):
  for d in glob.glob(f"{S}/leipzig/{LEIP[lang]}*/"):
    n=os.path.basename(d.rstrip("/"))
    for l in open(f"{d}{n}-sentences.txt",errors="replace"):
      p=l.rstrip("\n").split("\t")
      if len(p)>1: yield p[1],f"leipzig:{n}#s{p[0]}"
  f=f"{S}/commonvoice/{lang}_sentence-collector.txt"
  if os.path.exists(f):
    for i,l in enumerate(open(f),1): yield l,f"cv_sentences:{lang}#L{i}"
  for f in glob.glob(f"{S}/asp/{lang}/*.md"):
    t=open(f).read()
    if "License: [CC-BY]" in t or "License: [CC BY]" in t: yield t,f"asp:{os.path.basename(f)}"
  for f in glob.glob(f"{S}/sadilar/{lang}*.txt"):
    for i,l in enumerate(open(f,errors="replace"),1): yield l.split("\t")[0],f"sadilar:{os.path.basename(f)[:20]}#L{i}"
if __name__=="__main__":
  os.makedirs(R+"/synth/index",exist_ok=True)
  for lang in LEIP:
    ix={}
    for t,loc in texts(lang):
      for w in WORD.findall(U.normalize("NFC",t)):
        w=w.lower(); 
        if w in ix: ix[w][0]+=1
        else: ix[w]=[1,loc]
    json.dump(ix,open(f"{R}/synth/index/{lang}.json","w"),ensure_ascii=False)
    print(lang,len(ix))
