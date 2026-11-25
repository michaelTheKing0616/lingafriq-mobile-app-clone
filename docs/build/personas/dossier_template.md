# Persona dossier template (P11-002)

Authoritative persona grounding lives in validated dossier JSON ingested by `node-backend/src/services/persona/retrieval.service.ts`. The mobile client reads only the v1 roster manifest from `HistoricalPersonaRegistry.dossierRoster` (ADR-031).

## Required fields

| Field | Notes |
| --- | --- |
| `persona_id` | Lowercase snake_case; matches ADR-031 for v1 figures |
| `display_name` | UI label |
| `death_date` | ISO-8601 date |
| `primary_sources[]` | At least one row; `licence_status: approved` required for retrieval |
| `secondary_sources[]` | May be empty |
| `contested_points[]` | Historian-flagged disputes |
| `known_myths[]` | Popular myths to refuse |
| `review` | `{ historian_id, signed_at }` — required before ingest |
| `retrieval_cards[]` | Passages tied to `source_id`; indexed per persona |

Optional: `delivery_mode` (`first_person` \| `narrated_as_told_by`) per ADR-031.

## Validation errors

Invalid dossiers throw `DossierInvalid` with a `field` name (never silent defaults).

## Retrieval

After ingest, persona turns call `retrieveForPersonaTurn` / `assertPersonaTurnGrounding`. Zero matching cards → `NoGroundingError` (no plain-system-prompt fallback).

## Example skeleton

```json
{
  "persona_id": "yaa_asantewaa",
  "display_name": "Yaa Asantewaa",
  "death_date": "1921-10-17",
  "delivery_mode": "first_person",
  "primary_sources": [
    {
      "type": "archive",
      "title": "Colonial Office correspondence on the War of the Golden Stool",
      "year": 1900,
      "licence_status": "approved"
    }
  ],
  "secondary_sources": [],
  "contested_points": [],
  "known_myths": [],
  "review": { "historian_id": "historian-id", "signed_at": "2026-10-27T00:00:00Z" },
  "retrieval_cards": [
    {
      "card_id": "yaa.card.example",
      "source_id": "src-…",
      "text": "Short cited passage only.",
      "terms": ["keyword"]
    }
  ]
}
```

Store shipped dossiers under `docs/build/personas/dossiers/*.json`.
