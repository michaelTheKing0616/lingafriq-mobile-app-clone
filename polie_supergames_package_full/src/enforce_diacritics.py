# src/enforce_diacritics.py (enhanced)
import unicodedata, json, os, time
from typing import Tuple, Dict, Optional
from difflib import SequenceMatcher

# Try to use rapidfuzz if installed for better fuzzy matching
USE_RAPIDFUZZ = False
try:
    from rapidfuzz import fuzz, process
    USE_RAPIDFUZZ = True
except Exception:
    USE_RAPIDFUZZ = False

# Conservative seed mappings - extend this by loading JSON files or using register_mapping
BASE_MAPS = {
    "yoruba": {
        "bawo": "Báwo",
        "bawo ni": "Báwo ní",
        "ewa": "Ẹwà",
        "e kaaro": "Ẹ káàrọ̀",
        "e kaabo": "Ẹ káàbọ̀",
        "e se": "Ẹ ṣé",
        "mo n ko eko": "Mo ń kọ́ ẹ̀kọ́"
    },
    "swahili": {
        "hello": "Hujambo",
        "thank you": "Asante"
    },
    "igbo": {
        "ndewo": "Ndewo",
        "daalu": "Daalụ"
    }
}

AUDIT_LOG = []

def normalize_unicode(text: str) -> str:
    return unicodedata.normalize('NFC', text) if text else text

def _ratio(a: str, b: str) -> float:
    if USE_RAPIDFUZZ:
        return fuzz.ratio(a, b) / 100.0
    else:
        return SequenceMatcher(None, a, b).ratio()

def apply_exact(text: str, lang: Optional[str]) -> Optional[str]:
    if not text or not lang:
        return None
    key = text.strip().lower()
    mapping = BASE_MAPS.get(lang.lower(), {})
    return mapping.get(key)

def fuzzy_lookup(text: str, lang: Optional[str], threshold: float = 0.75):
    if not text or not lang:
        return None, 0.0, "missing"
    key = text.strip().lower()
    mapping = BASE_MAPS.get(lang.lower(), {})
    if not mapping:
        return None, 0.0, "no_map"
    # rapidfuzz path
    if USE_RAPIDFUZZ:
        choices = list(mapping.keys())
        match = process.extractOne(key, choices, scorer=fuzz.ratio)
        if match:
            candidate, score, _ = match
            sc = score / 100.0
            if sc >= threshold:
                return mapping[candidate], sc, "rapidfuzz"
    # fallback: SequenceMatcher
    best=None; best_score=0.0
    for k in mapping.keys():
        s = SequenceMatcher(None, key, k).ratio()
        if s > best_score:
            best_score = s; best = k
    if best and best_score >= threshold:
        return mapping[best], best_score, "difflib"
    # token overlap heuristic
    tokens = set(key.split())
    for k in mapping.keys():
        ktokens = set(k.split())
        overlap = len(tokens & ktokens) / max(1, len(ktokens))
        if overlap >= 0.6:
            return mapping[k], overlap, "token_overlap"
    return None, best_score, "no_match"

def enforce_diacritics(text: str, lang: Optional[str]=None, enable_fuzzy: bool=True, threshold: float=0.75) -> Tuple[str, bool, Dict]:
    meta = {"original": text, "lang": lang, "steps": []}
    start = time.time()
    if not text:
        meta["time_ms"] = int((time.time()-start)*1000)
        return text, False, meta
    text = normalize_unicode(text)
    meta["normalized"] = text
    # exact mapping
    exact = apply_exact(text, lang)
    if exact:
        meta["steps"].append({"step":"exact","out":exact})
        AUDIT_LOG.append({"event":"diacritics_applied","method":"exact","lang":lang,"input":text,"output":exact,"ts":int(time.time()*1000)})
        meta["time_ms"] = int((time.time()-start)*1000)
        return exact, True, meta
    # fuzzy
    if enable_fuzzy and lang:
        mapped, score, method = fuzzy_lookup(text, lang, threshold=threshold)
        meta["steps"].append({"step":"fuzzy_attempt","method":method,"score":score})
        if mapped:
            meta["mapped"] = mapped
            meta["score"] = score
            AUDIT_LOG.append({"event":"diacritics_applied","method":method,"lang":lang,"input":text,"output":mapped,"score":score,"ts":int(time.time()*1000)})
            meta["time_ms"] = int((time.time()-start)*1000)
            return mapped, True, meta
    meta["steps"].append({"step":"no_change"})
    meta["time_ms"] = int((time.time()-start)*1000)
    return text, False, meta

def register_mapping(lang: str, mapping: Dict[str,str]):
    BASE_MAPS.setdefault(lang.lower(), {}).update(mapping)

def dump_audit(path: str):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "a", encoding="utf-8") as f:
        for e in AUDIT_LOG:
            f.write(json.dumps(e, ensure_ascii=False) + "\n")
