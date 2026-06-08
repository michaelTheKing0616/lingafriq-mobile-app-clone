# -*- coding: utf-8 -*-
"""Authentic vocabulary, proverbs, scenarios, and A1 curriculum units."""

from __future__ import annotations

import copy
from typing import Any

LAUNCH_LANGUAGES = [
    "yoruba",
    "hausa",
    "igbo",
    "swahili",
    "zulu",
    "xhosa",
    "wolof",
    "pidgin",
]

EXTENDED_LANGUAGES = [
    "afrikaans",
    "amharic",
    "twi",
    "somali",
]

EXPANSION_LANGUAGES = [
    "lingala",
    "shona",
]

CURRICULUM_LANGUAGES = LAUNCH_LANGUAGES + EXTENDED_LANGUAGES + EXPANSION_LANGUAGES

# game_tags align with word_repo + game screens (PascalCase game names in scenarios)
_COMMON_TAGS = [
    "WordMatch",
    "SpeedRound",
    "PronunciationDuel",
    "ToneTrainer",
    "FlashcardSafari",
    "GreetingDiplomacy",
    "MarketBargaining",
    "FoodQuest",
    "Roleplay",
    "ProverbUnlocker",
]

LANG_PACKS: dict[str, dict[str, Any]] = {
    "yoruba": {
        "display": "Yoruba",
        "words": [
            ("Ẹ kú àárọ̀", "Good morning (to elders/group)", "greeting", "High tone on àárọ̀ marks respect", "Time-based greeting; always greet before asking for anything."),
            ("Ẹ kú ọ̀sán", "Good afternoon", "greeting", "", "Used from late morning through afternoon."),
            ("Ẹ kú alẹ́", "Good evening", "greeting", "", "Evening greeting; tone matters for clarity."),
            ("Báwo ni", "How are you? (informal)", "greeting", "", "Casual; use with peers."),
            ("Orúkọ mi ni", "My name is…", "phrase", "", "Introduce yourself before requests."),
            ("Ẹ ṣé", "Thank you", "expression", "", "Essential courtesy in every exchange."),
            ("Ẹ jọ̀wọ́", "Please", "expression", "", "Softens requests; shows respect."),
            ("Mo wá láti", "I come from…", "phrase", "", "Heritage learners use this to reconnect."),
            ("Ìyá", "Mother", "noun", "", "Family respect titles follow kinship."),
            ("Bàbá", "Father", "noun", "", ""),
            ("Ẹ̀bí", "Family", "noun", "", ""),
            ("Oúnjẹ", "Food", "noun", "ó-un-jẹ", "Market and home vocabulary."),
            ("Omi", "Water", "noun", "", ""),
            ("Owó", "Money", "noun", "Tone distinguishes from òwò (honour)", "Market bargaining essential."),
            ("Ilé", "House / home", "noun", "", ""),
            ("Mọ́tò", "Car", "noun", "", "Transport vocabulary."),
            ("Níbo ni… wà?", "Where is…?", "phrase", "", "Directions in the city."),
            ("Mo fẹ́", "I want", "phrase", "", "Market survival pattern."),
            ("Ẹ́élo ni?", "How much?", "phrase", "", "Ask after greeting the seller."),
            ("Ó dára", "It is good / fine", "phrase", "", "Positive response in conversation."),
            ("Mo ń ṣe dáadáa", "I am fine", "phrase", "", "Standard reply to báwo ni."),
            ("Ẹ káàbọ̀", "Welcome", "expression", "", "Host says this to guests."),
            ("Pẹ̀lẹ́", "Slowly / gently", "adverb", "", "Useful when learning pronunciation."),
            ("Ṣé o lè sọ̀rọ̀?", "Can you speak?", "phrase", "", "Asking for slower speech."),
            ("Mo ń kọ́ èdè Yorùbá", "I am learning Yoruba", "phrase", "", "Builds rapport with native speakers."),
            ("Ọ̀rọ̀", "Word / speech", "noun", "", ""),
            ("Ìbánisọ̀rọ̀", "Conversation", "noun", "", ""),
            ("Ọjà", "Market", "noun", "", "Central cultural space for trade."),
            ("Aṣọ", "Clothing / fabric", "noun", "", "Popular market item."),
            ("Ata", "Pepper", "noun", "", "Food market staple."),
            ("Dúdú", "Black / dark", "adjective", "", ""),
            ("Funfun", "White", "adjective", "", ""),
            ("Ó wú", "It is expensive", "phrase", "", "Opens bargaining respectfully."),
            ("Jọ̀ọ́", "Reduce the price", "verb", "", "Polite haggling phrase."),
        ],
        "proverbs": [
            ("Ìwà lẹwà", "Character is beauty", "Inner conduct matters more than appearance."),
            ("Ọwọ́ ọ̀rẹ́ kò ṣeé fi we", "A friend's hand is not weighed on scales", "True friendship is generous."),
            ("Bi a bá ń sọ̀rọ̀, a máa ń mọ̀", "If we keep talking, we come to know each other", "Conversation builds trust."),
            ("Àgbà kì í wà lọ́jà ká máa gbọ́ rẹ̀", "An elder is never in the market without us hearing wisdom", "Respect elders' speech."),
            ("Ilé ọba tó jú, ẹ̀kọ́ ló ń kó", "The palace that is far is learned about through stories", "Oral tradition carries knowledge."),
            ("Eni bá ṣeré, á máa rí inú rere", "Whoever plays will find joy inside", "Humour and play have value."),
        ],
        "scenarios": {
            "MarketBargaining": [
                ("Fabric stall at Balogun", "Ẹ kú àárọ̀, ìyá. Ẹ́élo ni àṣọ yìí?", "Greet first, then ask price", "Never open with price alone at a Yoruba market."),
                ("Spice seller", "Ata yìí dára gan-an. Ó wú díẹ̀.", "Compliment quality before counter-offer", "Praise opens friendly negotiation."),
                ("Bead trader", "Mo fẹ́ ìlẹ̀kẹ̀ méjì. Jọ̀ọ́ fún mi.", "Ask for two; request gentle reduction", "Bulk or bundle requests show intent to buy."),
            ],
            "GreetingDiplomacy": [
                ("Meeting an elder", "Ẹ kú àárọ̀, bàbá. Sé àlàáfíà ni?", "Morning + ask after wellbeing", "Use plural respect forms even to one elder."),
                ("Arriving at a home", "Ẹ káàbọ̀. Mo wá láti rí ẹ̀bí mi.", "Welcome exchange + purpose", "Hosts often respond with questions before seating."),
                ("Community event", "Ẹ kú ilé o, gbogbo wa.", "Greet the house and everyone", "Group greeting shows social awareness."),
            ],
            "TaxiSurvival": [
                ("Negotiating fare", "Mo ń lọ sí Ìkòyí. Ẹ́élo ni owó mọ́tò?", "State destination, then fare", "Confirm fare before entering."),
                ("Stop request", "Ẹ jọ̀wọ́, dúró níbí.", "Please stop here", "Polite imperative."),
                ("Lost direction", "Níbo ni ọjà ń wà?", "Where is the market?", "Landmarks help drivers help you."),
            ],
            "RoleplayAdventure": [
                ("Voice note from cousin", "Báwo ni? Mo ń rò ẹ. Báwo ni ìlé?", "Casual check-in on family", "Voice notes mirror real diaspora use."),
                ("First day at work", "Ẹ kú àárọ̀. Orúkọ mi ni Ade. Mo wá láti ṣiṣẹ́.", "Formal intro at workplace", "Professional register is calmer and clearer."),
            ],
            "EldersBlessings": [
                ("After helping an elder", "Ẹ ṣé, ìyá. Mo ń lọ.", "Thanks before leaving", "Elders may offer a blessing in return."),
                ("Naming ceremony visit", "Ẹ kú ọ̀sán. Orúkọ ọmọ dára púpọ̀.", "Afternoon greeting + compliment child's name", "Names carry deep cultural meaning."),
            ],
            "CulturalEtiquette": [
                ("Offering seat", "Ẹ jọ̀wọ́, jókòó.", "Please sit", "Physical gestures accompany speech."),
                ("Receiving with two hands", "Ẹ ṣé pupọ̀.", "Thank you very much", "Shows respect when receiving items."),
            ],
        },
        "units": [
            ("Discovery & Sound", "Welcome to Yoruba", [
                ("Sounds & identity", ["Mo ń kọ́ èdè Yorùbá", "Orúkọ mi ni", "Ó dára"], "Introduce yourself simply.", "Yoruba is tonal — listen before perfection."),
                ("Morning greetings", ["Ẹ kú àárọ̀", "Báwo ni", "Mo ń ṣe dáadáa"], "Greet by time of day.", "Greeting culture is the spine of social life."),
                ("Thank you & please", ["Ẹ ṣé", "Ẹ jọ̀wọ́", "Ẹ káàbọ̀"], "Courtesy phrases.", "Politeness opens every door."),
            ]),
            ("Family & Respect", "Family tree", [
                ("Core kinship", ["Ìyá", "Bàbá", "Ẹ̀bí"], "Name close family.", "Respect titles extend beyond blood family."),
                ("Meeting elders", ["Ẹ kú àárọ̀", "Sé àlàáfíà ni?", "Pẹ̀lẹ́"], "Slow, respectful speech.", "Elders are greeted before younger peers."),
                ("Home visit", ["Ẹ káàbọ̀", "Mo wá láti rí ẹ̀bí mi", "Ilé"], "State why you came.", "Hosts may offer food before business."),
            ]),
            ("Market survival", "At the market", [
                ("Food words", ["Oúnjẹ", "Omi", "Ata"], "Buy essentials.", "Markets are social — greet each stall."),
                ("Prices", ["Ẹ́élo ni?", "Mo fẹ́", "Ó wú"], "Ask and respond.", "Compliment goods before bargaining."),
                ("Closing a deal", ["Jọ̀ọ́", "Ẹ ṣé", "Mo ń lọ"], "Negotiate thanks and exit.", "Walking away can be a tactic — stay polite."),
            ]),
            ("Getting around", "Transport & directions", [
                ("Places", ["Ilé", "Ọjà", "Níbo ni… wà?"], "Find locations.", "Landmarks beat street numbers."),
                ("Vehicle", ["Mọ́tò", "Mo ń lọ sí", "Dúró níbí"], "Ride and stop.", "Agree fare early."),
                ("Check-in", ["Báwo ni?", "Mo ń ṣe dáadáa", "Ṣé o lè sọ̀rọ̀?"], "Ask for slower speech.", "Confidence matters more than perfection."),
            ]),
            ("Tone & confidence", "Speak boldly", [
                ("Tone pairs", ["Owó", "òwò", "Ó dára"], "Hear meaning shifts.", "Same syllable, different tone = different word."),
                ("Rhythm", ["Pẹ̀lẹ́", "Mo ń sọ̀rọ̀", "Ìbánisọ̀rọ̀"], "Practice pacing.", "Speak boldly before speaking perfectly."),
                ("Proverb hook", ["Ìwà lẹwà", "Ọwọ́ ọ̀rẹ́ kò ṣeé fi we"], "Cultural closure.", "Proverbs signal cultural fluency."),
            ]),
        ],
    },
    "hausa": {
        "display": "Hausa",
        "words": [
            ("Sannu", "Hello / peace", "greeting", "", "Universal greeting across Northern Nigeria and Sahel."),
            ("Ina kwana?", "How did you sleep?", "greeting", "", "Morning greeting showing care."),
            ("Ina lafiya?", "How are you?", "greeting", "", "Standard wellbeing check."),
            ("Na gode", "Thank you", "expression", "", "Essential courtesy."),
            ("Don Allah", "Please", "expression", "", "Literally 'for God's sake' — very common."),
            ("Sunana", "My name is", "phrase", "", ""),
            ("Ina zuwa daga", "I come from", "phrase", "", ""),
            ("Uwa", "Mother", "noun", "", ""),
            ("Uba", "Father", "noun", "", ""),
            ("Iyali", "Family", "noun", "", ""),
            ("Abinci", "Food", "noun", "", "Market and hospitality vocabulary."),
            ("Ruwa", "Water", "noun", "", ""),
            ("Kudi", "Money", "noun", "", "Trade language core."),
            ("Gida", "House", "noun", "", ""),
            ("Mota", "Car", "noun", "", ""),
            ("Ina ne…?", "Where is…?", "phrase", "", ""),
            ("Ina so", "I want", "phrase", "", ""),
            ("Nawa ne?", "How much?", "phrase", "", "Ask after sannu."),
            ("Yayi kyau", "It is good", "phrase", "", ""),
            ("Lafiya lau", "Fine / healthy", "phrase", "", "Reply to ina lafiya."),
            ("Barka da zuwa", "Welcome", "expression", "", ""),
            ("A hankuri", "Slowly", "adverb", "", ""),
            ("Kasuwa", "Market", "noun", "", "Trade-centred culture."),
            ("Danka", "Thank you (response)", "expression", "", ""),
            ("Barka", "Blessing / congratulations", "expression", "", ""),
            ("Tafiya", "Journey", "noun", "", "Travel and caravan heritage."),
            ("Kasuwanci", "Trade", "noun", "", ""),
            ("Dai-dai", "Fair / correct", "adjective", "", "Negotiation term."),
            ("Kadan", "A little", "adverb", "", "Reduce price politely."),
            ("Mai kyau", "Good / beautiful", "phrase", "", ""),
            ("Yi hakuri", "Sorry / excuse me", "phrase", "", ""),
            ("Ina jin Hausa", "I am learning Hausa", "phrase", "", ""),
            ("Littafi", "Book", "noun", "", "Scholarly tradition."),
            ("Mallam", "Teacher / learned person", "noun", "", "Respect title."),
        ],
        "proverbs": [
            ("Karatu, farkonka", "Learning is the beginning", "Education opens paths."),
            ("Gida bai daya ba", "A house is never one (alone)", "Community matters."),
            ("Hankuri ya ci gaba", "Patience advances", "Trade and life require patience."),
            ("Ruwan sama ba ya zama a kasa", "Rain from above does not stay on the ground", "Blessings flow through people."),
            ("Mutum da mutumci", "A person and personhood", "Character defines humanity."),
            ("Tafiya ta gama gida", "The journey finishes at home", "Return and roots matter."),
        ],
        "scenarios": {
            "MarketBargaining": [
                ("Kano market cloth", "Sannu, uwar gida. Nawa ne wannan?", "Greet seller as mother", "Hospitality language softens trade."),
                ("Grain seller", "Abincin ku yafi kyau. Nawa ne kadan?", "Praise quality; ask small price", "Compliment before counter."),
                ("Leather goods", "Ina so wannan. Yi mini kadan.", "State want; ask reduction", "Firm but polite."),
            ],
            "GreetingDiplomacy": [
                ("Emirate visit", "Sannu da safe. Ina lafiya?", "Peace greeting + wellbeing", "Formal contexts use fuller greetings."),
                ("Guest arrival", "Barka da zuwa. Sunana…", "Welcome response + name", "Hosts offer tea before talk."),
                ("Elder respect", "Ina kwana, baba?", "Morning to elder", "Title baba shows respect."),
            ],
            "TaxiSurvival": [
                ("Moto park", "Ina ne mota ta tafi Kano?", "Where is the Kano vehicle?", "Shared taxis use routes."),
                ("Fare", "Nawa ne tafiya?", "How much is the trip?", "Settle before departure."),
                ("Stop", "Don Allah, tsaya nan.", "Please stop here", ""),
            ],
            "RoleplayAdventure": [
                ("Shop visit", "Sannu. Ina so wannan abu.", "Greeting + request", ""),
                ("Phone call", "Ina lafiya? Lafiya lau.", "Check-in exchange", ""),
            ],
            "EldersBlessings": [
                ("After meal", "Na gode, uwar gida.", "Thanks to host", "May receive baraka."),
                ("Friday greeting", "Barka da Juma'a.", "Friday blessing", "Religious-cultural overlap."),
            ],
            "CulturalEtiquette": [
                ("Right hand", "Don Allah, yi hankuri.", "Polite excuse", "Right hand for giving/receiving."),
                ("Tea offer", "Na gode, zan sha.", "Accept hospitality", "Refusing abruptly can seem rude."),
            ],
        },
        "units": [
            ("Trade greetings", "Sannu culture", [
                ("Peace hello", ["Sannu", "Ina lafiya?", "Lafiya lau"], "Basic exchange.", "Hausa spread through trade — greetings open deals."),
                ("Morning", ["Ina kwana?", "Barka da safe", "Na gode"], "Sleep and peace.", ""),
                ("Please & thanks", ["Don Allah", "Na gode", "Barka da zuwa"], "Courtesy.", ""),
            ]),
            ("Family", "Iyali", [
                ("Kin", ["Uwa", "Uba", "Iyali"], "Family words.", ""),
                ("Respect", ["Baba", "Mallam", "Yi hakuri"], "Titles.", ""),
                ("Home", ["Gida", "Barka da zuwa", "Sunana"], "Welcome pattern.", ""),
            ]),
            ("Market", "Kasuwanci", [
                ("Goods", ["Abinci", "Ruwa", "Kasance"], "Staples.", ""),
                ("Money", ["Kudi", "Nawa ne?", "Kadan"], "Price talk.", ""),
                ("Close", ["Dai-dai", "Na gode", "Sannu"], "Fair deal + exit.", ""),
            ]),
            ("Travel", "Tafiya", [
                ("Go", ["Mota", "Ina ne?", "Tafiya"], "Movement.", ""),
                ("Ask", ["Ina so", "Nawa ne?", "A hankuri"], "Slow speech.", ""),
                ("Learn", ["Ina jin Hausa", "Mai kyau", "Littafi"], "Learner phrase.", ""),
            ]),
            ("Proverbs", "Hikima", [
                ("Wisdom", ["Karatu, farkonka", "Hankuri ya ci gaba"], "Proverb culture.", ""),
                ("Community", ["Gida bai daya ba", "Mutum da mutumci"], "Social ethics.", ""),
                ("Review", ["Sannu", "Na gode", "Lafiya lau"], "Consolidate.", ""),
            ]),
        ],
    },
    "igbo": {
        "display": "Igbo",
        "words": [
            ("Ndewo", "Greetings", "greeting", "", "General greeting; context sets tone."),
            ("Kedu ka ị mere?", "How are you?", "greeting", "", ""),
            ("Daalụ", "Thank you", "expression", "", ""),
            ("Biko", "Please", "expression", "", ""),
            ("Aha m bụ", "My name is", "phrase", "", ""),
            ("E si m na", "I am from", "phrase", "", ""),
            ("Nne", "Mother", "noun", "", ""),
            ("Nna", "Father", "noun", "", ""),
            ("Ezinaụlọ", "Family", "noun", "", ""),
            ("Nri", "Food", "noun", "", ""),
            ("Mmiri", "Water", "noun", "", ""),
            ("Ego", "Money", "noun", "", ""),
            ("Ụlọ", "House", "noun", "", ""),
            ("Ụgbọala", "Vehicle", "noun", "", ""),
            ("Kedụ ebe…?", "Where is…?", "phrase", "", ""),
            ("Achọrọ m", "I want", "phrase", "", ""),
            ("Ego ole?", "How much?", "phrase", "", ""),
            ("Ọ dị mma", "It is good", "phrase", "", ""),
            ("Adị m mma", "I am fine", "phrase", "", ""),
            ("Nnọọ", "Welcome", "expression", "", ""),
            ("Nwayọọ", "Slowly", "adverb", "", ""),
            ("Ahịa", "Market", "noun", "", "Entrepreneurial communication hub."),
            ("Jee nke ọma", "Go well", "phrase", "", ""),
            ("Kedu", "What / how", "question", "", ""),
            ("Biko, belata", "Please reduce", "phrase", "", "Bargaining."),
            ("A na m akwụkọ Igbo", "I am learning Igbo", "phrase", "", ""),
            ("Ihe", "Thing", "noun", "", ""),
            ("Oku", "Call / meeting", "noun", "", "Community gathering."),
            ("Ifeoma", "Something good", "name/phrase", "", "Common praise name."),
            ("Nwoke", "Man", "noun", "", ""),
            ("Nwanyị", "Woman", "noun", "", ""),
            ("Nwanne", "Sibling / kin", "noun", "", "Extended family bond."),
            ("Iri ji", "Yam feast", "noun", "", "Cultural food event."),
        ],
        "proverbs": [
            ("Egbe bere, ugo bere", "Let the eagle perch, let the kite perch", "Make room for all — coexistence."),
            ("Onye wetara oji, wetara ndu", "Who brings kola brings life", "Hospitality sustains community."),
            ("Aku ruo uno, okwuo onye kpara ya", "When wealth reaches home, it speaks for its owner", "Success has social voice."),
            ("Igwe bu ike", "The multitude is strength", "Community power."),
            ("Otu onye tuo izu, o gbue ochu", "One person does not plan a meeting alone", "Collective decision-making."),
            ("Ebe onye bi, ka o na-awachi", "Where one lives, one defends", "Local identity."),
        ],
        "scenarios": {
            "MarketBargaining": [
                ("Onitsha market", "Ndewo. Ego ole ihe a?", "Greet; ask price", ""),
                ("Fabric", "Ihe a dị mma. Belata ego biko.", "Praise; ask reduction", ""),
                ("Provisions", "Achọrọ m nri abụọ.", "Buy two items", ""),
            ],
            "GreetingDiplomacy": [
                ("Elder", "Ndewo, nna. Kedu ka ị mere?", "Father + wellbeing", ""),
                ("Home", "Nnọọ. Aha m bụ…", "Welcome + name", ""),
                ("Community", "Ndewo, umunna.", "Greet kindred", ""),
            ],
            "TaxiSurvival": [
                ("Park", "Kedụ ebe ụgbọala na-aga Enugu?", "Where is Enugu vehicle?", ""),
                ("Fare", "Ego ole ị ga-ana?", "What will you charge?", ""),
                ("Stop", "Biko, kwụsị ebe a.", "Stop here", ""),
            ],
            "RoleplayAdventure": [
                ("Family call", "Kedu? Adị m mma.", "Quick check-in", ""),
                ("Shop", "Achọrọ m ihe a.", "I want this", ""),
            ],
            "EldersBlessings": [
                ("Kola rite", "Daalụ, nne.", "Thanks to mother", "Kola is sacred hospitality."),
                ("Title greeting", "Ndewo, Igwe.", "Greet titled elder", ""),
            ],
            "CulturalEtiquette": [
                ("Two hands", "Daalụ nke ukwuu.", "Deep thanks", ""),
                ("Meeting", "Biko, nwee ndidi.", "Please be patient", ""),
            ],
        },
        "units": [
            ("Ndewo world", "First words", [
                ("Hello", ["Ndewo", "Kedu ka ị mere?", "Adị m mma"], "", "Igbo conversation starts warm."),
                ("Thanks", ["Daalụ", "Biko", "Nnọọ"], "", ""),
                ("Name", ["Aha m bụ", "E si m na", "A na m akwụkọ Igbo"], "", ""),
            ]),
            ("Ezinaụlọ", "Family", [
                ("Kin", ["Nne", "Nna", "Ezinaụlọ"], "", ""),
                ("Relations", ["Nwanne", "Nwoke", "Nwanyị"], "", ""),
                ("Respect", ["Nna", "Biko", "Nwayọọ"], "", ""),
            ]),
            ("Ahịa", "Market", [
                ("Buy", ["Nri", "Mmiri", "Ahịa"], "", ""),
                ("Price", ["Ego ole?", "Achọrọ m", "Belata"], "", ""),
                ("Praise", ["Ọ dị mma", "Daalụ", "Jee nke ọma"], "", ""),
            ]),
            ("Movement", "Travel", [
                ("Go", ["Ụgbọala", "Kedụ ebe", "Ụlọ"], "", ""),
                ("Fare", ["Ego ole?", "Biko", "Nwayọọ"], "", ""),
                ("Review", ["Ndewo", "Adị m mma", "Daalụ"], "", ""),
            ]),
            ("Iro", "Proverbs", [
                ("Wisdom", ["Egbe bere, ugo bere", "Onye wetara oji, wetara ndu"], "", ""),
                ("Community", ["Igwe bu ike", "Otu onye tuo izu, o gbue ochu"], "", ""),
                ("Close", ["Iri ji", "Ifeoma", "Ọ dị mma"], "", ""),
            ]),
        ],
    },
    "swahili": {
        "display": "Swahili",
        "words": [
            ("Habari", "News / how are things", "greeting", "", "Coastal East African default."),
            ("Hujambo", "Hello (to one person)", "greeting", "", ""),
            ("Shikamoo", "Respectful hello (to elder)", "greeting", "", "Response: Marahaba."),
            ("Marahaba", "I hold you in respect", "greeting", "", "Answer to Shikamoo."),
            ("Asante", "Thank you", "expression", "", ""),
            ("Tafadhali", "Please", "expression", "", ""),
            ("Jina langu ni", "My name is", "phrase", "", ""),
            ("Ninatoka", "I come from", "phrase", "", ""),
            ("Mama", "Mother", "noun", "", ""),
            ("Baba", "Father", "noun", "", ""),
            ("Familia", "Family", "noun", "", ""),
            ("Chakula", "Food", "noun", "", ""),
            ("Maji", "Water", "noun", "", ""),
            ("Pesa", "Money", "noun", "", ""),
            ("Nyumba", "House", "noun", "", ""),
            ("Gari", "Car", "noun", "", ""),
            ("Wapi…?", "Where is…?", "phrase", "", ""),
            ("Nataka", "I want", "phrase", "", ""),
            ("Bei gani?", "What price?", "phrase", "", ""),
            ("Nzuri", "Good", "adjective", "", ""),
            ("Nzuri sana", "Very good", "phrase", "", ""),
            ("Karibu", "Welcome / come close", "expression", "", "Hospitality core."),
            ("Pole pole", "Slowly", "adverb", "", "Iconic learning phrase."),
            ("Soko", "Market", "noun", "", ""),
            ("Safari", "Journey", "noun", "", ""),
            ("Hakuna matata", "No worries", "phrase", "", "Popular but real usage varies."),
            ("Ninajifunza Kiswahili", "I am learning Swahili", "phrase", "", ""),
            ("Samahani", "Sorry / excuse me", "phrase", "", ""),
            ("Ndio", "Yes", "particle", "", ""),
            ("Hapana", "No", "particle", "", ""),
            ("Lala salama", "Sleep peacefully", "phrase", "", "Night farewell."),
            ("Mambo", "Things / what's up", "greeting", "", "Casual youth speech."),
            ("Vipi", "How", "question", "", "Street casual."),
        ],
        "proverbs": [
            ("Haraka haraka haina baraka", "Hurry hurry has no blessing", "Patience brings quality."),
            ("Mgeni ni kuku mweupe", "A guest is a white chicken", "Honour guests."),
            ("Samaki mkunje angali mbichi", "Bend a fish while still fresh", "Teach early."),
            ("Penye nia pana njia", "Where there is will, there is a way", ""),
            ("Umoja ni nguvu", "Unity is strength", "Pan-African resonance."),
            ("Elimu ni taa", "Education is a lamp", ""),
        ],
        "scenarios": {
            "MarketBargaining": [
                ("Zanzibar spice", "Habari. Bei gani hii?", "Habari first", ""),
                ("Dar es Salaam", "Nzuri sana. Punguza kidogo.", "Praise; small reduction", ""),
                ("Fish market", "Nataka samaki mbili.", "Buy two fish", ""),
            ],
            "GreetingDiplomacy": [
                ("Elder", "Shikamoo, baba.", "Respect greeting", ""),
                ("Home", "Karibu nyumbani.", "Welcome home", ""),
                ("Hotel", "Habari za asubuhi.", "Morning news greeting", ""),
            ],
            "TaxiSurvival": [
                ("Daladala", "Gari la kwenda wapi?", "Which vehicle goes where?", ""),
                ("Fare", "Bei gani hadi town?", "Price to town?", ""),
                ("Stop", "Tafadhali, simama hapa.", "Stop here", ""),
            ],
            "RoleplayAdventure": [
                ("Beach vendor", "Karibu. Unataka nini?", "Welcome + offer", ""),
                ("Friend", "Mambo vipi?", "Casual opener", ""),
            ],
            "EldersBlessings": [
                ("Visit", "Shikamoo. Marahaba.", "Full respect exchange", ""),
                ("Thanks", "Asante sana, mama.", "Deep thanks", ""),
            ],
            "CulturalEtiquette": [
                ("Hospitality", "Karibu kula.", "Welcome to eat", ""),
                ("Patience", "Pole pole, tafadhali.", "Slow down please", ""),
            ],
        },
        "units": [
            ("Karibu", "Coastal hello", [
                ("Basic", ["Habari", "Hujambo", "Nzuri"], "", "Swahili connects nations."),
                ("Respect", ["Shikamoo", "Marahaba", "Asante"], "", ""),
                ("Please", ["Tafadhali", "Karibu", "Samahani"], "", ""),
            ]),
            ("Familia", "Family", [
                ("Kin", ["Mama", "Baba", "Familia"], "", ""),
                ("Learn", ["Jina langu ni", "Ninatoka", "Ninajifunza Kiswahili"], "", ""),
                ("Casual", ["Mambo", "Vipi", "Pole pole"], "", ""),
            ]),
            ("Soko", "Market", [
                ("Food", ["Chakula", "Maji", "Soko"], "", ""),
                ("Price", ["Bei gani?", "Nataka", "Pesa"], "", ""),
                ("Deal", ["Nzuri sana", "Asante", "Kwaheri"], "", ""),
            ]),
            ("Safari", "Journey", [
                ("Go", ["Gari", "Wapi", "Safari"], "", ""),
                ("Travel", ["Bei gani?", "Simama hapa", "Pole pole"], "", ""),
                ("Night", ["Lala salama", "Habari", "Nzuri"], "", ""),
            ]),
            ("Methali", "Proverbs", [
                ("Wisdom", ["Haraka haraka haina baraka", "Elimu ni taa"], "", ""),
                ("Unity", ["Umoja ni nguvu", "Penye nia pana njia"], "", ""),
                ("Guest", ["Mgeni ni kuku mweupe", "Karibu"], "", ""),
            ]),
        ],
    },
    "zulu": {
        "display": "Zulu",
        "words": [
            ("Sawubona", "Hello (to many / respect)", "greeting", "", "Literally 'we see you'."),
            ("Unjani?", "How are you?", "greeting", "", ""),
            ("Ngiyabonga", "Thank you", "expression", "", ""),
            ("Ngicela", "Please", "expression", "", ""),
            ("Igama lami ngingu", "My name is", "phrase", "", ""),
            ("Ngivela e", "I come from", "phrase", "", ""),
            ("Umama", "Mother", "noun", "", ""),
            ("Ubaba", "Father", "noun", "", ""),
            ("Umndeni", "Family", "noun", "", ""),
            ("Ukudla", "Food", "noun", "", ""),
            ("Amanzi", "Water", "noun", "", ""),
            ("Imali", "Money", "noun", "", ""),
            ("Ikhaya", "Home", "noun", "", ""),
            ("Imoto", "Car", "noun", "", ""),
            ("Kuphi…?", "Where is…?", "phrase", "", ""),
            ("Ngifuna", "I want", "phrase", "", ""),
            ("Malini?", "How much?", "phrase", "", ""),
            ("Kuhle", "It is good", "phrase", "", ""),
            ("Ngiyaphila", "I am well", "phrase", "", ""),
            ("Wamukelekile", "Welcome", "expression", "", ""),
            ("Kancane kancane", "Slowly", "adverb", "", ""),
            ("Imakethe", "Market", "noun", "", ""),
            ("Sawubona baba", "Hello father", "phrase", "", "Respect form."),
            ("Yebo", "Yes", "particle", "", ""),
            ("Cha", "No", "particle", "", ""),
            ("Uxolo", "Sorry", "expression", "", ""),
            ("Ngiyafunda isiZulu", "I am learning Zulu", "phrase", "", ""),
            ("Indaba", "Story / matter", "noun", "", "Praise poetry tradition."),
            ("Sawubona mageza", "Hello with clicks", "phrase", "Click consonants in mageza", "Clicks need repetition — mastery comes with practice."),
            ("Hamba kahle", "Go well", "phrase", "", ""),
            ("Sala kahle", "Stay well", "phrase", "", ""),
            ("Baba", "Father / sir", "noun", "", ""),
            ("Gogo", "Grandmother", "noun", "", "Respect elder."),
        ],
        "proverbs": [
            ("Umuntu ngumuntu ngabantu", "A person is a person through people", "Ubuntu philosophy."),
            ("Isandla sihlaba esinye", "One hand washes the other", "Cooperation."),
            ("Indlela ibuzwa kwabaphambili", "The road is asked from those ahead", "Seek elder guidance."),
            ("Akulahlwa mbuzi ngakuphi", "A goat is not slaughtered in any way", "Respect custom."),
            ("Inkunzi ayitholakali", "The bull is not easily found", "Patience for excellence."),
            ("Izandla ziyagezana", "Hands wash each other", "Mutual support."),
        ],
        "scenarios": {
            "MarketBargaining": [
                ("Durban market", "Sawubona. Malini lokhu?", "", ""),
                ("Praise", "Kuhle kakhulu. Nciphisa kancane.", "", ""),
                ("Buy", "Ngifuna lokhu.", "", ""),
            ],
            "GreetingDiplomacy": [
                ("Elder", "Sawubona baba. Unjani?", "", ""),
                ("Home", "Wamukelekile ekhaya.", "", ""),
                ("Group", "Sawubona nonke.", "", ""),
            ],
            "TaxiSurvival": [
                ("Taxi rank", "Kuphi itekisi eya eThekwini?", "", ""),
                ("Fare", "Malini uhambo?", "", ""),
                ("Stop", "Ngicela, yima lapha.", "", ""),
            ],
            "RoleplayAdventure": [
                ("Friend", "Unjani? Ngiyaphila.", "", ""),
                ("Shop", "Ngifuna lokhu.", "", ""),
            ],
            "EldersBlessings": [
                ("Gogo", "Sawubona gogo. Ngiyabonga.", "", ""),
                ("Blessing", "Sala kahle, baba.", "", ""),
            ],
            "CulturalEtiquette": [
                ("Sorry", "Uxolo, ngicela.", "", ""),
                ("Thanks", "Ngiyabonga kakhulu.", "", ""),
            ],
        },
        "units": [
            ("Sawubona", "Hello & clicks", [
                ("Greet", ["Sawubona", "Unjani?", "Ngiyaphila"], "", "Clicks are new — repetition builds mastery."),
                ("Thanks", ["Ngiyabonga", "Ngicela", "Wamukelekile"], "", ""),
                ("Learn", ["Ngiyafunda isiZulu", "Kancane kancane", "Yebo"], "", ""),
            ]),
            ("Umndeni", "Family", [
                ("Kin", ["Umama", "Ubaba", "Umndeni"], "", ""),
                ("Elders", ["Gogo", "Baba", "Sawubona baba"], "", ""),
                ("Home", ["Ikhaya", "Hamba kahle", "Igama lami ngingu"], "", ""),
            ]),
            ("Imakethe", "Market", [
                ("Buy", ["Ukudla", "Amanzi", "Imakethe"], "", ""),
                ("Price", ["Malini?", "Ngifuna", "Imali"], "", ""),
                ("Exit", ["Ngiyabonga", "Sawubona", "Hamba kahle"], "", ""),
            ]),
            ("Uhambo", "Journey", [
                ("Go", ["Imoto", "Kuphi", "Ikhaya"], "", ""),
                ("Fare", ["Malini?", "Ngicela", "Kancane kancane"], "", ""),
                ("Story", ["Indaba", "Kuhle", "Ngiyaphila"], "", ""),
            ]),
            ("Izaga", "Proverbs", [
                ("Ubuntu", ["Umuntu ngumuntu ngabantu", "Isandla sihlaba esinye"], "", ""),
                ("Guidance", ["Indlela ibuzwa kwabaphambili", "Izandla ziyagezana"], "", ""),
                ("Close", ["Sala kahle", "Ngiyabonga", "Sawubona"], "", ""),
            ]),
        ],
    },
    "xhosa": {
        "display": "Xhosa",
        "words": [
            ("Molo", "Hello", "greeting", "", ""),
            ("Unjani?", "How are you?", "greeting", "", ""),
            ("Enkosi", "Thank you", "expression", "", ""),
            ("Ndiyacela", "Please", "expression", "", ""),
            ("Igama lam ngu", "My name is", "phrase", "", ""),
            ("Ndivela e", "I come from", "phrase", "", ""),
            ("Umama", "Mother", "noun", "", ""),
            ("Utata", "Father", "noun", "", ""),
            ("Usapho", "Family", "noun", "", ""),
            ("Ukutya", "Food", "noun", "", ""),
            ("Amanzi", "Water", "noun", "", ""),
            ("Imali", "Money", "noun", "", ""),
            ("Ikhaya", "Home", "noun", "", ""),
            ("Imoto", "Car", "noun", "", ""),
            ("Phi…?", "Where", "question", "", ""),
            ("Ndifuna", "I want", "phrase", "", ""),
            ("Ixabisa malini?", "How much?", "phrase", "", ""),
            ("Kulungile", "It is fine", "phrase", "", ""),
            ("Ndiphilile", "I am well", "phrase", "", ""),
            ("Wamkelekile", "Welcome", "expression", "", ""),
            ("Kancinci", "A little / slowly", "adverb", "", ""),
            ("Imarike", "Market", "noun", "", ""),
            ("Ewe", "Yes", "particle", "", ""),
            ("Hayi", "No", "particle", "", ""),
            ("Uxolo", "Sorry", "expression", "", ""),
            ("Ndiyafunda isiXhosa", "I am learning Xhosa", "phrase", "", ""),
            ("Molweni", "Hello (plural/respect)", "greeting", "", ""),
            ("Tata", "Father / sir", "noun", "", ""),
            ("Makhulu", "Grandmother", "noun", "", ""),
            ("Hamba kakuhle", "Go well", "phrase", "", ""),
            ("Sala kakuhle", "Stay well", "phrase", "", ""),
            ("Click practice: wcwecwe", "Practice click word", "phrase", "Clicks in xc/xh", "These sounds are new — mastery comes through repetition."),
        ],
        "proverbs": [
            ("Ubuntu ngumtu ngabanye abantu", "Ubuntu — humanity through others", ""),
            ("Isiqhelo siyatywala", "Habit carries you", ""),
            ("Umntu ngumntu ngabantu", "A person through people", ""),
            ("Akuko mpukane inqakule enye", "No flea jumps alone", "Community."),
            ("Intaka yakha ngoboya bayo", "A bird builds with its feathers", "Self-reliance within community."),
            ("Uxolo lweendo", "Peace of journey", ""),
        ],
        "scenarios": {
            "MarketBargaining": [
                ("Market", "Molo. Ixabisa malini?", "", ""),
                ("Praise", "Kulungile. Nciphisa nceda.", "", ""),
                ("Buy", "Ndifuna oku.", "", ""),
            ],
            "GreetingDiplomacy": [
                ("Elder", "Molo tata. Unjani?", "", ""),
                ("Home", "Wamkelekile ekhaya.", "", ""),
                ("Group", "Molweni nonke.", "", ""),
            ],
            "TaxiSurvival": [
                ("Rank", "Phi itekisi eya eMonti?", "", ""),
                ("Fare", "Ixabisa malini uhambo?", "", ""),
                ("Stop", "Ndiyacela, yima apha.", "", ""),
            ],
            "RoleplayAdventure": [
                ("Friend", "Unjani? Ndiphilile.", "", ""),
                ("Shop", "Ndifuna oku.", "", ""),
            ],
            "EldersBlessings": [
                ("Gogo", "Molo makhulu. Enkosi.", "", ""),
                ("Leave", "Sala kakuhle, tata.", "", ""),
            ],
            "CulturalEtiquette": [
                ("Sorry", "Uxolo, ndiyacela.", "", ""),
                ("Thanks", "Enkosi kakhulu.", "", ""),
            ],
        },
        "units": [
            ("Molo", "Start", [
                ("Hi", ["Molo", "Unjani?", "Ndiphilile"], "", ""),
                ("Polite", ["Molweni", "Enkosi", "Ndiyacela"], "", ""),
                ("Learn", ["Ndiyafunda isiXhosa", "Kancinci", "Ewe"], "", ""),
            ]),
            ("Usapho", "Family", [
                ("Kin", ["Umama", "Utata", "Usapho"], "", ""),
                ("Elders", ["Makhulu", "Tata", "Molo tata"], "", ""),
                ("Home", ["Ikhaya", "Wamkelekile", "Igama lam ngu"], "", ""),
            ]),
            ("Imarike", "Market", [
                ("Food", ["Ukutya", "Amanzi", "Imarike"], "", ""),
                ("Price", ["Ixabisa malini?", "Ndifuna", "Imali"], "", ""),
                ("Deal", ["Kulungile", "Enkosi", "Hamba kakuhle"], "", ""),
            ]),
            ("Uhambo", "Travel", [
                ("Go", ["Imoto", "Phi", "Ikhaya"], "", ""),
                ("Fare", ["Ixabisa malini?", "Ndiyacela", "Kancinci"], "", ""),
                ("Clicks", ["Click practice: wcwecwe", "Molo", "Ndiphilile"], "", "Speak boldly before perfection."),
            ]),
            ("Izaci", "Wisdom", [
                ("Ubuntu", ["Ubuntu ngumtu ngabanye abantu", "Umntu ngumntu ngabantu"], "", ""),
                ("Habit", ["Isiqhelo siyatywala", "Intaka yakha ngoboya bayo"], "", ""),
                ("Close", ["Sala kakuhle", "Enkosi", "Molo"], "", ""),
            ]),
        ],
    },
    "wolof": {
        "display": "Wolof",
        "words": [
            ("Nanga def", "How are you", "greeting", "", "Teranga culture — warmth first."),
            ("Asalaam aleikum", "Peace greeting", "greeting", "", "Common in Senegal."),
            ("Jërëjëf", "Thank you", "expression", "", ""),
            ("Baal ma", "Please / excuse me", "expression", "", ""),
            ("Tudd mi", "My name is", "phrase", "", ""),
            ("Maa ngi fi", "I am here / I come from", "phrase", "", ""),
            ("Yaay", "Mother", "noun", "", ""),
            ("Baay", "Father", "noun", "", ""),
            ("Waa kër", "Family / household", "noun", "", ""),
            ("Lekk", "Eat / food", "verb/noun", "", ""),
            ("Ndox", "Water", "noun", "", ""),
            ("Xaalis", "Money", "noun", "", ""),
            ("Kër", "House", "noun", "", ""),
            ("Oto", "Car", "noun", "", ""),
            ("Ana…?", "Where is…?", "phrase", "", ""),
            ("Dama bëgg", "I want", "phrase", "", ""),
            ("Ñaata la?", "How much?", "phrase", "", ""),
            ("Baax na", "It is good", "phrase", "", ""),
            ("Mangi fi rekk", "I am fine", "phrase", "", ""),
            ("Dalal ak jamm", "Welcome in peace", "expression", "", ""),
            ("Yomb yomb", "Slowly", "adverb", "", ""),
            ("Marche", "Market", "noun", "", "French-Wolof bilingual context."),
            ("Teranga", "Hospitality", "noun", "", "Core Senegalese value."),
            ("Waaw", "Yes", "particle", "", ""),
            ("Déedéet", "No", "particle", "", ""),
            ("Baal ma ci", "Sorry", "phrase", "", ""),
            ("Dama jàng Wolof", "I am learning Wolof", "phrase", "", ""),
            ("Xale", "Child", "noun", "", ""),
            ("Goor", "Man", "noun", "", ""),
            ("Jigéen", "Woman", "noun", "", ""),
            ("Chai", "Tea", "noun", "", "Hospitality ritual."),
            ("Attaya", "Tea ceremony", "noun", "", ""),
        ],
        "proverbs": [
            ("Ku amul ndox, amul dund", "Who has no water has no life", ""),
            ("Gëm gi mooy jàngale", "Faith teaches", ""),
            ("Kër gi mooy làkk gi", "The home is the language", ""),
            ("Yokkute dafa am solo", "Unity has meaning", ""),
            ("Ndox mi doy na", "Water is enough", "Contentment."),
            ("Teranga mooy sunu gis-gis", "Hospitality is our face", ""),
        ],
        "scenarios": {
            "MarketBargaining": [
                ("Sandaga", "Nanga def. Ñaata la?", "", "Teranga before price."),
                ("Fabric", "Baax na. Wàññil ma.", "Good — reduce for me", ""),
                ("Fish", "Dama bëgg genn gi.", "Want fish", ""),
            ],
            "GreetingDiplomacy": [
                ("Elder", "Asalaam aleikum, baay.", "", ""),
                ("Home", "Dalal ak jamm.", "", ""),
                ("Tea", "Attaya ngii. Jërëjëf.", "Tea offered — thanks", ""),
            ],
            "TaxiSurvival": [
                ("Car rapide", "Ana oto bi di dem?", "", ""),
                ("Fare", "Ñaata la dem?", "", ""),
                ("Stop", "Baal ma, taxaw fii.", "", ""),
            ],
            "RoleplayAdventure": [
                ("Friend", "Nanga def? Mangi fi rekk.", "", ""),
                ("Shop", "Dama bëgg lii.", "", ""),
            ],
            "EldersBlessings": [
                ("Mother", "Jërëjëf, yaay.", "", ""),
                ("Leave", "Ba beneen yoon, baay.", "Until next time", ""),
            ],
            "CulturalEtiquette": [
                ("Tea", "Jërëjëf, dinaa ata.", "Thanks, I will drink", ""),
                ("Respect", "Teranga la.", "It is hospitality", ""),
            ],
        },
        "units": [
            ("Teranga", "Welcome", [
                ("Hi", ["Nanga def", "Mangi fi rekk", "Baax na"], "", "Wolof warmth is the lesson."),
                ("Thanks", ["Jërëjëf", "Baal ma", "Dalal ak jamm"], "", ""),
                ("Learn", ["Dama jàng Wolof", "Yomb yomb", "Waaw"], "", ""),
            ]),
            ("Waa kër", "Family", [
                ("Kin", ["Yaay", "Baay", "Waa kër"], "", ""),
                ("People", ["Goor", "Jigéen", "Xale"], "", ""),
                ("Tea", ["Chai", "Attaya", "Jërëjëf"], "", ""),
            ]),
            ("Marche", "Market", [
                ("Buy", ["Lekk", "Ndox", "Marche"], "", ""),
                ("Price", ["Ñaata la?", "Dama bëgg", "Xaalis"], "", ""),
                ("Deal", ["Baax na", "Jërëjëf", "Waaw"], "", ""),
            ]),
            ("Dem", "Go", [
                ("Move", ["Oto", "Ana", "Kër"], "", ""),
                ("Fare", ["Ñaata la?", "Baal ma", "Yomb yomb"], "", ""),
                ("Music", ["Teranga", "Nanga def", "Baax na"], "", "Music and radio build listening."),
            ]),
            ("Màggal", "Wisdom", [
                ("Proverbs", ["Teranga mooy sunu gis-gis", "Kër gi mooy làkk gi"], "", ""),
                ("Life", ["Ku amul ndox, amul dund", "Yokkute dafa am solo"], "", ""),
                ("Close", ["Dalal ak jamm", "Jërëjëf", "Nanga def"], "", ""),
            ]),
        ],
    },
    "pidgin": {
        "display": "Nigerian Pidgin",
        "words": [
            ("How far?", "How are you / what's up", "greeting", "", "Legitimate identity language — not 'broken English'."),
            ("How you dey?", "How are you?", "greeting", "", ""),
            ("I dey fine", "I am fine", "phrase", "", ""),
            ("Thank you", "Thank you", "expression", "", ""),
            ("Abeg", "Please", "expression", "", ""),
            ("My name na", "My name is", "phrase", "", ""),
            ("I come from", "I come from", "phrase", "", ""),
            ("Mama", "Mother", "noun", "", ""),
            ("Papa", "Father", "noun", "", ""),
            ("Family", "Family", "noun", "", ""),
            ("Chop", "Food / eat", "noun/verb", "", ""),
            ("Water", "Water", "noun", "", ""),
            ("Money", "Money", "noun", "", ""),
            ("House", "House", "noun", "", ""),
            ("Motor", "Car", "noun", "", ""),
            ("Where… dey?", "Where is…?", "phrase", "", ""),
            ("I want", "I want", "phrase", "", ""),
            ("How much?", "How much?", "phrase", "", ""),
            ("E good", "It is good", "phrase", "", ""),
            ("You welcome", "You are welcome", "expression", "", ""),
            ("Slow slow", "Slowly", "adverb", "", ""),
            ("Market", "Market", "noun", "", ""),
            ("Na so", "That's how it is", "phrase", "", ""),
            ("No wahala", "No problem", "phrase", "", ""),
            ("I dey learn Pidgin", "I am learning Pidgin", "phrase", "", ""),
            ("Wetin dey happen?", "What is happening?", "phrase", "", ""),
            ("Make we go", "Let's go", "phrase", "", ""),
            ("I no sabi", "I don't know", "phrase", "", ""),
            ("You sabi?", "Do you understand?", "phrase", "", ""),
            ("Gist", "Chat / story", "noun", "", ""),
            ("Wahala", "Trouble", "noun", "", ""),
            ("Sharp sharp", "Quickly", "adverb", "", ""),
            ("E be like film", "It's dramatic / unbelievable", "phrase", "", "Pop culture speech."),
        ],
        "proverbs": [
            ("Who no know, go know", "Who doesn't know will know", "Experience teaches."),
            ("Na condition make crayfish bend", "Condition makes crayfish bend", "Context shapes behaviour."),
            ("Monkey smart, monkey smart", "Wisdom in street smarts", "Humour carries truth."),
            ("Today soup, tomorrow soup", "Take today as it comes", ""),
            ("No be today", "Not today / patience", ""),
            ("Body no be firewood", "The body is not firewood", "Rest matters."),
        ],
        "scenarios": {
            "MarketBargaining": [
                ("Lagos market", "How far? How much this one?", "", ""),
                ("Banter", "Oga, e too cost. Reduce am abeg.", "", "Humour opens negotiation."),
                ("Buy", "I want two.", "", ""),
            ],
            "GreetingDiplomacy": [
                ("Street", "How you dey? I dey fine.", "", ""),
                ("Home", "You welcome. My name na…", "", ""),
                ("Elder", "Good afternoon, ma. How far?", "", ""),
            ],
            "TaxiSurvival": [
                ("Keke", "Where motor dey go VI?", "", ""),
                ("Fare", "How much go reach?", "", ""),
                ("Stop", "Abeg, stop here.", "", ""),
            ],
            "RoleplayAdventure": [
                ("Friend gist", "Wetin dey happen? No wahala.", "", ""),
                ("Shop", "I want this one.", "", ""),
            ],
            "EldersBlessings": [
                ("Thanks", "Thank you, ma.", "", ""),
                ("Leave", "Make we dey go. Thank you.", "", ""),
            ],
            "CulturalEtiquette": [
                ("Humour", "No wahala, we dey together.", "", ""),
                ("Respect", "Abeg, slow slow.", "", ""),
            ],
        },
        "units": [
            ("How far", "Street hello", [
                ("Greet", ["How far?", "How you dey?", "I dey fine"], "", "Pidgin connects Nigeria."),
                ("Please", ["Abeg", "Thank you", "You welcome"], "", ""),
                ("Learn", ["I dey learn Pidgin", "You sabi?", "No wahala"], "", ""),
            ]),
            ("Family", "Home", [
                ("Kin", ["Mama", "Papa", "Family"], "", ""),
                ("Talk", ["Gist", "Wetin dey happen?", "Make we go"], "", ""),
                ("Pop", ["Na so", "E be like film", "Sharp sharp"], "", ""),
            ]),
            ("Market", "Buy & sell", [
                ("Food", ["Chop", "Water", "Market"], "", ""),
                ("Price", ["How much?", "I want", "Money"], "", ""),
                ("Deal", ["E good", "Thank you", "No wahala"], "", ""),
            ]),
            ("Motor", "Move", [
                ("Go", ["Motor", "Where… dey?", "House"], "", ""),
                ("Fare", ["How much?", "Abeg", "Slow slow"], "", ""),
                ("Exit", ["Make we go", "Thank you", "How far?"], "", ""),
            ]),
            ("Street wisdom", "Proverbs", [
                ("Life", ["Na condition make crayfish bend", "Body no be firewood"], "", ""),
                ("Humour", ["Monkey smart, monkey smart", "Who no know, go know"], "", ""),
                ("Close", ["No wahala", "I dey fine", "You welcome"], "", ""),
            ]),
        ],
    },
}

from .a2_b1_units import A2_UNITS, B1_UNITS  # noqa: E402
from .b2_c1_units import (  # noqa: E402
    B2_UNITS,
    C1_UNITS,
    C2_UNITS,
    EXTENDED_A2_UNITS,
    EXTENDED_B1_UNITS,
)
from .extended_language_packs import EXTENDED_LANG_PACKS  # noqa: E402
from .native_review import apply_native_review, NATIVE_REVIEW_META  # noqa: E402

LANG_PACKS.update(EXTENDED_LANG_PACKS)

_A2_ALL = {**A2_UNITS, **EXTENDED_A2_UNITS}
_B1_ALL = {**B1_UNITS, **EXTENDED_B1_UNITS}

for _lang in CURRICULUM_LANGUAGES:
    if _lang not in LANG_PACKS:
        continue
    LANG_PACKS[_lang]["units_a2"] = _A2_ALL.get(_lang, [])
    LANG_PACKS[_lang]["units_b1"] = _B1_ALL.get(_lang, [])
    LANG_PACKS[_lang]["units_b2"] = B2_UNITS.get(_lang, [])
    LANG_PACKS[_lang]["units_c1"] = C1_UNITS.get(_lang, [])
    LANG_PACKS[_lang]["units_c2"] = C2_UNITS.get(_lang, [])

LANG_PACKS = apply_native_review(LANG_PACKS)

from .game_vocab_expansion import augment_curriculum_units, merge_expansion_words  # noqa: E402

for _lang in CURRICULUM_LANGUAGES:
    _pack = LANG_PACKS.get(_lang)
    if not _pack:
        continue
    # Two passes: first harvests cross-level pool; second tops up thin levels.
    augment_curriculum_units(_pack)
    augment_curriculum_units(_pack)


def _word_entry(lang_key: str, idx: int, pack: dict, row: tuple) -> dict:
    text, gloss, pos, tonal, cultural = row[:5]
    display = pack["display"]
    tags = list(_COMMON_TAGS)
    if "greeting" in pos or "Greeting" in gloss:
        tags.append("GreetingDiplomacy")
    if pos in ("noun",) and ("food" in gloss.lower() or "market" in text.lower()):
        tags.append("FoodQuest")
    cefr = row[5] if len(row) > 5 and row[5] in ("A1", "A2", "B1", "B2", "C1", "C2") else "A1"
    return {
        "id": idx,
        "language": lang_key,
        "word": text,
        "english_meaning": gloss,
        "phonetic_guide": tonal or None,
        "part_of_speech": pos,
        "cefr": cefr,
        "topic": gloss.split("/")[0].strip()[:40] if gloss else "General",
        "tonal_note": tonal or None,
        "cultural_note": cultural or None,
        "game_tags": tags,
    }


def _phrase_card_entry(lang_key: str, idx: int, pack: dict, row: tuple) -> dict:
    text, gloss, pos, tonal, cultural = row
    display = pack["display"]
    return {
        "id": str(idx),
        "language": display,
        "text": text,
        "gloss": gloss,
        "ascii": tonal or text,
        "part_of_speech": pos,
        "cefr": "A1",
        "topic": (gloss.split("/")[0].strip()[:40] if gloss else "General"),
        "tonal_note": tonal or "",
        "cultural_note": cultural or "",
        "game_tags": _COMMON_TAGS[:8],
    }


def build_game_content() -> dict:
    from .polie_game_content import (  # noqa: E402
        build_grammar_drills,
        build_liar_liar_rounds,
        extend_scenarios,
    )

    words: list[dict] = []
    proverbs: list[dict] = []
    scenarios: list[dict] = []
    wid = 1
    pid = 1
    sid = 1
    for lang_key in CURRICULUM_LANGUAGES:
        pack = LANG_PACKS.get(lang_key)
        if not pack:
            continue
        for row in merge_expansion_words(pack):
            words.append(_word_entry(lang_key, wid, pack, row))
            wid += 1
        for orig, trans, meaning in pack["proverbs"]:
            proverbs.append({
                "id": pid,
                "language": lang_key,
                "original": orig,
                "translation": trans,
                "meaning": meaning,
                "cefr": "A1",
                "game_tags": ["ProverbUnlocker", "StoryBuilder", "CulturalEtiquette"],
            })
            pid += 1
        for game, items in pack["scenarios"].items():
            for title, prompt, expected, note in items:
                scenarios.append({
                    "id": sid,
                    "game": game,
                    "language": lang_key,
                    "cefr": "A1",
                    "title": title,
                    "prompt": prompt,
                    "expected_response": expected,
                    "cultural_note": note,
                })
                sid += 1
        # Extra scenario archetypes used by Polie-driven cultural games
        food = pack["words"][10] if len(pack["words"]) > 10 else pack["words"][0]
        scenarios.append({
            "id": sid,
            "game": "FoodQuest",
            "language": lang_key,
            "cefr": "A1",
            "title": f"Order {food[0]}",
            "prompt": food[0],
            "expected_response": food[1],
            "cultural_note": food[4] if len(food) > 4 else "",
        })
        sid += 1
        greet_sc = pack["scenarios"].get("GreetingDiplomacy", [])
        if greet_sc:
            scenarios.append({
                "id": sid,
                "game": "VillageQuest",
                "language": lang_key,
                "cefr": "A1",
                "title": "Community greeting",
                "prompt": greet_sc[0][1],
                "expected_response": greet_sc[0][2],
                "cultural_note": greet_sc[0][3],
            })
            sid += 1
        prov = pack["proverbs"][0]
        scenarios.append({
            "id": sid,
            "game": "FolktaleReconstruction",
            "language": lang_key,
            "cefr": "A1",
            "title": "Proverb story",
            "prompt": prov[0],
            "expected_response": prov[1],
            "cultural_note": prov[2],
        })
        sid += 1
    scenarios, sid = extend_scenarios(scenarios, CURRICULUM_LANGUAGES, sid)
    grammar_drills = build_grammar_drills(CURRICULUM_LANGUAGES)
    liar_liar_rounds = build_liar_liar_rounds(CURRICULUM_LANGUAGES)
    return {
        "meta": {
            "version": "4.0.0",
            "languages": CURRICULUM_LANGUAGES,
            "description": "LingAfriq authentic game content — expanded vocab pool for 37 games",
            "min_words_per_language": 80,
            "native_review": NATIVE_REVIEW_META,
        },
        "words": words,
        "proverbs": proverbs,
        "scenarios": scenarios,
        "grammar_drills": grammar_drills,
        "liar_liar_rounds": liar_liar_rounds,
    }


def build_word_repo_entries() -> dict[str, list]:
    out: dict[str, list] = {}
    idx_base = 9000
    for lang_key in CURRICULUM_LANGUAGES:
        pack = LANG_PACKS.get(lang_key)
        if not pack:
            continue
        entries = []
        for i, row in enumerate(pack["words"]):
            entries.append(_phrase_card_entry(lang_key, idx_base + i, pack, row))
        repo_key = "nigerian_pidgin" if lang_key == "pidgin" else lang_key
        out[repo_key] = entries
        if lang_key == "pidgin":
            out["pidgin"] = entries
    return out


def build_curriculum_a1() -> dict:
    from .curriculum_engine import build_curriculum_a1_only  # noqa: E402

    return build_curriculum_a1_only(LANG_PACKS)


def build_curriculum_full() -> dict:
    from .curriculum_engine import build_curriculum_a1  # noqa: E402

    return build_curriculum_a1(LANG_PACKS)
