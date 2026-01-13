# usage_example.py
from src_diacritics_correction import enforce_diacritics

samples = [
    ("bawo", "yoruba"),
    ("mo n ko eko", "yoruba"),
    ("xin chao", "vietnamese"),
    ("cam on", "vietnamese")
]

for s, lang in samples:
    out, changed = enforce_diacritics(s, lang=lang)
    print(f"{lang} | IN: {s} -> OUT: {out} (changed={changed})")