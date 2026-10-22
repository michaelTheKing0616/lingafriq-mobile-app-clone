import sys,re,json,unicodedata as U
sys.path.insert(0,"synth"); from attest import texts
def k(s): return re.sub(r"[^a-z ]","",re.sub(r"\s+"," ","".join(c for c in U.normalize("NFD",s.lower()) if not U.combining(c)).replace("ɓ","b").replace("ɗ","d").replace("ƙ","k")))
C=json.load(open("synth/proverb_candidates.json")); out={}
for lang,cands in C.items():
  keys={c:k(c) for c in cands}; hits={}
  for t,loc in texts(lang):
    kt=k(t)
    for c,kc in keys.items():
      if c not in hits and kc in kt: hits[c]=(re.sub(r"\s+"," ",t.strip())[:220],loc)
    if len(hits)==len(keys): break
  out[lang]={c:hits.get(c) for c in cands}
  for c in cands: print(lang,"|",c,"=>",hits.get(c))
json.dump(out,open("synth/proverb_hits.json","w"),ensure_ascii=False,indent=1)
