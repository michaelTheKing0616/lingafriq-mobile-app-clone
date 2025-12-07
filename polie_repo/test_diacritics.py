import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from src_diacritics_correction import enforce_diacritics

def test_yoruba_bawo():
    out, changed = enforce_diacritics("bawo", lang="yoruba")
    assert "Báwo" in out

def test_yoruba_sentence():
    out, changed = enforce_diacritics("mo n ko eko", lang="yoruba")
    assert "Mo ń kọ́ ẹ̀kọ́" in out

def test_vietnamese():
    out, changed = enforce_diacritics("xin chao", lang="vietnamese")
    assert "Xin chào" in out