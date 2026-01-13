def enforce_diacritics(text, lang=None):
    maps = {'yoruba': {'bawo ni':'Báwo ni','ekaaro':'Ẹ káàrọ̀'}, 'swahili': {'asante':'Asante'}}
    key = (text or '').strip().lower()
    m = maps.get(lang, {})
    if key in m:
        return m[key], True, {'method':'exact'}
    return text, False, {}
