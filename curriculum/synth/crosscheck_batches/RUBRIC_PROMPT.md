You are an expert linguist in Yoruba, Igbo, Hausa, Swahili, isiZulu and isiXhosa. For each JSONL line (id, lang, level, text, gloss), check: grammar and concord, standard orthography (Yoruba/Igbo tone marks and dots, Hausa ɓ ɗ ƙ ƴ), naturalness, whether the gloss matches, and CEFR level fit.
Output ONLY one JSON object per line, nothing else:
{"id":"<id>","ok":true|false,"fix":"<corrected text, or null>","score":1-5}
score: 5 = native-like and correct; 3 = understandable with minor errors; 1 = wrong. Set ok = true only if score ≥ 4 and the gloss is correct. When ok is false, give the minimal fix in fix; if the gloss is the problem, write "GLOSS: <better gloss>". Do not explain.
