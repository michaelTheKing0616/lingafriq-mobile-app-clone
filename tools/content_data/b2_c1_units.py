# -*- coding: utf-8 -*-
"""B2 and C1 unit blocks merged into LANG_PACKS at import time."""

from __future__ import annotations

# (unit_title, unit_subtitle, [(lesson_title, [vocab], objective, cultural_note), ...])

_ALL_LANGS = [
    "yoruba", "hausa", "igbo", "swahili", "zulu", "xhosa", "wolof", "pidgin",
    "afrikaans", "amharic", "twi", "somali", "lingala", "shona",
]

B2_UNITS: dict[str, list] = {
    "yoruba": [
        ("Professional register", "Office & meetings", [
            ("Formal intro", ["Ẹ kú àárọ̀", "Orúkọ mi ni", "Mo wá láti ṣiṣẹ́"], "Introduce yourself professionally.", "Workplace Yoruba is slower and clearer."),
            ("Meeting talk", ["Mo rò pé", "Ṣé o gbà?", "A máa padà"], "Present a view in a meeting.", "Use ro pé to frame opinions respectfully."),
            ("Email tone", ["Ẹ jọ̀wọ́", "Mo máa fi ìwé ránṣẹ́", "Ó dára"], "Close formal exchanges.", ""),
        ]),
        ("Media & analysis", "News and discourse", [
            ("Headlines", ["Ìròyìn", "Redio", "Mo ti gbọ́"], "Discuss news sources.", "Media vocabulary builds B2 comprehension."),
            ("Debate", ["Bẹ́ẹ̀ kọ́?", "Mo faramọ́", "Mo kọ̀"], "Respond to opposing views.", ""),
            ("Report", ["Mo rí pé", "Àṣà", "Àgbà"], "Summarize an event.", "Oral reporting mirrors TV/radio style."),
        ]),
    ],
    "hausa": [
        ("Professional", "Aiki da taron aiki", [
            ("Intro", ["Sannu", "Sunana", "Ina aiki a nan"], "Professional introduction.", ""),
            ("Meeting", ["Ina tsammani", "Na yarda", "Za mu dawo"], "Meeting contributions.", ""),
            ("Formal close", ["Don Allah", "Zan aiko sako", "Na gode"], "Formal courtesy.", ""),
        ]),
        ("Media", "Labarai", [
            ("News", ["Labari", "Rediyo", "Na ji"], "Discuss news.", ""),
            ("Debate", ["Haka ne?", "Na fahimta", "Ban yarda ba"], "Debate phrases.", ""),
            ("Summary", ["Na ga cewa", "Al'ada", "Mutane"], "Summarize events.", ""),
        ]),
    ],
    "igbo": [
        ("Professional", "Ọrụ", [
            ("Intro", ["Ndewo", "Aha m bụ", "Ana m arụ ọrụ ebe a"], "Workplace intro.", ""),
            ("Meeting", ["Eche m na", "Ekwenyere m", "Anyị ga-alọghachi"], "Meeting speech.", ""),
            ("Formal", ["Biko", "A ga m zitere ozi", "Ọ dị mma"], "Formal closing.", ""),
        ]),
        ("Media", "Akụkọ", [
            ("News", ["Akụkọ", "Redio", "Anụrụ m"], "News vocabulary.", ""),
            ("Debate", ["Ọ di otú?", "Ghọtara m", "Ekwetaghị m"], "Debate.", ""),
            ("Report", ["Ahụrụ m na", "Omenala", "Ndị okenye"], "Reporting.", ""),
        ]),
    ],
    "swahili": [
        ("Professional", "Kazi", [
            ("Intro", ["Habari", "Jina langu ni", "Ninafanya kazi hapa"], "Professional intro.", ""),
            ("Meeting", ["Nadhani", "Nakubali", "Tutarudi"], "Meeting phrases.", ""),
            ("Formal", ["Tafadhali", "Nitatumia barua pepe", "Sawa"], "Formal close.", ""),
        ]),
        ("Media", "Habari", [
            ("News", ["Habari", "Redio", "Nimesikia"], "News talk.", ""),
            ("Debate", ["Kweli?", "Nimeelewa", "Sikubali"], "Debate.", ""),
            ("Report", ["Nimeona kwamba", "Utamaduni", "Wazee"], "Summarize.", ""),
        ]),
    ],
    "zulu": [
        ("Professional", "Umsebenzi", [
            ("Intro", ["Sawubona", "Igama lami ngu", "Ngisebenza lapha"], "Work intro.", ""),
            ("Meeting", ["Ngicabanga", "Ngiyavuma", "Sizobuya"], "Meeting.", ""),
            ("Formal", ["Sicela", "Ngizothumela i-imeyili", "Kulungile"], "Formal.", ""),
        ]),
        ("Media", "Izindaba", [
            ("News", ["Izindaba", "Umsakazo", "Ngizwile"], "News.", ""),
            ("Debate", ["Kunjalo?", "Ngiyakuqonda", "Angivumi"], "Debate.", ""),
            ("Report", ["Ngibone ukuthi", "Isiko", "Abadala"], "Report.", ""),
        ]),
    ],
    "xhosa": [
        ("Professional", "Umsebenzi", [
            ("Intro", ["Molo", "Igama lam ngu", "Ndisebenza apha"], "Work intro.", ""),
            ("Meeting", ["Ndicinga", "Ndiyavuma", "Siza kubuya"], "Meeting.", ""),
            ("Formal", ["Nceda", "Ndiza kuthumela i-imeyili", "Kulungile"], "Formal.", ""),
        ]),
        ("Media", "Iindaba", [
            ("News", ["Iindaba", "Umsakazo", "Ndive"], "News.", ""),
            ("Debate", ["Kunjalo?", "Ndiyaqonda", "Andivumi"], "Debate.", ""),
            ("Report", ["Ndibone ukuba", "Inkcubeko", "Oothandwayo"], "Report.", ""),
        ]),
    ],
    "wolof": [
        ("Professional", "Liggéey", [
            ("Intro", ["Nanga def", "Turam", "Ma liggéey fii"], "Work intro.", ""),
            ("Meeting", ["Ma xalaat ne", "Ma nangu", "Dinaa dellu"], "Meeting.", ""),
            ("Formal", ["Baam la neex", "Dinaa yónnee email", "Baax na"], "Formal.", ""),
        ]),
        ("Media", "Xibaar", [
            ("News", ["Xibaar", "Redio", "Ma dégg"], "News.", ""),
            ("Debate", ["Ndax loolu?", "Xam naa", "Ma bëggul"], "Debate.", ""),
            ("Report", ["Ma gis ne", "Aada", "Mag yi"], "Report.", ""),
        ]),
    ],
    "pidgin": [
        ("Professional", "Office", [
            ("Intro", ["How far?", "My name na", "I dey work here"], "Work intro.", ""),
            ("Meeting", ["I think say", "I agree", "We go come back"], "Meeting.", ""),
            ("Formal", ["Abeg", "I go send email", "E good"], "Formal.", ""),
        ]),
        ("Media", "News", [
            ("News", ["News", "Radio", "I don hear"], "News.", ""),
            ("Debate", ["Na so?", "I understand", "I no agree"], "Debate.", ""),
            ("Report", ["I see say", "Culture", "Elders"], "Report.", ""),
        ]),
    ],
    "afrikaans": [
        ("Professional", "Werk", [
            ("Intro", ["Goeie môre", "My naam is", "Ek werk hier"], "Work intro.", ""),
            ("Meeting", ["Ek dink", "Ek stem saam", "Ons kom terug"], "Meeting.", ""),
            ("Formal", ["Asseblief", "Ek sal 'n e-pos stuur", "Goed"], "Formal.", ""),
        ]),
        ("Media", "Nuus", [
            ("News", ["Nuus", "Radio", "Ek het gehoor"], "News.", ""),
            ("Debate", ["Regtig?", "Ek verstaan", "Ek stem nie saam nie"], "Debate.", ""),
            ("Report", ["Ek sien dat", "Kultuur", "Ouers"], "Report.", ""),
        ]),
    ],
    "amharic": [
        ("Professional", "ስራ", [
            ("Intro", ["ሰላም", "ስሜ", "እዚህ እሰራለሁ"], "Work introduction.", "Formal Amharic uses full titles."),
            ("Meeting", ["እመስላለሁ", "እስማማለሁ", "እንመለሳለን"], "Meeting phrases.", ""),
            ("Formal", ["እባክህ", "ኢሜይል እልካለሁ", "ጥሩ ነው"], "Formal close.", ""),
        ]),
        ("Media", "ዜና", [
            ("News", ["ዜና", "ራዲዮ", "ሰምቻለሁ"], "News vocabulary.", ""),
            ("Debate", ["እንደዚህ ነው?", "ገባኝ", "አልስማምምም"], "Debate.", ""),
            ("Report", ["እንደሆነ አይቻለሁ", "ባህል", "ሽማግሌዎች"], "Reporting.", ""),
        ]),
    ],
    "twi": [
        ("Professional", "Adwuma", [
            ("Intro", ["Maakye", "Me din de", "Mɛdwuma ha"], "Work intro.", ""),
            ("Meeting", ["Misusuw sɛ", "Mepene so", "Yɛbɛsan aba"], "Meeting.", ""),
            ("Formal", ["Mesrɛ wo", "Mɛsoma email", "Eye"], "Formal.", ""),
        ]),
        ("Media", "Nnwom", [
            ("News", ["Nnwom", "Redio", "Metee"], "News.", ""),
            ("Debate", ["Enti saa?", "Mete aseɛ", "Mempene so"], "Debate.", ""),
            ("Report", ["Mahunu sɛ", "Amammerɛ", "Mpanyimfo"], "Report.", ""),
        ]),
    ],
    "somali": [
        ("Professional", "Shaqo", [
            ("Intro", ["Salaan", "Magacaygu waa", "Halkan ayaan ka shaqeeyaa"], "Work intro.", ""),
            ("Meeting", ["Waxaan u maleynayaa", "Waan ogolahay", "Waan soo noqon doonaa"], "Meeting.", ""),
            ("Formal", ["Fadlan", "Email ayaan soo diri doonaa", "Waa hagaag"], "Formal.", ""),
        ]),
        ("Media", "War", [
            ("News", ["War", "Raadiyo", "Waan maqlay"], "News.", ""),
            ("Debate", ["Sidaas ma aha?", "Waan fahmay", "Ma ogola"], "Debate.", ""),
            ("Report", ["Waxaan arkay in", "Dhaqan", "Odayaasha"], "Report.", ""),
        ]),
    ],
    "lingala": [
        ("Professional", "Mosala", [
            ("Intro", ["Mbote", "Nkombo na ngai", "Nasalaka awa"], "Work intro.", ""),
            ("Meeting", ["Nakanisi ete", "Nandimi", "Tokozonga"], "Meeting.", ""),
            ("Formal", ["Svp", "Nabotamela email", "Malamu"], "Formal.", ""),
        ]),
        ("Media", "Sango", [
            ("News", ["Sango", "Radio", "Nayokaki"], "News.", ""),
            ("Debate", ["Vraiment?", "Nayebi", "Nandimi te"], "Debate.", ""),
            ("Report", ["Namoni ete", "Bizaleli", "Bakolo"], "Report.", ""),
        ]),
    ],
    "shona": [
        ("Professional", "Basa", [
            ("Intro", ["Mangwanani", "Zita rangu ndini", "Ndinoshanda pano"], "Work intro.", ""),
            ("Meeting", ["Ndinofunga", "Ndinobvuma", "Tichadzoka"], "Meeting.", ""),
            ("Formal", ["Ndapota", "Ndichatumira email", "Zvakanaka"], "Formal.", ""),
        ]),
        ("Media", "Nhau", [
            ("News", ["Nhau", "Redhiyo", "Ndakanzwa"], "News.", ""),
            ("Debate", ["Chokwadi?", "Ndinonzwisisa", "Handibvumi"], "Debate.", ""),
            ("Report", ["Ndakaona kuti", "Tsika", "Vakuru"], "Report.", ""),
        ]),
    ],
}

C1_UNITS: dict[str, list] = {
    "yoruba": [
        ("Idioms & nuance", "Deep register", [
            ("Proverbs in use", ["Ìwà lẹwà", "Ọwọ́ ọ̀rẹ́", "Bi a bá ń sọ̀rọ̀"], "Use proverbs in context.", "Proverbs carry moral argument."),
            ("Rhetoric", ["Bẹ́ẹ̀ ni", "Ṣùgbọ́n", "Nítorí náà"], "Link ideas in formal speech.", ""),
            ("Monologue", ["Mo fẹ́ sọ pé", "Gẹ́gẹ́ bí", "Ní ìparí"], "Deliver a structured argument.", ""),
        ]),
        ("Certification prep", "Advanced discourse", [
            ("Rebuttal", ["Mo kọ̀ ṣùgbọ́n", "Mo gbà láti", "Ó ṣe é ṣe"], "Polite rebuttal.", ""),
            ("Abstract", ["Àṣà", "Ìmọ̀", "Ìlera"], "Discuss abstract topics.", ""),
            ("Closing", ["Mo dúpẹ́", "A máa pàdé", "Ó dára gan-an"], "Close formal discourse.", ""),
        ]),
    ],
    "hausa": [
        ("Idioms", "Kalmomi masu zurfi", [
            ("Proverbs", ["Mutuwar mutum", "Gida gida", "Taimako"], "Proverbs in speech.", ""),
            ("Rhetoric", ["Haka ne", "Amma", "Saboda haka"], "Formal linking.", ""),
            ("Monologue", ["Ina so in ce", "Kamar yadda", "A ƙarshe"], "Structured speech.", ""),
        ]),
        ("Cert prep", "Ci gaba", [
            ("Rebuttal", ["Ban yarda ba amma", "Na yarda da", "Yadda aka saba"], "Rebuttal.", ""),
            ("Abstract", ["Al'ada", "Ilimi", "Lafiya"], "Abstract topics.", ""),
            ("Close", ["Na gode", "Za mu hadu", "Lafiya lau"], "Close.", ""),
        ]),
    ],
    "igbo": [
        ("Idioms", "Ilu", [
            ("Proverbs", ["Ihe omume", "Ụlọ", "Enyemaka"], "Proverbs.", ""),
            ("Rhetoric", ["Ọ di otú", "Ma", "N'ihi ya"], "Linking.", ""),
            ("Monologue", ["Achọrọ m ikwu", "Dị ka", "Na ngwụcha"], "Monologue.", ""),
        ]),
        ("Cert prep", "Elite", [
            ("Rebuttal", ["Ekwetaghị m ma", "Ekwenyere m na", "Omenala"], "Rebuttal.", ""),
            ("Abstract", ["Omenala", "Ọmụma", "Ahụ ike"], "Abstract.", ""),
            ("Close", ["Daalụ", "Anyị ga-ezukọ", "Ọ dị mma"], "Close.", ""),
        ]),
    ],
    "swahili": [
        ("Idioms", "Methali", [
            ("Proverbs", ["Haraka haraka", "Umoja", "Msaada"], "Proverbs.", ""),
            ("Rhetoric", ["Ni kweli", "Lakini", "Kwa hiyo"], "Formal links.", ""),
            ("Monologue", ["Nataka kusema", "Kama", "Mwishowe"], "Monologue.", ""),
        ]),
        ("Cert prep", "Juujuu", [
            ("Rebuttal", ["Sikubali lakini", "Nakubali kwamba", "Desturi"], "Rebuttal.", ""),
            ("Abstract", ["Utamaduni", "Elimu", "Afya"], "Abstract.", ""),
            ("Close", ["Asante", "Tutakutana", "Sawa kabisa"], "Close.", ""),
        ]),
    ],
    "zulu": [
        ("Idioms", "Izaga", [
            ("Proverbs", ["Isithunzi", "Ikhaya", "Usizo"], "Proverbs.", ""),
            ("Rhetoric", ["Kunjalo", "Kodwa", "Ngakho"], "Links.", ""),
            ("Monologue", ["Ngifuna ukusho", "Njengoba", "Ekugcineni"], "Monologue.", ""),
        ]),
        ("Cert prep", "Phakeme", [
            ("Rebuttal", ["Angivumi kodwa", "Ngiyavuma ukuthi", "Isiko"], "Rebuttal.", ""),
            ("Abstract", ["Isiko", "Imfundo", "Impilo"], "Abstract.", ""),
            ("Close", ["Ngiyabonga", "Sizohlangana", "Kulungile impela"], "Close.", ""),
        ]),
    ],
    "xhosa": [
        ("Idioms", "Izisho", [
            ("Proverbs", ["Isithunzi", "Ikhaya", "Uncedo"], "Proverbs.", ""),
            ("Rhetoric", ["Kunjalo", "Kodwa", "Ngoko ke"], "Links.", ""),
            ("Monologue", ["Ndifuna ukuthetha", "Njengoko", "Ekugqibeleni"], "Monologue.", ""),
        ]),
        ("Cert prep", "Phezulu", [
            ("Rebuttal", ["Andivumi kodwa", "Ndiyavuma ukuba", "Inkcubeko"], "Rebuttal.", ""),
            ("Abstract", ["Inkcubeko", "Imfundo", "Impilo"], "Abstract.", ""),
            ("Close", ["Enkosi", "Siza kudibana", "Kulungile ngokupheleleyo"], "Close.", ""),
        ]),
    ],
    "wolof": [
        ("Idioms", "Baat yu gudd", [
            ("Proverbs", ["Xel", "Kër", "Ndimbal"], "Proverbs.", ""),
            ("Rhetoric", ["Waaw", "Waaye", "Loolu moo tax"], "Links.", ""),
            ("Monologue", ["Bëgg naa wax", "Ni", "Ci mujjantal"], "Monologue.", ""),
        ]),
        ("Cert prep", "Kaw", [
            ("Rebuttal", ["Ma bëggul waaye", "Ma nangu ne", "Aada"], "Rebuttal.", ""),
            ("Abstract", ["Aada", "Xam-xam", "Wergu yaram"], "Abstract.", ""),
            ("Close", ["Jërëjëf", "Dinaa jàppante", "Baax na lool"], "Close.", ""),
        ]),
    ],
    "pidgin": [
        ("Idioms", "Deep talk", [
            ("Proverbs", ["Na condition make crayfish bend", "Body no be firewood", "No wahala"], "Street wisdom.", ""),
            ("Rhetoric", ["Na so", "But", "Na why"], "Link ideas.", ""),
            ("Monologue", ["I wan talk say", "Like", "For end"], "Structured gist.", ""),
        ]),
        ("Cert prep", "Sharp level", [
            ("Rebuttal", ["I no agree but", "I agree say", "Culture"], "Rebuttal.", ""),
            ("Abstract", ["Culture", "Education", "Health"], "Abstract.", ""),
            ("Close", ["Thank you", "We go meet", "E perfect"], "Close.", ""),
        ]),
    ],
    "afrikaans": [
        ("Idioms", "Spreekwoorde", [
            ("Proverbs", ["Die appel val nie ver van die boom nie", "Goeie goed", "Hulp"], "Proverbs.", ""),
            ("Rhetoric", ["Dit is so", "Maar", "Daarom"], "Links.", ""),
            ("Monologue", ["Ek wil sê", "Soos", "Ten slotte"], "Monologue.", ""),
        ]),
        ("Cert prep", "Gevorderd", [
            ("Rebuttal", ["Ek stem nie saam nie maar", "Ek stem saam dat", "Kultuur"], "Rebuttal.", ""),
            ("Abstract", ["Kultuur", "Onderwys", "Gesondheid"], "Abstract.", ""),
            ("Close", ["Dankie", "Ons sal ontmoet", "Perfek"], "Close.", ""),
        ]),
    ],
    "amharic": [
        ("Idioms", "ምሳሌ", [
            ("Proverbs", ["ሰላም", "ቤት", "እገዛ"], "Proverbs in use.", ""),
            ("Rhetoric", ["እንደዚህ", "ግን", "ስለዚህ"], "Formal links.", ""),
            ("Monologue", ["መናገር እፈልጋለሁ", "እንደ", "በመጨረሻ"], "Monologue.", ""),
        ]),
        ("Cert prep", "ከፍተኛ", [
            ("Rebuttal", ["አልስማምምም ግን", "እስማማለሁ", "ባህል"], "Rebuttal.", ""),
            ("Abstract", ["ባህል", "ትምህርት", "ጤና"], "Abstract.", ""),
            ("Close", ["አመሰግናለሁ", "እንገናኝ", "በጣም ጥሩ"], "Close.", ""),
        ]),
    ],
    "twi": [
        ("Idioms", "Akontabuo", [
            ("Proverbs", ["Asomdwoe", "Fie", "Mmoa"], "Proverbs.", ""),
            ("Rhetoric", ["Enti saa", "Nanso", "Esiane saa"], "Links.", ""),
            ("Monologue", ["Mepɛ sɛ meka", "Sɛ", "Awieɛ"], "Monologue.", ""),
        ]),
        ("Cert prep", "Soro", [
            ("Rebuttal", ["Mempene so nanso", "Mepene so sɛ", "Amammerɛ"], "Rebuttal.", ""),
            ("Abstract", ["Amammerɛ", "Adesua", "Apɔmuden"], "Abstract.", ""),
            ("Close", ["Meda wo ase", "Yɛbɛhyia", "Eye papa"], "Close.", ""),
        ]),
    ],
    "somali": [
        ("Idioms", "Maahmaah", [
            ("Proverbs", ["Nabad", "Guri", "Caawimaad"], "Proverbs.", ""),
            ("Rhetoric", ["Sidaas", "Laakiin", "Sababtaas awgeed"], "Links.", ""),
            ("Monologue", ["Waxaan rabaa inaan idhaahdo", "Sida", "Ugu dambeyn"], "Monologue.", ""),
        ]),
        ("Cert prep", "Sare", [
            ("Rebuttal", ["Ma ogola laakiin", "Waan ogolahay in", "Dhaqan"], "Rebuttal.", ""),
            ("Abstract", ["Dhaqan", "Waxbarasho", "Caafimaad"], "Abstract.", ""),
            ("Close", ["Mahadsanid", "Waan kulmi doonaa", "Waa fiican"], "Close.", ""),
        ]),
    ],
    "lingala": [
        ("Idioms", "Bakɔ́si", [
            ("Proverbs", ["Kimia", "Ndako", "Lisalisi"], "Proverbs.", ""),
            ("Rhetoric", ["Eza bongo", "Kasi", "Yango wana"], "Links.", ""),
            ("Monologue", ["Nalingi koloba", "Ndenge", "Na nsuka"], "Monologue.", ""),
        ]),
        ("Cert prep", "Likolo", [
            ("Rebuttal", ["Nandimi te kasi", "Nandimi ete", "Bizaleli"], "Rebuttal.", ""),
            ("Abstract", ["Bizaleli", "Boyekoli", "Sante"], "Abstract.", ""),
            ("Close", ["Matondi", "Tokomonana", "Malamu mingi"], "Close.", ""),
        ]),
    ],
    "shona": [
        ("Idioms", "Tsumo", [
            ("Proverbs", ["Runyararo", "Imba", "Rubatsiro"], "Proverbs.", ""),
            ("Rhetoric", ["Zvakadaro", "Asi", "Saka"], "Links.", ""),
            ("Monologue", ["Ndinoda kutaura", "Sekunge", "Pakupedzisira"], "Monologue.", ""),
        ]),
        ("Cert prep", "Pamusoro", [
            ("Rebuttal", ["Handibvumi asi", "Ndinobvuma kuti", "Tsika"], "Rebuttal.", ""),
            ("Abstract", ["Tsika", "Dzidzo", "Utano"], "Abstract.", ""),
            ("Close", ["Ndatenda", "Tichasangana", "Zvakanaka chaizvo"], "Close.", ""),
        ]),
    ],
}

# A2/B1 for extended languages (mirror launch themes)
from .a2_b1_units import A2_UNITS as _A2_BASE, B1_UNITS as _B1_BASE  # noqa: E402

for _lang in ("afrikaans", "amharic", "twi", "somali", "lingala", "shona"):
    if _lang not in _A2_BASE:
        B2_UNITS.setdefault(_lang, B2_UNITS.get("swahili", []))
    if _lang not in C1_UNITS:
        pass  # all defined above

# Ensure extended langs have A2/B1 if missing in base file
_EXTENDED_A2: dict[str, list] = {
    "afrikaans": [
        ("Past & stories", "Gister", [
            ("Past", ["Ek het geëet", "Hy het gekom", "Ons het gegaan"], "Past tense.", ""),
            ("Story", ["Gister", "Op 'n dag", "Ek het gesien"], "Narrative.", ""),
            ("Feelings", ["Ek is bly", "Ek is kwaad", "Ek hou van"], "Emotions.", ""),
        ]),
        ("Work & plans", "Werk", [
            ("Work", ["Werk", "Kantoor", "Ek werk"], "Work talk.", ""),
            ("Help", ["Asseblief help my", "Kan jy?", "Ek wil"], "Requests.", ""),
            ("Future", ["Ek sal gaan", "Môre", "Twee uur"], "Future.", ""),
        ]),
    ],
    "amharic": [
        ("Past & stories", "ትላንት", [
            ("Past", ["በላሁ", "መጣ", "ሄድን"], "Past actions.", ""),
            ("Story", ["ትላንት", "አንድ ቀን", "አየሁ"], "Story frame.", ""),
            ("Feelings", ["ደስ ብሎኛል", "ተቆጥቻለሁ", "ወድዳለሁ"], "Emotions.", ""),
        ]),
        ("Work", "ስራ", [
            ("Work", ["ስራ", "ቢሮ", "እሰራለሁ"], "Work.", ""),
            ("Help", ["እባክህ ረዳኝ", "ትችላለህ?", "እፈልጋለሁ"], "Help.", ""),
            ("Future", ["እሄዳለሁ", "ነገ", "ሁለት ሰዓት"], "Plans.", ""),
        ]),
    ],
    "twi": [
        ("Past & stories", "Deda", [
            ("Past", ["Meadi", "Ɔbaa", "Yɛkɔɔ"], "Past.", ""),
            ("Story", ["Deda", "Da bi", "Mihuu"], "Story.", ""),
            ("Feelings", ["Anigye", "Abufuo", "Mepɛ"], "Feelings.", ""),
        ]),
        ("Work", "Adwuma", [
            ("Work", ["Adwuma", "Ofis", "Mɛdwuma"], "Work.", ""),
            ("Help", ["Mesrɛ wo boa me", "Wubetumi?", "Mepɛ"], "Help.", ""),
            ("Future", ["Mɛkɔ", "Ɔkyena", "Mpreabien"], "Future.", ""),
        ]),
    ],
    "somali": [
        ("Past & stories", "Shalay", [
            ("Past", ["Waan cunay", "Wuu yimid", "Waan tagnay"], "Past.", ""),
            ("Story", ["Shalay", "Maalin", "Waan arkay"], "Story.", ""),
            ("Feelings", ["Waan faraxsanahay", "Waan cadhooday", "Waan jeclahay"], "Feelings.", ""),
        ]),
        ("Work", "Shaqo", [
            ("Work", ["Shaqo", "Xafiis", "Waan shaqeeyaa"], "Work.", ""),
            ("Help", ["Fadlan i caawi", "Ma awoodaa?", "Waan rabaa"], "Help.", ""),
            ("Future", ["Waan tegi doonaa", "Berri", "Laba saac"], "Future.", ""),
        ]),
    ],
    "lingala": [
        ("Past & stories", "Lobi", [
            ("Past", ["Malaki", "Ayei", "Tokei"], "Past.", ""),
            ("Story", ["Lobi", "Mokolo moko", "Namoni"], "Story.", ""),
            ("Feelings", ["Nasepeli", "Nazui", "Nalingi"], "Feelings.", ""),
        ]),
        ("Work", "Mosala", [
            ("Work", ["Mosala", "Bureau", "Nasalaka"], "Work.", ""),
            ("Help", ["Svp salisa ngai", "Okoki?", "Nalingi"], "Help.", ""),
            ("Future", ["Nakokende", "Lobi", "Mokolo mibale"], "Future.", ""),
        ]),
    ],
    "shona": [
        ("Past & stories", "Nezuro", [
            ("Past", ["Ndadya", "Akasvika", "Taenda"], "Past.", ""),
            ("Story", ["Nezuro", "Zuva rimwe", "Ndakaona"], "Story.", ""),
            ("Feelings", ["Ndinofara", "Ndakatsamwa", "Ndinoda"], "Feelings.", ""),
        ]),
        ("Work", "Basa", [
            ("Work", ["Basa", "Ophisi", "Ndinoshanda"], "Work.", ""),
            ("Help", ["Ndapota ndibatsire", "Unogona?", "Ndinoda"], "Help.", ""),
            ("Future", ["Ndichaenda", "Mangwana", "Maawa maviri"], "Future.", ""),
        ]),
    ],
}

_EXTENDED_B1: dict[str, list] = {
    "afrikaans": [
        ("Opinions", "Menings", [
            ("Think", ["Ek dink", "Ek stem saam", "Ek stem nie saam nie"], "Opinions.", ""),
            ("Debate", ["Regtig?", "Nie reg nie", "Ek verstaan"], "Debate.", ""),
            ("News", ["Nuus", "Radio", "Ek het gehoor"], "News.", ""),
        ]),
        ("Community", "Gemeenskap", [
            ("Health", ["Siekte", "Medisyne", "Ek is siek"], "Health.", ""),
            ("Society", ["Gemeenskap", "Skool", "Kultuur"], "Society.", ""),
            ("Advice", ["Ek sal versigtig wees", "Dit is belangrik", "Asseblief"], "Advice.", ""),
        ]),
    ],
    "amharic": [
        ("Opinions", "አስተያየት", [
            ("Think", ["እመስላለሁ", "እስማማለሁ", "አልስማምምም"], "Opinions.", ""),
            ("Debate", ["እንደዚህ ነው?", "አይሆንም", "ገባኝ"], "Debate.", ""),
            ("News", ["ዜና", "ራዲዮ", "ሰምቻለሁ"], "News.", ""),
        ]),
        ("Community", "ማህበረሰብ", [
            ("Health", ["በሽታ", "መድሃኒት", "እሳብያለሁ"], "Health.", ""),
            ("Society", ["ማህበረሰብ", "ትምህርት ቤት", "ባህል"], "Society.", ""),
            ("Advice", ["ጥንቃቄ እደርጋለሁ", "አስፈላጊ ነው", "እባክህ"], "Advice.", ""),
        ]),
    ],
    "twi": [
        ("Opinions", "Adwene", [
            ("Think", ["Misusuw sɛ", "Mepene so", "Mempene so"], "Opinions.", ""),
            ("Debate", ["Enti saa?", "Ɛnyɛ saa", "Mete aseɛ"], "Debate.", ""),
            ("News", ["Nnwom", "Redio", "Metee"], "News.", ""),
        ]),
        ("Community", "Asafo", [
            ("Health", ["Yare", "Aduro", "Yare"], "Health.", ""),
            ("Society", ["Asafo", "Sukuu", "Amammerɛ"], "Society.", ""),
            ("Advice", ["Mɛhwɛ yiye", "Ɛho hia", "Mesrɛ wo"], "Advice.", ""),
        ]),
    ],
    "somali": [
        ("Opinions", "Ra'yiga", [
            ("Think", ["Waxaan u maleynayaa", "Waan ogolahay", "Ma ogola"], "Opinions.", ""),
            ("Debate", ["Sidaas ma aha?", "Ma aha sidaas", "Waan fahmay"], "Debate.", ""),
            ("News", ["War", "Raadiyo", "Waan maqlay"], "News.", ""),
        ]),
        ("Community", "Bulsho", [
            ("Health", ["Cudur", "Daawo", "Waan xanuunsanahay"], "Health.", ""),
            ("Society", ["Bulsho", "Dugsi", "Dhaqan"], "Society.", ""),
            ("Advice", ["Waan taxaddarayaa", "Waa muhiim", "Fadlan"], "Advice.", ""),
        ]),
    ],
    "lingala": [
        ("Opinions", "Makanisi", [
            ("Think", ["Nakanisi ete", "Nandimi", "Nandimi te"], "Opinions.", ""),
            ("Debate", ["Vraiment?", "Ezali te bongo", "Nayebi"], "Debate.", ""),
            ("News", ["Sango", "Radio", "Nayokaki"], "News.", ""),
        ]),
        ("Community", "Lisanga", [
            ("Health", ["Maladi", "Mingi", "Nazui"], "Health.", ""),
            ("Society", ["Lisanga", "Eteyelo", "Bizaleli"], "Society.", ""),
            ("Advice", ["Nakokanisa", "Ezali ntina", "Svp"], "Advice.", ""),
        ]),
    ],
    "shona": [
        ("Opinions", "Mafungiro", [
            ("Think", ["Ndinofunga", "Ndinobvuma", "Handibvumi"], "Opinions.", ""),
            ("Debate", ["Chokwadi?", "Hazvina kuita", "Ndinonzwisisa"], "Debate.", ""),
            ("News", ["Nhau", "Redhiyo", "Ndakanzwa"], "News.", ""),
        ]),
        ("Community", "Nharaunda", [
            ("Health", ["Chirwere", "Mishonga", "Ndarwara"], "Health.", ""),
            ("Society", ["Nharaunda", "Chikoro", "Tsika"], "Society.", ""),
            ("Advice", ["Ndichachengeta", "Zvakakosha", "Ndapota"], "Advice.", ""),
        ]),
    ],
}

# Export merged A2/B1 for extended langs (imported by packs.py)
EXTENDED_A2_UNITS = _EXTENDED_A2
EXTENDED_B1_UNITS = _EXTENDED_B1

# ---------------------------------------------------------------------------
# C2 — Mastery / Near-native fluency
#
# C2 lessons emphasise advanced register, rhetoric, idioms and abstract
# discourse. Each language ships two units of three lessons covering
# (1) mastery rhetoric / public speaking, and (2) cultural literacy / nuance.
# ---------------------------------------------------------------------------
C2_UNITS: dict[str, list] = {
    "yoruba": [
        ("Mastery rhetoric", "Ọ̀rọ̀ jíjinlẹ̀", [
            ("Hedge & nuance", ["Bí ó tilẹ̀ jẹ́ pé", "Lẹ́yìn àyẹ̀wò", "Ó ṣe é ṣe pé"], "Hedge claims like a native speaker.", "C2 speakers signal uncertainty politely."),
            ("Public address", ["Ẹ̀yin ọ̀wọ́", "Mo dúpẹ́ lọ́wọ́ yín", "Lẹ́yìn òwò àjọ"], "Open and close formal addresses.", "Public speech follows a kɔn-pó-án arc."),
            ("Rhetorical force", ["Báwo ni kò ṣe le jẹ́ pé", "Ìbéèrè ni pé", "Èyí ni mo fẹ́ tẹnumọ́"], "Drive a point with rhetorical questions.", ""),
        ]),
        ("Cultural literacy", "Ọgbọ́n àti àṣà", [
            ("Idioms in argument", ["Ọwọ́ ti kọ́ ní eégún", "Bí omi ṣe ń tú yìnyín", "Ẹnu ti àgbà"], "Wield idioms in advanced discourse.", "Idioms persuade more than facts."),
            ("Code-switching", ["Mo máa fi èdè Gẹ̀ẹ́sì", "Padà sí Yorùbá", "Ó dára ká kọ́"], "Manage register shifts intentionally.", "Code-switching marks identity."),
            ("Subtle persuasion", ["Bí a bá rò ó", "Kì í ṣe ìrọ̀rùn", "Mo nírètí pé"], "Persuade with measured language.", ""),
        ]),
    ],
    "hausa": [
        ("Mastery rhetoric", "Magana mai zurfi", [
            ("Hedge", ["Watakila", "Bayan an duba", "Yana yiwuwa"], "Hedge complex claims.", ""),
            ("Address", ["Manyan jama'a", "Na gode da", "Bayan duka"], "Formal address.", ""),
            ("Force", ["Yaya zai yiwu", "Tambaya ita ce", "Ina son in karfafa"], "Rhetorical force.", ""),
        ]),
        ("Cultural literacy", "Al'ada", [
            ("Idioms", ["Hannu ya san karfi", "Kamar ruwa", "Bakin dattijo"], "Idioms in argument.", ""),
            ("Code-switching", ["Zan yi da Turanci", "Komawa Hausa", "Yana da kyau"], "Code-switching.", ""),
            ("Persuasion", ["In muka yi tunani", "Ba abu ne mai sauki ba", "Ina fata"], "Subtle persuasion.", ""),
        ]),
    ],
    "igbo": [
        ("Mastery rhetoric", "Okwu miri emi", [
            ("Hedge", ["Eleghi anya", "Mgbe e leworo", "Ọ ga-ekwe omume"], "Hedge claims.", ""),
            ("Address", ["Ndị ọha", "Daalụ maka", "N'ọnụ ụzọ"], "Formal address.", ""),
            ("Force", ["Kedu ka ọ ga-esi", "Ajụjụ bụ", "Achọrọ m ime ka"], "Rhetorical force.", ""),
        ]),
        ("Cultural literacy", "Omenala", [
            ("Idioms", ["Aka mụtara olu", "Dị ka mmiri", "Ọnụ okenye"], "Use idioms.", ""),
            ("Code-switching", ["Aga m eji Bekee", "Laghachi Igbo", "Ọ dị mma"], "Code-switching.", ""),
            ("Persuasion", ["Ọ bụrụ na anyị echere", "Ọ bụghị ihe dị mfe", "Atụrụ m anya"], "Subtle persuasion.", ""),
        ]),
    ],
    "swahili": [
        ("Mastery rhetoric", "Hotuba ya kiwango", [
            ("Hedge", ["Huenda", "Baada ya uchunguzi", "Inawezekana"], "Hedge.", ""),
            ("Address", ["Waheshimiwa", "Asante kwa", "Baada ya yote"], "Address.", ""),
            ("Force", ["Inawezekanaje", "Swali ni", "Nataka kusisitiza"], "Rhetorical force.", ""),
        ]),
        ("Cultural literacy", "Utamaduni", [
            ("Idioms", ["Mkono umejifunza", "Kama maji", "Mdomo wa mzee"], "Idioms.", ""),
            ("Code-switching", ["Nitatumia Kiingereza", "Kurudi Kiswahili", "Ni vyema"], "Code-switching.", ""),
            ("Persuasion", ["Tukifikiri", "Si jambo rahisi", "Ninatumaini"], "Persuasion.", ""),
        ]),
    ],
    "zulu": [
        ("Mastery rhetoric", "Inkulumo ephakeme", [
            ("Hedge", ["Mhlawumbe", "Ngemuva kokuhlola", "Kungenzeka"], "Hedge.", ""),
            ("Address", ["Bahlonishwayo", "Ngiyabonga", "Ekugcineni"], "Address.", ""),
            ("Force", ["Kungenzeka kanjani", "Umbuzo uthi", "Ngifuna ukugcizelela"], "Force.", ""),
        ]),
        ("Cultural literacy", "Amasiko", [
            ("Idioms", ["Isandla siyazi", "Njengamanzi", "Umlomo womdala"], "Idioms.", ""),
            ("Code-switching", ["Ngizosebenzisa isiNgisi", "Buyela isiZulu", "Kulungile"], "Code-switching.", ""),
            ("Persuasion", ["Uma sicabanga", "Akulula", "Ngithemba"], "Persuasion.", ""),
        ]),
    ],
    "xhosa": [
        ("Mastery rhetoric", "Intetho ephakamileyo", [
            ("Hedge", ["Mhlawumbi", "Emva kokuhlola", "Kungenzeka"], "Hedge.", ""),
            ("Address", ["Bahlonelwa", "Ndiyabulela", "Ekugqibeleni"], "Address.", ""),
            ("Force", ["Kungenzeka njani", "Umbuzo uthi", "Ndifuna ukugxininisa"], "Force.", ""),
        ]),
        ("Cultural literacy", "Isiko", [
            ("Idioms", ["Isandla siyazi", "Njengamanzi", "Umlomo wabadala"], "Idioms.", ""),
            ("Code-switching", ["Ndizakusebenzisa isiNgesi", "Buyela isiXhosa", "Kulungile"], "Code-switching.", ""),
            ("Persuasion", ["Ukuba siyacinga", "Akulula", "Ndinethemba"], "Persuasion.", ""),
        ]),
    ],
    "wolof": [
        ("Mastery rhetoric", "Waxtaan bu xóot", [
            ("Hedge", ["Xanaa", "Sopplu ko", "Mën nañu ko jëf"], "Hedge.", ""),
            ("Address", ["Yéen waa", "Jërejëf ci", "Ci dénd la"], "Address.", ""),
            ("Force", ["Naka la mën a ame", "Laaj la", "Damay bëgg a wone"], "Force.", ""),
        ]),
        ("Cultural literacy", "Cosaan", [
            ("Idioms", ["Loxo dafa xam", "Mel ni ndox", "Géwél gu mag"], "Idioms.", ""),
            ("Code-switching", ["Maa ngi jëfandikoo Anglais", "Dellu ci Wolof", "Baax na"], "Code-switching.", ""),
            ("Persuasion", ["Bu ñu xalaate", "Du yomb", "Yaakaar naa ne"], "Persuasion.", ""),
        ]),
    ],
    "pidgin": [
        ("Mastery rhetoric", "Big-big sabi talk", [
            ("Hedge", ["E fit be say", "After we don check", "E possible"], "Hedge.", ""),
            ("Address", ["Una well well", "I dey thank una", "After everything"], "Address.", ""),
            ("Force", ["How e go take be", "The question be say", "I wan emphasize"], "Force.", ""),
        ]),
        ("Cultural literacy", "Wisdom for street", [
            ("Idioms", ["Hand don sabi", "Like water", "Mouth of elder"], "Idioms.", ""),
            ("Code-switching", ["I go use English", "Come back to Pidgin", "E dey alright"], "Code-switching.", ""),
            ("Persuasion", ["If we think am", "E no easy", "I dey hope"], "Persuasion.", ""),
        ]),
    ],
    "afrikaans": [
        ("Mastery rhetoric", "Hoë register", [
            ("Hedge", ["Moontlik", "Ná oorweging", "Dit kan wees"], "Hedge.", ""),
            ("Address", ["Geagte gehoor", "Dankie vir", "Ná alles"], "Address.", ""),
            ("Force", ["Hoe kan dit wees", "Die vraag is", "Ek wil beklemtoon"], "Force.", ""),
        ]),
        ("Cultural literacy", "Kultuur", [
            ("Idioms", ["Die hand weet", "Soos water", "Die mond van die oue"], "Idioms.", ""),
            ("Code-switching", ["Ek sal Engels gebruik", "Terug na Afrikaans", "Dis goed"], "Code-switching.", ""),
            ("Persuasion", ["As ons dink", "Dis nie maklik nie", "Ek hoop"], "Persuasion.", ""),
        ]),
    ],
    "amharic": [
        ("Mastery rhetoric", "ጥልቅ ንግግር", [
            ("Hedge", ["ምናልባት", "ከመመርመር በኋላ", "ሊሆን ይችላል"], "Hedge.", ""),
            ("Address", ["የተከበራችሁ", "አመሰግናለሁ ስለ", "ከሁሉም በኋላ"], "Address.", ""),
            ("Force", ["እንዴት ሊሆን ይችላል", "ጥያቄው ነው", "አጽንኦት መስጠት እፈልጋለሁ"], "Force.", ""),
        ]),
        ("Cultural literacy", "ባህል", [
            ("Idioms", ["እጅ አወቀ", "እንደ ውሃ", "የሽማግሌ አፍ"], "Idioms.", ""),
            ("Code-switching", ["እንግሊዝኛ እጠቀማለሁ", "ወደ አማርኛ ተመለስ", "ጥሩ ነው"], "Code-switching.", ""),
            ("Persuasion", ["ካሰብን", "ቀላል አይደለም", "ተስፋ አደርጋለሁ"], "Persuasion.", ""),
        ]),
    ],
    "twi": [
        ("Mastery rhetoric", "Kasa a emu yɛ duru", [
            ("Hedge", ["Ebia", "Akyiri yi a", "Ebetumi aba"], "Hedge.", ""),
            ("Address", ["Mo nyinaa", "Meda mo ase", "Akyiri biara"], "Address.", ""),
            ("Force", ["Ɛbɛyɛ dɛn", "Asɛm no ne sɛ", "Mepɛ sɛ meka"], "Force.", ""),
        ]),
        ("Cultural literacy", "Amammerɛ", [
            ("Idioms", ["Nsa nim", "Sɛ nsuo", "Opanyin ano"], "Idioms.", ""),
            ("Code-switching", ["Mede Borɔfo bɛyɛ", "San kɔ Twi", "Ɛyɛ"], "Code-switching.", ""),
            ("Persuasion", ["Sɛ yɛsusu a", "Ɛnyɛ mmerɛ", "Mewɔ anidasoɔ"], "Persuasion.", ""),
        ]),
    ],
    "somali": [
        ("Mastery rhetoric", "Hadal sare", [
            ("Hedge", ["Waxaa laga yaabaa", "Ka dib eegista", "Way suurtagal tahay"], "Hedge.", ""),
            ("Address", ["Mudaneyaal", "Waan idinku mahadinayaa", "Ka dib dhammaan"], "Address.", ""),
            ("Force", ["Sidee bay u dhici kartaa", "Su'aashu waxay tahay", "Waxaan rabaa inaan xoojiyo"], "Force.", ""),
        ]),
        ("Cultural literacy", "Dhaqan", [
            ("Idioms", ["Gacanta way taqaan", "Sida biyo", "Afka odayga"], "Idioms.", ""),
            ("Code-switching", ["Waan isticmaali doonaa Ingiriis", "Dib ugu noqo Soomaali", "Way fiicantahay"], "Code-switching.", ""),
            ("Persuasion", ["Haddaan ka fikirno", "Ma sahlana", "Waan rajeyaa"], "Persuasion.", ""),
        ]),
    ],
    "lingala": [
        ("Mastery rhetoric", "Lokota ya monene", [
            ("Hedge", ["Tango mosusu", "Sima ya kotala", "Ekoki kosalema"], "Hedge.", ""),
            ("Address", ["Bino banso", "Natondi bino", "Sima ya nyonso"], "Address.", ""),
            ("Force", ["Ndenge nini ekosalema", "Motuna ezali", "Nalingi kotia mboka"], "Force.", ""),
        ]),
        ("Cultural literacy", "Bonkoko", [
            ("Idioms", ["Loboko eyebi", "Lokola mai", "Monoko ya mokóló"], "Idioms.", ""),
            ("Code-switching", ["Nakosalela Lingelesi", "Zonga na Lingala", "Ezali malamu"], "Code-switching.", ""),
            ("Persuasion", ["Soki tokanisi", "Ezali pasi te", "Nazali na elikya"], "Persuasion.", ""),
        ]),
    ],
    "shona": [
        ("Mastery rhetoric", "Hurukuro yepamusoro", [
            ("Hedge", ["Pamwe", "Mushure mokuongorora", "Zvinogona kuitika"], "Hedge.", ""),
            ("Address", ["Imi mose", "Ndinotenda nezve", "Mushure mezvose"], "Address.", ""),
            ("Force", ["Zvingaita sei", "Mubvunzo unoti", "Ndinoda kusimbisa"], "Force.", ""),
        ]),
        ("Cultural literacy", "Tsika", [
            ("Idioms", ["Ruoko runoziva", "Semvura", "Muromo wevakuru"], "Idioms.", ""),
            ("Code-switching", ["Ndichashandisa chiNgezi", "Dzokera kuChishona", "Zvakanaka"], "Code-switching.", ""),
            ("Persuasion", ["Kana tichifunga", "Hazvisi nyore", "Ndinotarisira"], "Persuasion.", ""),
        ]),
    ],
}
