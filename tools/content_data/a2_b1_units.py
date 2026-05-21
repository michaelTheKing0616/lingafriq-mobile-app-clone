# -*- coding: utf-8 -*-
"""A2 and B1 unit blocks merged into LANG_PACKS at import time."""

from __future__ import annotations

# (unit_title, unit_subtitle, [(lesson_title, [vocab], objective, cultural_note), ...])

A2_UNITS: dict[str, list] = {
    "yoruba": [
        ("Past & stories", "What happened yesterday", [
            ("Past tense", ["Mo ti jẹun", "O ti dé", "A ti lọ"], "Describe completed actions.", "Ti + verb marks recent past in Yoruba."),
            ("Narration", ["Láàárín", "Ní ọjọ́ kan", "Mo rí"], "Tell a short story opener.", "Time phrases anchor oral storytelling."),
            ("Feelings", ["Mo dùn", "Mo bínú", "Mo fẹ́ràn"], "Express emotions clearly.", "Emotion verbs often use mo + verb."),
        ]),
        ("Work & study", "Office and school", [
            ("Workplace", ["Iṣẹ́", "Ọ̀fíìsì", "Mo ń ṣiṣẹ́"], "Introduce your role.", "Professional register is slower and clearer."),
            ("Requests", ["Jọ̀wọ́ fún mi", "Ṣé o lè ran mi lọ́wọ́?", "Mo fẹ́"], "Ask for help politely.", "Ran…lọ́wọ́ is the help pattern."),
            ("Plans", ["Mo máa lọ", "Ọ̀la", "Ni àkókò méjì"], "Discuss future plans.", "Máa + verb signals intention."),
        ]),
    ],
    "hausa": [
        ("Past experiences", "Yesterday on the road", [
            ("Completed", ["Na ci abinci", "Ya iso", "Mun tafi"], "Talk about what already happened.", "Na/ka/ya + verb for past."),
            ("Story frame", ["Da safe", "A wata rana", "Na ga"], "Open a short narrative.", ""),
            ("Feelings", ["Ina farin ciki", "Na ji haushi", "Ina son"], "Share emotions.", ""),
        ]),
        ("Work & travel", "Office and journey", [
            ("Work", ["Aiki", "Ofis", "Ina aiki"], "Describe your job.", ""),
            ("Help", ["Don Allah taimaka mini", "Zaka iya?", "Ina so"], "Request assistance.", ""),
            ("Future", ["Zan tafi", "Gobe", "Da karfe biyu"], "Plan ahead.", "Za + verb for future."),
        ]),
    ],
    "igbo": [
        ("Past & narrative", "What you did", [
            ("Past", ["Eriri m nri", "Ọ bịara", "Anyị gara"], "Use past forms.", ""),
            ("Story", ["Mgbe ahụ", "Ụbọchị ụka", "Ahụrụ m"], "Begin a story.", ""),
            ("Emotion", ["Obi ụtọ", "Iwe", "Ahụrụ m n'anya"], "Express feelings.", ""),
        ]),
        ("Work & plans", "Career talk", [
            ("Work", ["Ọrụ", "Ọfịs", "Ana m arụ ọrụ"], "Talk about work.", ""),
            ("Help", ["Biko nyere m aka", "Ị nwere ike?", "Achọrọ m"], "Ask politely.", ""),
            ("Future", ["Ga-aga", "Echi", "N'elekere abụọ"], "Future plans.", ""),
        ]),
    ],
    "swahili": [
        ("Past stories", "Jana", [
            ("Past", ["Nimekula", "Amefika", "Tulikwenda"], "Past perfect forms.", ""),
            ("Narrative", ["Jana", "Siku moja", "Niliona"], "Story opening.", ""),
            ("Feelings", ["Nimefurahi", "Nimekasirika", "Ninapenda"], "Emotions.", ""),
        ]),
        ("Work future", "Kazi na safari", [
            ("Work", ["Kazi", "Ofisi", "Ninafanya kazi"], "Work vocabulary.", ""),
            ("Help", ["Tafadhali nisaidie", "Unaweza?", "Nataka"], "Requests.", ""),
            ("Future", ["Nitaenda", "Kesho", "Saa mbili"], "Future tense.", ""),
        ]),
    ],
    "zulu": [
        ("Past & story", "Izolo", [
            ("Past", ["Ngidlile", "Ufikile", "Sihambe"], "Past events.", ""),
            ("Story", ["Izolo", "Ngolunye usuku", "Ngibone"], "Narrative frame.", ""),
            ("Emotion", ["Ngijabule", "Ngicasulwe", "Ngiyayithanda"], "Feelings.", ""),
        ]),
        ("Work plans", "Umsebenzi", [
            ("Work", ["Umsebenzi", "Ihhovisi", "Ngisebenza"], "Work talk.", ""),
            ("Help", ["Sicela ungisize", "Ungakwazi?", "Ngifuna"], "Help requests.", ""),
            ("Future", ["Ngizohamba", "Kusasa", "Ngehora lesibili"], "Future.", ""),
        ]),
    ],
    "xhosa": [
        ("Past narrative", "Izolo", [
            ("Past", ["Ndidlile", "Ufikile", "Sihambe"], "Past tense.", ""),
            ("Story", ["Izolo", "Ngolunye usuku", "Ndibone"], "Story start.", ""),
            ("Emotion", ["Ndiyavuya", "Ndicaphukile", "Ndiyayithanda"], "Emotions.", ""),
        ]),
        ("Work", "Umsebenzi", [
            ("Work", ["Umsebenzi", "Iofisi", "Ndisebenza"], "Work phrases.", ""),
            ("Help", ["Nceda undincede", "Ungakwazi?", "Ndifuna"], "Polite help.", ""),
            ("Future", ["Ndiza kuhamba", "Ngomso", "Ngeyure lesibini"], "Plans.", ""),
        ]),
    ],
    "wolof": [
        ("Past & story", "Démb", [
            ("Past", ["Ma lekk", "Mu ñëw", "Nu dem"], "Past actions.", ""),
            ("Story", ["Démb", "Benn bés", "Ma gis"], "Story frame.", ""),
            ("Emotion", ["Ma bég", "Ma xanaa", "Bëgg naa"], "Feelings.", ""),
        ]),
        ("Work", "Liggéey", [
            ("Work", ["Liggéey", "Bureau", "Ma liggéey"], "Work vocab.", ""),
            ("Help", ["Baam la neex", "Mën nga?", "Bëgg naa"], "Requests.", ""),
            ("Future", ["Dinaa dem", "Suba", "Ñaari waxtu"], "Future.", ""),
        ]),
    ],
    "pidgin": [
        ("Past gist", "Wetin happen", [
            ("Past", ["I don chop", "E don reach", "We don go"], "Completed actions.", ""),
            ("Story", ["Yesterday", "One day", "I see"], "Story opener.", ""),
            ("Feelings", ["I happy", "I vex", "I like am"], "Emotions.", ""),
        ]),
        ("Work street", "Office & hustle", [
            ("Work", ["Work", "Office", "I dey work"], "Work talk.", ""),
            ("Help", ["Abeg help me", "You fit?", "I want"], "Street requests.", ""),
            ("Future", ["I go go", "Tomorrow", "By two o'clock"], "Plans.", ""),
        ]),
    ],
}

B1_UNITS: dict[str, list] = {
    "yoruba": [
        ("Opinions & debate", "Say what you think", [
            ("Opinion", ["Mo rò pé", "Mo gbà", "Mo kọ̀"], "Agree and disagree.", "Ro pé introduces opinion."),
            ("Debate", ["Bẹ́ẹ̀ kọ́?", "Kò yẹ", "Mo faramọ́"], "Debate politely.", ""),
            ("Media", ["Ìròyìn", "Redio", "Mo ti gbọ́"], "Discuss news.", ""),
        ]),
        ("Health & community", "Care and belonging", [
            ("Health", ["Aarun", "Oògùn", "Mo kọ̀rọ̀"], "Health vocabulary.", ""),
            ("Community", ["Àgbè", "Ilé-ìwé", "Àṣà"], "Community life.", ""),
            ("Advice", ["Mo máa dáàbàá", "O gbọ́dọ̀", "Ẹ jọ̀wọ́"], "Give gentle advice.", ""),
        ]),
    ],
    "hausa": [
        ("Opinions", "Ra'ayi", [
            ("Think", ["Ina tsammani", "Na yarda", "Ban yarda ba"], "Opinions.", ""),
            ("Debate", ["Haka ne?", "Ba daidai ba", "Na fahimta"], "Debate.", ""),
            ("News", ["Labari", "Rediyo", "Na ji"], "Media.", ""),
        ]),
        ("Community", "Al'umma", [
            ("Health", ["Cutar", "Magani", "Na jinya"], "Health.", ""),
            ("Society", ["Al'umma", "Makaranta", "Al'ada"], "Community.", ""),
            ("Advice", ["Zan yi hankuri", "Dole ne", "Don Allah"], "Advice.", ""),
        ]),
    ],
    "igbo": [
        ("Opinions", "Echiche", [
            ("Think", ["Eche m na", "Ekwenyere m", "Ekwetaghị m"], "Opinions.", ""),
            ("Debate", ["Ọ di otú?", "Ọ zighị ezi", "Ghọtara m"], "Debate.", ""),
            ("News", ["Akụkọ", "Redio", "Anụrụ m"], "News.", ""),
        ]),
        ("Community", "Obodo", [
            ("Health", ["Ọrịa", "Ọgwụ", "Ahụ ọkụ"], "Health.", ""),
            ("Society", ["Obodo", "Ụlọ akwụkwọ", "Omenala"], "Society.", ""),
            ("Advice", ["Ga-eme ka o di", "Ọ dị mkpa", "Biko"], "Advice.", ""),
        ]),
    ],
    "swahili": [
        ("Opinions", "Maoni", [
            ("Think", ["Nadhani", "Nakubali", "Sikubali"], "Opinions.", ""),
            ("Debate", ["Kweli?", "Si sawa", "Nimeelewa"], "Debate.", ""),
            ("News", ["Habari", "Redio", "Nimesikia"], "News.", ""),
        ]),
        ("Community", "Jamii", [
            ("Health", ["Ugonjwa", "Dawa", "Nina homa"], "Health.", ""),
            ("Society", ["Jamii", "Shule", "Utamaduni"], "Society.", ""),
            ("Advice", ["Nitakuwa mwangalifu", "Ni lazima", "Tafadhali"], "Advice.", ""),
        ]),
    ],
    "zulu": [
        ("Opinions", "Imibono", [
            ("Think", ["Ngicabanga", "Ngiyavuma", "Angivumi"], "Opinions.", ""),
            ("Debate", ["Kunjalo?", "Akulungile", "Ngiyakuqonda"], "Debate.", ""),
            ("News", ["Izindaba", "Umsakazo", "Ngizwile"], "News.", ""),
        ]),
        ("Community", "Umphakathi", [
            ("Health", ["Isifo", "Umuthi", "Ngiyagula"], "Health.", ""),
            ("Society", ["Umphakathi", "Isikole", "Isiko"], "Society.", ""),
            ("Advice", ["Ngizobaqaphele", "Kuyadingeka", "Sicela"], "Advice.", ""),
        ]),
    ],
    "xhosa": [
        ("Opinions", "Iimbono", [
            ("Think", ["Ndicinga", "Ndiyavuma", "Andivumi"], "Opinions.", ""),
            ("Debate", ["Kunjalo?", "Akulunganga", "Ndiyaqonda"], "Debate.", ""),
            ("News", ["Iindaba", "Umsakazo", "Ndive"], "News.", ""),
        ]),
        ("Community", "Uluntu", [
            ("Health", ["Isifo", "Iyeza", "Ndisonakala"], "Health.", ""),
            ("Society", ["Uluntu", "Isikolo", "Inkcubeko"], "Society.", ""),
            ("Advice", ["Ndiza kuqaphela", "Kuyimfuneko", "Nceda"], "Advice.", ""),
        ]),
    ],
    "wolof": [
        ("Opinions", "Xalaat", [
            ("Think", ["Ma xalaat ne", "Ma nangu", "Ma bëggul"], "Opinions.", ""),
            ("Debate", ["Ndax loolu?", "Du dëgg", "Xam naa"], "Debate.", ""),
            ("News", ["Xibaar", "Redio", "Ma dégg"], "News.", ""),
        ]),
        ("Community", "Koom-koom", [
            ("Health", ["Feebar", "Garab", "Ma xanu"], "Health.", ""),
            ("Society", ["Koom-koom", "Dara", "Aada"], "Society.", ""),
            ("Advice", ["Dinaa xamal", "War na", "Baam la neex"], "Advice.", ""),
        ]),
    ],
    "pidgin": [
        ("Opinions", "Wetin you think", [
            ("Think", ["I think say", "I agree", "I no agree"], "Opinions.", ""),
            ("Debate", ["Na so?", "No be so", "I understand"], "Debate.", ""),
            ("News", ["News", "Radio", "I don hear"], "News.", ""),
        ]),
        ("Community", "Area", [
            ("Health", ["Sick", "Medicine", "I get fever"], "Health.", ""),
            ("Society", ["Community", "School", "Culture"], "Society.", ""),
            ("Advice", ["I go careful", "E dey important", "Abeg"], "Advice.", ""),
        ]),
    ],
}
