# diacritics_correction.py
# Production-ready diacritics correction helpers for language outputs.
# Supports Yoruba and Vietnamese out of the box. Easy to extend with new mapping files.
# Key features:
# - Canonicalize composed unicode forms
# - Map common ASCII fallback tokens to canonical forms
# - Provide an "enforce" function to run as a post-process in the Polie pipeline

import unicodedata
from typing import Tuple, Dict

# Basic mapping dictionaries.
# These are intentionally conservative: map frequent ASCII variants to canonical with diacritics.
YORUBA_MAP = {
    # greetings
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
}

VIETNAMESE_MAP = {
    # examples
    "xin chao": "Xin chào",
    "cam on": "Cảm ơn",
    "toi ten la": "Tôi tên là",
    "anh yeu em": "Anh yêu em",
    "em yeu anh": "Em yêu anh"
}

# Combine into a registry for extensibility
LANG_MAPS = {
    "yoruba": YORUBA_MAP,
    "vi": VIETNAMESE_MAP,
    "vietnamese": VIETNAMESE_MAP
}

def normalize_unicode(text: str) -> str:
    """Normalize to NFC (composed) form for consistent diacritic handling."""
    return unicodedata.normalize("NFC", text)

def apply_lookup_map(text: str, lang: str) -> Tuple[str, bool]:
    """
    Apply a mapping table for simple phrase-level corrections.
    Returns (corrected_text, changed_flag)
    """
    if not text or not lang:
        return text, False
    key = text.strip().lower()
    mapping = LANG_MAPS.get(lang.lower())
    if not mapping:
        return text, False
    corrected = mapping.get(key)
    if corrected:
        return corrected, True
    return text, False

def enforce_diacritics(text: str, lang: str = None) -> Tuple[str, bool]:
    """
    Enforce diacritics in text for a given language.
    Steps:
      1) Normalize Unicode to NFC.
      2) Try phrase-level mapping lookup.
      3) (Optional) More advanced heuristics can be added, such as token-level fuzzy matching.
    Returns (text_out, changed_flag)
    """
    if not text:
        return text, False
    original = text
    text = normalize_unicode(text)
    if lang:
        corrected, changed = apply_lookup_map(text, lang)
        if changed:
            return corrected, True
    # If no direct mapping, return normalized text (no change)
    return text, text != original

# Small helper to extend mapping at runtime
def register_mapping(lang: str, mapping: Dict[str, str]):
    LANG_MAPS[lang.lower()] = mapping

# Example: a simple fuzzy matcher could be added (not included here) for token-level.
if __name__ == "__main__":
    # Quick demo
    samples = [
        ("Translate 'Hello' to Yoruba", "bawo"),
        ("I am learning", "mo n ko eko"),
        ("hello vi", "xin chao")
    ]
    for desc, sample in samples:
        out, changed = enforce_diacritics(sample, lang="yoruba")
        print(f"IN: {sample} -> OUT: {out} (changed={changed})")