# Backend contract: `POST /hybrid-polie/translate`

**Verified against:** `node-backend` (`hybrid-polie.controller.ts`, `translate` handler)  
**Last updated:** 2026-04-05  

## Purpose

Server-side translation for Polie / mobile `TranslationService` (`ApiContract.ai.hybridTranslate` → `/hybrid-polie/translate`). Routing is **fixed**: quality-ordered fallbacks, not yet driven by client “model” selection.

## Authentication

- Requires authenticated user (`userId` on request). Unauthenticated calls return **401**.

## Request body

| Field | Required | Notes |
|--------|-----------|--------|
| `text` | Yes | Validated for max length (`validateTextLength`). |
| `sourceLang` | Yes | Must pass `validateLanguageCode` (allowlist). |
| `targetLang` | Yes | Same. |
| `__tokensConsumed` | No | Internal: skips token debit when truthy. |
| `llmModel` | No | **Optional string** (trimmed, max **160** chars). **Does not select an engine** today. Echoed in `metadata.llmModelRequested` on success. Logged at debug when present. |
| `includePhraseBreakdown` | No | **Optional boolean**. **No phrase breakdown is generated** yet. Echoed as `metadata.includePhraseBreakdownRequested`. |

Extra JSON fields are ignored except the above.

## Successful response (200)

- `translation` (string)  
- `sourceText`, `sourceLang`, `targetLang`  
- `model` — e.g. `google-translate`, `NLLB-200` or `AfriNLLB/NLLB` (depends on repo branch), `mymemory`  
- `confidence` (number)  
- `fallback` (boolean) — present when not using Google primary (repo variants may differ).  
- `metadata` — object including:
  - `llmModelRequested`: `string | null`
  - `includePhraseBreakdownRequested`: `boolean`
  - `routingNote`: explains that routing is fixed until a future implementation.

## Engine order (confirmed)

1. **Google Translate** (via `freeGoogleTranslate.service`), when language codes map successfully.  
2. **NLLB / AfriNLLB family** (Hugging Face), when configured and available (exact stack differs slightly between **Downloads** `node-backend-main` and **intermediary** `node-backend-safe-push`).  
3. **MyMemory** free API.

## Client alignment (Flutter)

- `lib/services/hybrid_polie/translation_service.dart` may send `llmModel` and `includePhraseBreakdown`. This is **safe** and now **visible in `metadata`** on the push-ready backend copy.  
- To make `llmModel` **change behavior**, backend work is required (e.g. skip Google, force NLLB, or call an LLM post-edit). Track that under product/API design, not this contract doc.

## Implementation locations

- **Intermediary (push from here):** `C:\Users\HP\Desktop\LingAfriqMobile\node-backend-safe-push\src\controllers\hybrid-polie.controller.ts`  
- **Local Downloads clone:** `C:\Users\HP\Downloads\node-backend-main\src\controllers\hybrid-polie.controller.ts` (keep in sync when merging)

## Related mobile contract

- `lib/config/api_contract.dart` — `hybridTranslate` path.  
