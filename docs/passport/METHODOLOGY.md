# LingAfriq Proficiency Passport — CEFR mapping methodology

```json
{
  "charter": "v2",
  "card_id": "P10-914",
  "versions": [
    {
      "id": "2026.1",
      "effective_from": "2026-10-27",
      "review_by": "2027-04-27",
      "supersedes": null,
      "public_slug": "2026.1"
    }
  ],
  "limits": [
    "Passport levels are aligned to CEFR bands for curriculum can-dos; they are not a replacement for an official CEFR examination.",
    "Speaking scores come from LingAfriq's proctored rubric (fluency, accuracy, comprehensibility, register), not from a third-party exam board.",
    "No accuracy or correlation figure is published here unless it appears in a cited efficacy study in the licence register."
  ],
  "descriptor_registry": {
    "CV2020.A1.SPEAK": {
      "title": "Spoken interaction A1 (global scale)",
      "source": "Council of Europe, CEFR Companion Volume (2020), spoken interaction A1 descriptors"
    },
    "CV2020.A1.READ": {
      "title": "Reading A1 (global scale)",
      "source": "Council of Europe, CEFR Companion Volume (2020), reading A1 descriptors"
    },
    "CV2020.A1.LEX": {
      "title": "Vocabulary range A1 (global scale)",
      "source": "Council of Europe, CEFR Companion Volume (2020), vocabulary A1 descriptors"
    },
    "CV2020.A2.SPEAK": {
      "title": "Spoken interaction A2 (global scale)",
      "source": "Council of Europe, CEFR Companion Volume (2020), spoken interaction A2 descriptors"
    },
    "CV2020.A2.READ": {
      "title": "Reading A2 (global scale)",
      "source": "Council of Europe, CEFR Companion Volume (2020), reading A2 descriptors"
    },
    "CV2020.A2.LEX": {
      "title": "Vocabulary range A2 (global scale)",
      "source": "Council of Europe, CEFR Companion Volume (2020), vocabulary A2 descriptors"
    },
    "CV2020.B1.SPEAK": {
      "title": "Spoken interaction B1 (global scale)",
      "source": "Council of Europe, CEFR Companion Volume (2020), spoken interaction B1 descriptors"
    },
    "CV2020.B1.READ": {
      "title": "Reading B1 (global scale)",
      "source": "Council of Europe, CEFR Companion Volume (2020), reading B1 descriptors"
    },
    "CV2020.B1.LEX": {
      "title": "Vocabulary range B1 (global scale)",
      "source": "Council of Europe, CEFR Companion Volume (2020), vocabulary B1 descriptors"
    },
    "CV2020.B2.SPEAK": {
      "title": "Spoken interaction B2 (global scale)",
      "source": "Council of Europe, CEFR Companion Volume (2020), spoken interaction B2 descriptors"
    },
    "CV2020.B2.READ": {
      "title": "Reading B2 (global scale)",
      "source": "Council of Europe, CEFR Companion Volume (2020), reading B2 descriptors"
    },
    "CV2020.B2.LEX": {
      "title": "Vocabulary range B2 (global scale)",
      "source": "Council of Europe, CEFR Companion Volume (2020), vocabulary B2 descriptors"
    },
    "CV2020.C1.SPEAK": {
      "title": "Spoken interaction C1 (global scale)",
      "source": "Council of Europe, CEFR Companion Volume (2020), spoken interaction C1 descriptors"
    },
    "CV2020.C1.READ": {
      "title": "Reading C1 (global scale)",
      "source": "Council of Europe, CEFR Companion Volume (2020), reading C1 descriptors"
    },
    "CV2020.C1.LEX": {
      "title": "Vocabulary range C1 (global scale)",
      "source": "Council of Europe, CEFR Companion Volume (2020), vocabulary C1 descriptors"
    },
    "CV2020.C2.SPEAK": {
      "title": "Spoken interaction C2 (global scale)",
      "source": "Council of Europe, CEFR Companion Volume (2020), spoken interaction C2 descriptors"
    },
    "CV2020.C2.READ": {
      "title": "Reading C2 (global scale)",
      "source": "Council of Europe, CEFR Companion Volume (2020), reading C2 descriptors"
    },
    "CV2020.C2.LEX": {
      "title": "Vocabulary range C2 (global scale)",
      "source": "Council of Europe, CEFR Companion Volume (2020), vocabulary C2 descriptors"
    }
  },
  "skill_cefr_to_descriptor": {
    "A1.SPEAK": "CV2020.A1.SPEAK",
    "A1.READ": "CV2020.A1.READ",
    "A1.LEX": "CV2020.A1.LEX",
    "A2.SPEAK": "CV2020.A2.SPEAK",
    "A2.READ": "CV2020.A2.READ",
    "A2.LEX": "CV2020.A2.LEX",
    "B1.SPEAK": "CV2020.B1.SPEAK",
    "B1.READ": "CV2020.B1.READ",
    "B1.LEX": "CV2020.B1.LEX",
    "B2.SPEAK": "CV2020.B2.SPEAK",
    "B2.READ": "CV2020.B2.READ",
    "B2.LEX": "CV2020.B2.LEX",
    "C1.SPEAK": "CV2020.C1.SPEAK",
    "C1.READ": "CV2020.C1.READ",
    "C1.LEX": "CV2020.C1.LEX",
    "C2.SPEAK": "CV2020.C2.SPEAK",
    "C2.READ": "CV2020.C2.READ",
    "C2.LEX": "CV2020.C2.LEX"
  }
}
```

## Version 2026.1 (effective 2026-10-27)

Curriculum can-do statements (`assets/data/cando_map.json`, P5-014) map to CEFR Companion Volume (2020) global-scale descriptor ids via the `skill_cefr_to_descriptor` table above. Each can-do inherits the descriptor for its `cefr` band and `skill` column.

Passport issue levels (A1–C1 from the proctored rubric) describe overall spoken performance; unit can-dos remain the evidence portfolio anchors (P10-915).

**Next methodology review:** 2027-04-27.

## Version history

| Version | Effective | Review by | Notes |
|---------|-----------|-----------|-------|
| 2026.1 | 2026-10-27 | 2027-04-27 | Initial published methodology (P10-914). |

Older versions remain readable in this file when superseded; the `versions` array in the JSON block is append-only.
