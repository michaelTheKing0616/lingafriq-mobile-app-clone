# -*- coding: utf-8 -*-
"""Polie-driven game drills: Grammar Jam, Liar Liar, and extended scenarios."""

from __future__ import annotations

from typing import Any

# GrammarJam: (phrase_with___, correct, [options], tip)
_GRAMMAR: dict[str, list[tuple]] = {
    "yoruba": [
        ("Mo ___ lo si ile-iwe.", "ń", ["ń", "ti", "ma", "ko"], "Present continuous uses ń before the verb."),
        ("O ___ jeun?", "ti", ["ti", "n", "yoo", "ma"], "Ti marks recent past — Have you eaten?"),
        ("A ___ lo ni ola.", "yoo", ["yoo", "ti", "n", "ko"], "Yoo indicates future tense."),
        ("Emi ___ omo ile Yoruba.", "ni", ["ni", "si", "ti", "ko"], "Ni functions as am/is in identity."),
        ("Won ___ wa nibi.", "ko", ["ko", "n", "ti", "yoo"], "Ko is the negation marker."),
        ("Mo fe ___ omi.", "mu", ["mu", "je", "lo", "wa"], "Mu means drink with fe (want)."),
        ("E ___ mi lowo.", "ran", ["ran", "fun", "ba", "fi"], "Ran…lowo means help me."),
        ("Ile ___ tobi.", "naa", ["naa", "yi", "yen", "kan"], "Naa is definite — the house is big."),
        ("Mo ___ kọ Yorùbá.", "ń", ["ń", "ti", "ko", "ma"], "Progressive learning: Mo ń kọ…"),
        ("Ṣé o ___ sọ̀rọ̀?", "lè", ["lè", "ti", "ń", "ko"], "Modal lè — can you speak?"),
    ],
    "hausa": [
        ("Ina ___ Hausa.", "koyo", ["koyo", "ci", "tafi", "kwana"], "Koyo = learning."),
        ("Ya ___ mota.", "tafi", ["tafi", "ci", "kwana", "zo"], "Ya + verb past."),
        ("Za mu ___ gobe.", "tafi", ["tafi", "ci", "kwana", "zo"], "Za future marker."),
        ("Ba ta ___ ba.", "zo", ["zo", "tafi", "ci", "kwana"], "Ba…ba negation."),
        ("Ina so in ___ ruwa.", "sha", ["sha", "ci", "tafi", "kwana"], "Sha = drink."),
        ("Sunana ___ Ahmad.", "ne", ["ne", "ce", "na", "ka"], "Ne copula for names."),
        ("Kudi ___ kadan.", "ya", ["ya", "ba", "za", "na"], "Ya shows change/state."),
        ("Ina ___ lafiya.", "jin", ["jin", "ci", "tafi", "kwana"], "Jin lafiya = feel well."),
    ],
    "igbo": [
        ("Ana m ___ Igbo.", "a", ["a", "e", "i", "o"], "Ana m a + verb = progressive."),
        ("Ọ ___ abịa.", "bịara", ["bịara", "bịa", "ga", "na"], "Bịara past."),
        ("Anyị ga-___ echi.", "aga", ["aga", "ga", "ra", "la"], "Ga- future prefix."),
        ("Aha m ___ Chioma.", "bụ", ["bụ", "dị", "ka", "na"], "Bụ copula."),
        ("Achọrọ m ___ mmiri.", "ọ", ["ọ", "e", "a", "i"], "Ọ verb slot for drink."),
        ("Ọ bụ ___ ezigbo.", "otu", ["otu", "ọma", "nke", "ya"], "Otú = how/that."),
        ("Eriri m ___ taa.", "nri", ["nri", "mmiri", "ego", "ụlọ"], "Nri = food."),
        ("Kedu ___ ị bụ?", "aha", ["aha", "ebe", "mgbe", "ọnụ"], "Aha = name."),
    ],
    "swahili": [
        ("Nina ___ Kiswahili.", "soma", ["soma", "kula", "lala", "pika"], "Nina + verb present."),
        ("Yeye ___ mwalimu.", "ni", ["ni", "si", "ana", "ali"], "Ni copula."),
        ("Tuta ___ kesho.", "enda", ["enda", "kuja", "soma", "lala"], "Tuta future."),
        ("Hawa ___ wanafunzi.", "si", ["si", "ni", "wana", "wali"], "Si negative copula."),
        ("Nili ___ jana.", "fika", ["fika", "enda", "kula", "soma"], "Nili past."),
        ("Ana ___ sasa.", "pika", ["pika", "soma", "lala", "enda"], "Ana continuous."),
        ("Sina ___ ya kutosha.", "pesa", ["pesa", "maji", "nyumba", "gari"], "Sina = don't have."),
        ("Nyumba ___ nzuri.", "hii", ["hii", "ile", "hiyo", "hizo"], "Demonstrative hii."),
    ],
    "zulu": [
        ("Ngiyafunda ___ .", "isiZulu", ["isiZulu", "isiNgisi", "ukudla", "indlu"], "Object prefix slot."),
        ("Ungu ___ wami.", "thisha", ["thisha", "mfundi", "umama", "ubaba"], "Ungu copula."),
        ("Sizohamba ___ .", "kusasa", ["kusasa", "namhlanje", "izolo", "manje"], "Future time."),
        ("Angisomi ___ .", "lapha", ["lapha", "khona", "phansi", "phezulu"], "Negative present."),
        ("Ngifuna ___ .", "amanzi", ["amanzi", "ukudla", "imali", "indlu"], "Want + noun."),
        ("Le ndlu ___ .", "ikhulu", ["ikhulu", "incane", "ihle", "imbi"], "Adjective agreement."),
    ],
    "xhosa": [
        ("Ndiyafunda ___ .", "isiXhosa", ["isiXhosa", "isiNgisi", "ukutya", "indlu"], "Learning phrase."),
        ("Ungu ___ wam.", "thisha", ["thisha", "mfundi", "umama", "utata"], "Copula."),
        ("Siza kuhamba ___ .", "ngomso", ["ngomso", "namhlanje", "izolo", "ngoku"], "Future."),
        ("Andimi ___ .", "apha", ["apha", "khona", "phantsi", "phezulu"], "Negative."),
        ("Ndifuna ___ .", "amanzi", ["amanzi", "ukutya", "imali", "indlu"], "Want."),
    ],
    "wolof": [
        ("Damay ___ Wolof.", "jàng", ["jàng", "lekk", "dem", "nelaw"], "Progressive jàng."),
        ("Mu ___ dem.", "dem", ["dem", "ñëw", "lekk", "jàng"], "Past dem."),
        ("Dinaa ___ suba.", "dem", ["dem", "ñëw", "lekk", "jàng"], "Future dinaa."),
        ("Du ___ fi.", "dem", ["dem", "ñëw", "lekk", "jàng"], "Negative du."),
        ("Bëgg naa ___ ndox.", "naan", ["naan", "lekk", "dem", "jàng"], "Naan drink."),
    ],
    "pidgin": [
        ("I ___ dey learn Pidgin.", "dey", ["dey", "don", "go", "fit"], "I dey = continuous."),
        ("E ___ reach.", "don", ["don", "dey", "go", "fit"], "Don complete."),
        ("We ___ go tomorrow.", "go", ["go", "dey", "don", "fit"], "Go future."),
        ("I no ___ wan.", "dey", ["dey", "don", "go", "fit"], "No dey negation."),
        ("I wan ___ water.", "drink", ["drink", "chop", "go", "sleep"], "Want + verb."),
    ],
    "afrikaans": [
        ("Ek ___ Afrikaans leer.", "leer", ["leer", "eet", "gaan", "slaap"], "Present tense."),
        ("Hy ___ gister gekom.", "het", ["het", "is", "sal", "kan"], "Past auxiliary."),
        ("Ons ___ môre gaan.", "sal", ["sal", "het", "is", "kan"], "Future sal."),
        ("Ek ___ nie saam nie.", "stem", ["stem", "het", "is", "kan"], "Stem saam."),
        ("Ek wil ___ drink.", "water", ["water", "kos", "geld", "huis"], "Want + noun."),
    ],
    "amharic": [
        ("እኔ ___ እማራርኛ እማር.", "እማር", ["እማር", "በላ", "ሄድ", "ተኛ"], "Learning."),
        ("እሁ ___ መጣ.", "አለ", ["አለ", "ነው", "ይሆን", "יכול"], "Past marker."),
        ("ነገ ___ እሄዳለሁ.", "እሄዳለሁ", ["እሄዳለሁ", "በላ", "ሄድ", "ተኛ"], "Future."),
    ],
    "twi": [
        ("Me ___ Twi.", "re", ["re", "di", "kɔ", "da"], "Progressive."),
        ("Ɔ___ aba.", "baa", ["baa", "bɛ", "kɔ", "di"], "Past."),
        ("Yɛbɛ___ ɔkyena.", "kɔ", ["kɔ", "ba", "di", "da"], "Future."),
    ],
    "somali": [
        ("Waxaan ___ Soomaali.", "baranayaa", ["baranayaa", "cunay", "tegay", "seexday"], "Progressive."),
        ("Wuu ___ yimid.", "yimid", ["yimid", "yahay", "tegi", "cuni"], "Past."),
        ("Waan ___ doonaa.", "tegi", ["tegi", "cuni", "seex", "tag"], "Future."),
    ],
    "lingala": [
        ("Nazali ___ Lingala.", "koyekola", ["koyekola", "kolia", "kokende", "kolala"], "Learning."),
        ("A___ koya.", "yaki", ["yaki", "zali", "kokende", "kolia"], "Past."),
    ],
    "shona": [
        ("Ndiri ___ ChiShona.", "kudzidza", ["kudzidza", "kudya", "kuenda", "kurara"], "Learning."),
        ("A___ asvika.", "kasvika", ["kasvika", "ari", "aenda", "adyi"], "Past."),
    ],
}

# Liar Liar: (sentence, has_error, explanation)
_LIAR: dict[str, list[tuple]] = {
    "yoruba": [
        ("Mo ti jeun.", False, "Correct: ti + jeun (I have eaten)."),
        ("Mo ti je.", True, "Missing final syllable — jeun is the verb to eat."),
        ("O n lo si oja.", True, "Should be O ń lọ sí ọjà — missing tones and sí."),
        ("Ẹ kú àárọ̀.", False, "Correct respectful morning greeting."),
        ("Mo fe omi mu.", True, "Natural order: Mo fẹ́ mu omi (I want to drink water)."),
        ("Won ko wa.", False, "Correct negative: They did not come."),
        ("Mo ni omo.", False, "Correct: I have a child (identity)."),
        ("Emi ni Yoruba.", True, "Use Mo jẹ́ ọmọ Yorùbá for I am Yoruba."),
    ],
    "hausa": [
        ("Na ci abinci.", False, "Correct past: I ate food."),
        ("Na ci abincin.", True, "Incomplete noun — abinci is standard."),
        ("Ina lafiya lau.", False, "Correct wellbeing reply."),
        ("Ina kwana?", True, "Question needs rising context — Ina kwana? is fine alone."),
        ("Sunana Musa ne.", False, "Correct name introduction."),
        ("Ya tafi mota.", True, "Should be Ya tafi da mota or Ya tafi."),
    ],
    "igbo": [
        ("Eriri m nri.", False, "Correct: I ate food."),
        ("Eri m nri.", True, "Use eriri m for completed eating."),
        ("Kedu ka ị mere?", False, "Correct: How are you?"),
        ("Aha m bụ Ada.", False, "Correct name phrase."),
        ("Ana m arụ ọrụ.", False, "Correct progressive work."),
        ("Ọ bịa.", True, "Incomplete — Ọ bịara (he/she came)."),
    ],
    "swahili": [
        ("Nimekula.", False, "Correct: I have eaten."),
        ("Nimekula chakula.", False, "Correct with object."),
        ("Yeye ni mwalimu.", False, "Correct copula."),
        ("Yeye mwalimu.", True, "Missing ni copula."),
        ("Tutaenda kesho.", False, "Correct future."),
        ("Tuta enda kesho.", True, "Tutaenda is written as one word."),
    ],
    "zulu": [
        ("Ngidlile.", False, "Correct: I have eaten."),
        ("Ngidlile ukudla.", False, "Correct with object."),
        ("Ungumfundisi.", False, "Correct: He is a teacher."),
        ("Umfundisi.", True, "Missing copula ungu-."),
        ("Ngizohamba kusasa.", False, "Correct future."),
    ],
    "xhosa": [
        ("Ndidlile.", False, "Correct past."),
        ("Ungumfundisi.", False, "Correct copula."),
        ("Umfundisi.", True, "Needs ungu- copula."),
        ("Ndiza kuhamba ngomso.", False, "Correct future."),
    ],
    "wolof": [
        ("Ma lekk.", False, "Correct: I ate."),
        ("Ma lek.", True, "Incomplete verb form."),
        ("Damay dem.", False, "Correct future intent."),
        ("Damay demek.", True, "Non-standard ending."),
    ],
    "pidgin": [
        ("I don chop.", False, "Correct completed action."),
        ("I chop don.", True, "Word order — I don chop."),
        ("How far?", False, "Correct greeting."),
        ("How you dey?", False, "Correct follow-up."),
        ("I dey fine.", False, "Correct reply."),
        ("I fine dey.", True, "Reversed — I dey fine."),
    ],
}

# Extra scenario games (title, prompt, expected, note)
_EXTRA_SCENARIOS: dict[str, dict[str, list[tuple]]] = {
    "GrammarJam": {
        "yoruba": [
            ("Fill the blank", "Mo ___ lo si ọjà. (market)", "ń", "Present continuous before verb."),
            ("Politeness", "Before price: greet with ___", "Ẹ kú ọ̀sán", "Greeting opens negotiation."),
        ],
    },
    "LiarLiar": {
        "yoruba": [
            ("Spot the error", "Mo ti je. — Is this complete Yoruba?", "No — use jeun", "Verb form check."),
        ],
    },
    "ConversationRelay": {
        "yoruba": [
            ("Market relay", "Ẹ kú àárọ̀ → respond → ask price", "Ẹ kú àárọ̀. Ó dára. Ẹ́élo ni?", "Three-turn market flow."),
            ("Check-in relay", "Báwo ni? → wellbeing → family", "Mo ń ṣe dáadáa. Ẹ̀bí dára.", "Conversation chain."),
        ],
        "hausa": [
            ("Greeting chain", "Sannu → lafiya → purpose", "Lafiya lau. Ina zuwa kasuwa.", "Relay pattern."),
        ],
        "swahili": [
            ("Coast relay", "Habari → response → plan", "Nzuri. Nitaenda sokoni.", "Natural pacing."),
        ],
        "pidgin": [
            ("Street relay", "How far? → reply → gist", "I dey fine. Wetin dey happen?", "Casual chain."),
        ],
    },
    "StoryBuilder": {
        "yoruba": [
            ("Market day", "Start: Ẹ kú ọ̀sán at ọjà…", "Continue with Mo fẹ́ and Ẹ ṣé", "Build a 3-sentence market story."),
            ("Family visit", "Start: Mo wá láti rí ẹ̀bí mi…", "Use Ilé and Ẹ káàbọ̀", "Arrival narrative."),
        ],
        "hausa": [
            ("Journey", "Start: Tafiya ta fara…", "Use Sannu and Gida", "Travel story arc."),
        ],
        "pidgin": [
            ("Lagos gist", "Start: Yesterday for market…", "Use Chop and How much?", "Urban story."),
        ],
    },
    "QuizChef": {
        "yoruba": [
            ("Greeting pot", "Which is afternoon greeting?", "Ẹ kú ọ̀sán", "Time-of-day accuracy."),
            ("Respect pot", "Which asks price politely?", "Ẹ́élo ni?", "After greeting."),
        ],
    },
    "ToneTrainer": {
        "yoruba": [
            ("Owó vs òwò", "Say owó (money) and òwò (honour)", "Tone pair", "Minimal tone pair practice."),
            ("ó vs ò", "Ó dára vs ò dára", "Meaning shift", "High vs low tone."),
        ],
    },
    "ProverbUnlocker": {},
    "CallAndResponse": {
        "yoruba": [
            ("Call: Ẹ kú ilé o!", "Respond: Ẹ kú àárọ̀, gbogbo wa.", "Group greeting response.", ""),
        ],
        "hausa": [
            ("Call: Sannu da zuwa!", "Respond: Lafiya lau, na gode.", "Welcome exchange.", ""),
        ],
    },
    "PhraseSniper": {
        "yoruba": [
            ("Catch the bargain", "Jọ̀ọ́!", "Polite price reduction.", "Quick phrase ID."),
        ],
    },
    "CulturalEtiquetteScenarios": {
        "yoruba": [
            ("Two-hand receive", "When elder gives gift, say ___", "Ẹ ṣé pupọ̀", "Receive with respect."),
        ],
    },
    "EldersBlessingsChallenge": {
        "yoruba": [
            ("After helping", "Ẹ ṣé, ìyá. Mo ń lọ.", "Elder may bless your journey.", ""),
        ],
    },
    "SpeedRound": {
        "yoruba": [
            ("Rapid greet", "Ẹ kú àárọ̀!", "Morning only.", "Speed ID."),
            ("Rapid thanks", "Ẹ ṣé!", "Courtesy.", ""),
        ],
    },
}


def build_grammar_drills(languages: list[str]) -> list[dict]:
    out: list[dict] = []
    gid = 1
    for lang in languages:
        for phrase, correct, options, tip in _GRAMMAR.get(lang, _GRAMMAR.get("yoruba", [])):
            out.append({
                "id": gid,
                "language": lang,
                "game": "GrammarJam",
                "phrase": phrase,
                "correct": correct,
                "options": options,
                "tip": tip,
                "cefr": "A1",
            })
            gid += 1
        for level in ("A2", "B1", "B2", "C1"):
            for phrase, correct, options, tip in _GRAMMAR.get(lang, [])[:4]:
                out.append({
                    "id": gid,
                    "language": lang,
                    "game": "GrammarJam",
                    "phrase": phrase,
                    "correct": correct,
                    "options": options,
                    "tip": tip,
                    "cefr": level,
                })
                gid += 1
    return out


def build_liar_liar_rounds(languages: list[str]) -> list[dict]:
    out: list[dict] = []
    lid = 1
    for lang in languages:
        for sentence, has_error, explanation in _LIAR.get(lang, _LIAR.get("yoruba", [])):
            out.append({
                "id": lid,
                "language": lang,
                "sentence": sentence,
                "has_error": has_error,
                "explanation": explanation,
                "cefr": "A1",
            })
            lid += 1
    return out


def extend_scenarios(
    scenarios: list[dict],
    languages: list[str],
    sid_start: int,
) -> tuple[list[dict], int]:
    sid = sid_start
    for game, by_lang in _EXTRA_SCENARIOS.items():
        for lang in languages:
            items = by_lang.get(lang, [])
            for title, prompt, expected, note in items:
                scenarios.append({
                    "id": sid,
                    "game": game,
                    "language": lang,
                    "cefr": "A1",
                    "title": title,
                    "prompt": prompt,
                    "expected_response": expected,
                    "cultural_note": note,
                })
                sid += 1
    return scenarios, sid
