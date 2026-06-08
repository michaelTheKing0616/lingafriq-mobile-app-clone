"""Per-language and per-level cultural and linguistic briefs.

These are short paragraphs (3-6 sentences) injected into every drafting
prompt so the LLM has stable, opinionated guidance about orthography,
tonality, register, and cultural sensitivities. They are not exhaustive
references — the human native reviewer remains the final arbiter — but
they keep first-pass quality high and consistent across runs.
"""

from __future__ import annotations

LANGUAGE_BRIEFS: dict[str, str] = {
    "yoruba": (
        "Yoruba is a tonal language (high, mid, low). Always include tone "
        "marks and sub-dots in the bundle (e.g. ẹ́, ọ̀, ṣ). Standard Yoruba is the "
        "target dialect, but cultural notes may reference Ijebu, Egba, Oyo. "
        "Respect titles (Ẹ kú, Ẹ jọ̀wọ́) carry social weight; never drop them in "
        "elder/formal contexts. Avoid pidgin loans unless the lesson is "
        "explicitly diaspora-oriented."
    ),
    "hausa": (
        "Hausa uses the Boko Latin script with hooked letters (ɓ, ɗ, ƙ) and "
        "tonal marking that is not written but should be cued via grammar "
        "notes. Standard Hausa is the target; Kano dialect is mainstream. "
        "Always include the Sannu greeting family. Religious greetings "
        "(As-salamu alaykum) are common — note them in cultural context."
    ),
    "igbo": (
        "Igbo uses Latin script with diacritics (ị, ọ, ụ, ṅ) and dot-below for "
        "open vowels. Tone is significant (e.g. àkwà / akwa). Standard Igbo "
        "(Igbo izugbe) is the target but cultural notes should respect Anambra "
        "and Imo variation. Respect titles (nna, nne, dee, nwanne) carry "
        "kinship meaning."
    ),
    "swahili": (
        "Swahili uses Latin script with no diacritics. The target dialect is "
        "Kiswahili sanifu (Standard Swahili) used in Tanzania, Kenya, and the "
        "African Union. Bantu noun classes drive agreement — surface them in "
        "grammar notes. Cultural notes can include Bantu and Arab heritage."
    ),
    "zulu": (
        "Zulu uses Latin script. Clicks (c, q, x) are core phonemes — flag "
        "them in pronunciation notes. Tone is phonemic but not written. "
        "Hlonipha (respect speech) modifies vocabulary in formal contexts."
    ),
    "xhosa": (
        "Xhosa uses Latin script with click consonants (c, q, x) and "
        "tone-driven distinctions. Hlonipha respect speech alters word "
        "choice for elders. Standard isiXhosa is the target."
    ),
    "wolof": (
        "Wolof uses Latin script with diacritics (ñ, ŋ, é, ó). Standard "
        "Senegalese Wolof is the target. Greetings like Nanga def? open every "
        "exchange. Sufi/Islamic vocabulary is common — surface culturally."
    ),
    "pidgin": (
        "Nigerian Pidgin English (Naija) uses Latin script. It is a creole "
        "lingua franca across Nigeria with strong informal register. Greetings "
        "(How you dey, Abeg) and discourse markers (sef, wahala, dey kampe) "
        "are mandatory. Do not over-formalise it."
    ),
    "amharic": (
        "Amharic uses Ge'ez (Fidel) script. Always include the Fidel form. "
        "Transliterations should follow ISO 9 / common Latin-Amharic schemes. "
        "Respect titles (Ato, Wo/Weizero, Wo/Weizerit) modulate formality."
    ),
    "twi": (
        "Twi (Asante/Akuapem) uses Latin script with extended letters (ɛ, ɔ). "
        "Tone is phonemic but not always written. Cultural notes can include "
        "Ashanti customs. Akwaaba is the canonical welcome."
    ),
    "somali": (
        "Somali uses Latin script (Wadaad-influenced orthography). Long vowels "
        "are doubled (aa, ee). Standard Northern Somali is the target. "
        "Greetings like Subax wanaagsan and the formal Salaamu calaykum are "
        "common in the diaspora."
    ),
    "lingala": (
        "Lingala uses Latin script with diacritics (é, ó). Two-tone system. "
        "Standard Kinshasa Lingala is the target. French loanwords (s'il vous "
        "plaît, bureau) are common in urban registers — keep them where "
        "natural."
    ),
    "shona": (
        "Shona (Standard Shona, chiShona) uses Latin script with extended "
        "consonants (zv, sv). Tone is phonemic but not written. Greetings are "
        "elaborate (Mangwanani / Masikati / Manheru) — match the time of day."
    ),
    "arabic": (
        "Use Modern Standard Arabic (MSA / fuṣḥā) for written text. The bundle "
        "must include the Arabic script form and a Latin transliteration. "
        "Respect formal vs casual register: ya akhi, ya ukhti for friends; "
        "ustadh/ustadha for teachers. Avoid dialect-specific slang unless "
        "explicitly marked."
    ),
}


LEVEL_BRIEFS: dict[str, str] = {
    "A1": (
        "A1 (Discovery): learner just started. Lessons must use 3-5 vocab "
        "items, single-clause utterances, present tense only. Cultural notes "
        "should focus on greetings, courtesy, and basic survival situations."
    ),
    "A2": (
        "A2 (Foundations): learner can survive routine tasks. Introduce "
        "simple past/future markers, asking for things, expressing "
        "preferences. Vocab should be 5-7 items per lesson."
    ),
    "B1": (
        "B1 (Independence): learner handles travel and familiar situations. "
        "Introduce subordinate clauses, opinions, narration of past events. "
        "Cultural notes should cover everyday social codes."
    ),
    "B2": (
        "B2 (Confidence): learner discusses abstract topics. Introduce "
        "complex tenses (conditional, subjunctive equivalents), nuance "
        "markers, and register shifts. Vocab 7-9 items."
    ),
    "C1": (
        "C1 (Advanced fluency): learner argues fluently. Introduce idioms, "
        "rhetorical structures, professional registers (meetings, media). "
        "Cultural notes should cover values and worldview."
    ),
    "C2": (
        "C2 (Mastery): learner is near-native. Introduce literary register, "
        "wordplay, proverbs, advanced negotiation. Cultural notes should "
        "cover heritage, identity, and cross-regional variation."
    ),
}
