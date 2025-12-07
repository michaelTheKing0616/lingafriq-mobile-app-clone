# src_diacritics_correction.py (enhanced)
import unicodedata, time, json
from typing import Tuple, Dict, Optional
from difflib import SequenceMatcher, get_close_matches
import os

# Load base mappings (will be extended dynamically)
BASE_MAPS = {
    "yoruba": {
        "bawo": "Báwo",
        "bawo ni": "Báwo ní",
        "ewa": "Ẹwà",
        "e kaaro": "Ẹ káàrọ̀",
        "e kaale": "Ẹ káalẹ́",
        "e kaabo": "Ẹ káàbọ̀",
        "e n le": "Ẹ n lẹ",
        "e n lẹ": "Ẹ n lẹ",
        "mo n ko eko": "Mo ń kọ́ ẹ̀kọ́",
        "mo n ko": "Mo ń kọ́",
        "e se": "Ẹ ṣé",
        "e seun": "Ẹ ṣéun",
        "o se": "Ó ṣé",
        "bawo ni o": "Báwo ní o",
        "bawo ni o?": "Báwo ní o?"
    },
    "vietnamese": {
        "xin chao": "Xin chào",
        "cam on": "Cảm ơn",
        "toi ten la": "Tôi tên là",
        "anh yeu em": "Anh yêu em",
        "em yeu anh": "Em yêu anh"
    }
}

# Attempt to load expanded_lang_maps.json if present in repo data
REPO_DATA_PATH = "/mnt/data/polie_repo/data/expanded_lang_maps.json"
if os.path.exists(REPO_DATA_PATH):
    try:
        with open(REPO_DATA_PATH, "r", encoding="utf-8") as f:
            EXPANDED = json.load(f)
            # merge into BASE_MAPS conservatively
            for k,v in EXPANDED.items():
                if k in BASE_MAPS:
                    BASE_MAPS[k].update(v)
                else:
                    BASE_MAPS[k] = v
    except Exception as e:
        # fallback: ignore load errors
        EXPANDED = {}
else:
    EXPANDED = {}

# Telemetry / audit log collector (append to file or in-memory)
AUDIT_LOG = []

def normalize_unicode(text: str) -> str:
    return unicodedata.normalize("NFC", text) if text else text

def ratio(a: str, b: str) -> float:
    return SequenceMatcher(None, a, b).ratio()

def apply_lookup_map(text: str, lang: str) -> Tuple[Optional[str], bool, str]:
    """
    Phrase-level exact mapping.
    Returns (corrected_text, changed_flag, reason)
    """
    if not text or not lang:
        return None, False, "missing_input"
    key = text.strip().lower()
    mapping = BASE_MAPS.get(lang.lower(), {})
    corrected = mapping.get(key)
    if corrected:
        return corrected, True, "exact_match"
    return None, False, "no_exact"

def fuzzy_token_match(text: str, lang: str, threshold: float = 0.75) -> Tuple[Optional[str], bool, str, float]:
    """
    Token-level or phrase-level fuzzy matching.
    We compute best match among mapping keys using SequenceMatcher ratio.
    Returns (corrected_text, changed_flag, reason, best_score)
    """
    if not text or not lang:
        return None, False, "missing_input", 0.0
    key = text.strip().lower()
    mapping = BASE_MAPS.get(lang.lower(), {})
    if not mapping:
        return None, False, "no_mapping", 0.0
    best = None
    best_score = 0.0
    for k in mapping.keys():
        s = ratio(key, k)
        if s > best_score:
            best_score = s
            best = k
    if best and best_score >= threshold:
        return mapping[best], True, "fuzzy_match", best_score
    # attempt token-level: split and match subsets
    tokens = key.split()
    for k in mapping.keys():
        k_tokens = k.split()
        # check if most tokens overlap (simple)
        overlap = len(set(tokens) & set(k_tokens)) / max(1, len(set(k_tokens)))
        if overlap >= 0.6:
            # consider as fuzzy token match
            return mapping[k], True, "token_overlap", overlap
    return None, False, "no_fuzzy", best_score

def enforce_diacritics(text: str, lang: str = None, enable_fuzzy: bool = True) -> Tuple[str, bool, dict]:
    """
    Enforce diacritics with multiple strategies:
      1) NFC normalization
      2) Exact phrase lookup
      3) Fuzzy/token-level matching (if enabled)
    Returns (output_text, changed_flag, metadata)
    """
    start = time.time()
    meta = {"original": text, "lang": lang, "steps": []}
    if not text:
        meta["steps"].append(("empty_input", None))
        return text, False, meta
    original = text
    text = normalize_unicode(text)
    meta["normalized"] = text
    # exact lookup
    corrected, changed, reason = apply_lookup_map(text, lang)
    meta["steps"].append((reason, None))
    if changed and corrected:
        meta["corrected"] = corrected
        meta["time_ms"] = int((time.time() - start)*1000)
        # audit log entry
        AUDIT_LOG.append({"event":"diacritics_applied","lang":lang,"method":reason,"input":original,"output":corrected,"time_ms":meta["time_ms"]})
        return corrected, True, meta
    # fuzzy/token-level
    if enable_fuzzy:
        corr2, changed2, reason2, score = fuzzy_token_match(text, lang)
        meta["steps"].append((reason2, score))
        if changed2 and corr2:
            meta["corrected"] = corr2
            meta["score"] = score
            meta["time_ms"] = int((time.time() - start)*1000)
            AUDIT_LOG.append({"event":"diacritics_applied","lang":lang,"method":reason2,"input":original,"output":corr2,"score":score,"time_ms":meta["time_ms"]})
            return corr2, True, meta
    # no change
    meta["time_ms"] = int((time.time() - start)*1000)
    meta["steps"].append(("no_change", None))
    return text, False, meta

def register_mapping(lang: str, mapping: Dict[str, str]):
    BASE_MAPS[lang.lower()] = {**BASE_MAPS.get(lang.lower(), {}), **mapping}

def dump_audit(path: str):
    try:
        with open(path, "a", encoding="utf-8") as f:
            for e in AUDIT_LOG:
                f.write(json.dumps(e, ensure_ascii=False) + "\\n")
    except Exception:
        pass

if __name__ == "__main__":
    # quick demonstration
    samples = [
        ("bawo","yoruba"),
        ("bawo ni","yoruba"),
        ("bawoo","yoruba"),  # intentional typo to test fuzzy
        ("xin chao","vietnamese"),
        ("xin chăo","vietnamese")
    ]
    for s, l in samples:
        out, changed, meta = enforce_diacritics(s, lang=l)
        print(f"{l} | IN: {s} -> OUT: {out} (changed={changed}) meta={meta}")