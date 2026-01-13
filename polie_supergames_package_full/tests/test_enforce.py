from src.enforce_diacritics import enforce_diacritics
def test_exact():
    out, changed, meta = enforce_diacritics('bawo', 'yoruba')
    assert changed and 'Báwo' in out
