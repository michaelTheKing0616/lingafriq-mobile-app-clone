Implementation Notes and Integration Guidance
-------------------------------------------
- Install src_diacritics_correction.py into your Polie pipeline as a post-process step.
- When running responses from the language model:
  1) If mode == translate or tutor: call enforce_diacritics(response_text, lang=target_lang)
  2) If changed == True: prefer corrected text for user output and store telemetry event 'diacritics_corrected'.
- For low-resource languages, add curated phrase mappings into the LANG_MAPS registry via register_mapping().
- Consider adding a lightweight fuzzy-matching token-level step for partial matches.