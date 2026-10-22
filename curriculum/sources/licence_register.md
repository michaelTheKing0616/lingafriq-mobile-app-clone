# Licence register (all checked 2026-10-21 at primary source unless noted)

| id | Source | Licence | Use | Attribution |
|---|---|---|---|---|
| leipzig | [Leipzig Corpora Collection (yor/ibo/hau/pcm/swa/zul/xho corpora)](https://wortschatz.uni-leipzig.de/en/download) | CC BY (downloadable corpora; site itself CC BY-NC) | ship | Leipzig Corpora Collection, Universität Leipzig. D. Goldhahn, T. Eckart & U. Quasthoff (2012): Building Large Monolingual Dictionaries at the Leipzig Corpora Collection. LREC 2012. CC BY. |
| asp | [African Storybook / Global-ASP asp-source](https://github.com/global-asp/asp-source) | Per story: CC BY 4.0 (shipped) / CC BY-NC (excluded) | ship (CC BY stories only) | Story credits (author, illustrator, translator) as listed per story; African Storybook Initiative, www.africanstorybook.org, CC BY 4.0. |
| sadilar_morph | [SADiLaR NCHLT morphologically annotated corpora isiZulu/isiXhosa (SADII-Ext 2023)](https://repo.sadilar.org) | CC BY 4.0 | ship | SADiLaR / NCHLT Morphologically annotated corpora (isiZulu, isiXhosa), 2023, CC BY 4.0. |
| sadilar_xhmono | [SADiLaR English-isiXhosa Drop monolingual isiXhosa corpus 1.0.0](https://repo.sadilar.org) | CC BY 4.0 | ship | SADiLaR, English–isiXhosaDrop Monolingual Corpus 1.0.0 (2019), CC BY 4.0. |
| fsi | [FSI Basic Courses (Yoruba, Hausa, Swahili, Igbo) student texts](https://www.fsi-language-courses.org/) | Public domain (US Government work) | ship (grammar evidence/locators) | Foreign Service Institute, US Department of State. Public domain. |
| cv_sentences | [Mozilla Common Voice sentence-collector text (yo, ig, ha, zu, xh; repo server/data/<lang>/sentence-collector.txt)](https://github.com/common-voice/common-voice/tree/main/server/data) | CC0 / public domain (Sentence Collector accepts only public-domain sentences; Common Voice dataset CC0) | ship | Mozilla Common Voice contributors (CC0; attribution not required, given as courtesy). |
| synth-v2 | [LingAfriq original synthesized B2–C2 items (AI-drafted, unattested forms allowed)](synth/v2/*.tsv) | original (LingAfriq) | ship after review only (all needs-review) | LingAfriq |
| kaikki | [Kaikki.org Wiktionary extracts](https://kaikki.org/dictionary/) | CC BY-SA 4.0 + GFDL | cross-check only | n/a (not shipped) |
| fleurs | [Google FLEURS](https://huggingface.co/datasets/google/fleurs) | Card CC BY 4.0; transcripts from FLoRes-101 (CC BY-SA 4.0) | cross-check only | n/a |
| masakhaner2 | [MasakhaNER 2.0](https://github.com/masakhane-io/masakhane-ner) | CC BY-NC 4.0 | excluded |  |
| masakhapos | [MasakhaPOS](https://github.com/masakhane-io/masakhane-pos) | README: CC BY-4.0-NC (HF card afl-3.0 conflicts) | excluded |  |
| nla_orthography | [Naija Langwej Akademi orthography / Naijá spelling guidance]((no licensed text located)) | Not stated | excluded as text; spelling conventions may be cited as facts by a reviewer only |  |
| cv_pcm | [Mozilla Common Voice Nigerian Pidgin v27.0 (2026-09-11)](https://datacollective.mozillafoundation.org) | CC0 | qualifies; NOT downloaded (needs MDC account); link-only, no re-hosting |  |
| cv27_pcm | [Mozilla Common Voice 27.0 Nigerian Pidgin: validated_sentences.tsv (987 sentences) + validated.tsv (clip refs)](https://datacollective.mozillafoundation.org) | CC0 | ship sentences; audio link-only (no re-hosting per MDC terms) | Mozilla Common Voice contributors (CC0) |
| cv27_xh | [Mozilla Common Voice 27.0 isiXhosa: validated_sentences.tsv + validated.tsv](https://datacollective.mozillafoundation.org) | CC0 | ship sentences; clip refs link-only | Mozilla Common Voice contributors (CC0) |
| cv_xh | [Mozilla Common Voice isiXhosa v27.0](https://datacollective.mozillafoundation.org) | CC0 | qualifies but negligible (35 clips, 0.02 h validated); not downloaded |  |
| naija_tts | [Naija-TTS-Dataset (MDC)](https://datacollective.mozillafoundation.org) | NOODL-1.0 (research only, no redistribution, no voice cloning) | excluded |  |
| hf_pcm_asr | [asr-nigerian-pidgin/nigerian-pidgin-1.0 (Hugging Face)](https://huggingface.co/datasets/asr-nigerian-pidgin/nigerian-pidgin-1.0) | cc-by-4.0 (card); transcripts crawled text of undocumented origin | conditional: audio only after provenance confirmed; text cross-check only; not used |  |
| slr32 | [OpenSLR SLR32 (isiXhosa etc. TTS)](https://openslr.org/32/) | CC BY-SA 4.0 | cross-check / ASR-eval only (shipping audio or derived models would impose share-alike) |  |
| vixsd | [Vukuzenzele ViXSD isiXhosa speech (Esethu)](https://huggingface.co/datasets/Esethu/ViXSD) | Open release CC BY-NC-SA 4.0; commercial needs signed agreement (fee waiver for African entities) | not usable until agreement signed |  |
| african_voices | [African Voices (Data Science Nigeria)](https://africanvoices.ai) | ToS licence; CC BY 4.0 by default, commercial + derivatives with attribution | qualifies (ha/ig/pcm/yo); NOT downloaded (needs registration) |  |
| tonative | [Tonative datasets (XNLI adaptation, MRL-Benchmark incl. Pidgin)](https://tonative.org) | Not stated | excluded (unclear) |  |
| peace_corps | [Peace Corps language manuals](various) | Public-domain status unclear | excluded (unclear) |  |

Notes:
- **leipzig**: Licence page bot-walled (403); verified via Terms of Usage text in search index. Sentences from *.wikipedia.org (CC BY-SA) and Bible/JW domains excluded from shipped examples; frequencies use all.
- **fsi**: Scanned images; OCR with English model, target-language diacritics unreliable -> used for grammar-topic locators only.
- **cv_sentences**: No pcm file exists in the repo; the 987 pcm sentences are only in the dataset download (MDC account). wiki.ig.txt / wiki.sw.txt (Wikipedia-extracted) not used. PD status is contributor-asserted.
- **kaikki**: No Igbo or Nigerian Pidgin files.
- **cv_pcm**: 8,964 clips, 12.5 h validated, 60 speakers, 987 sentences.
- **cv27_pcm**: Downloaded by user to ~/Downloads 2026-10-21; only sentence TSVs extracted.
