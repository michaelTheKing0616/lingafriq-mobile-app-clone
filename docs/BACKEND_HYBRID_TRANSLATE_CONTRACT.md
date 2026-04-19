# Backend contract: `POST /hybrid-polie/translate`

**Verified against:** `node-backend-safe-push` (`hybrid-polie.controller.ts`, `translate` handler)  
**Last updated:** 2026-04-19  

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

1. **Google Translate** (via `freeGoogleTranslate.service`), **only when** both source and target map to non-`null` ISO codes (see above).  
2. **AfriNLLB then NLLB-200** (Hugging Face), when token, URL, and env allow—AfriNLLB endpoints are tried **before** the generic NLLB model.  
3. **MyMemory** free API, **only when** both sides map to non-`null` ISO codes (same mapping as Google for this purpose).

If Google is skipped due to `null` mapping, the flow proceeds to HF, then MyMemory under the same rules.

## Client alignment (Flutter)

- `lib/services/hybrid_polie/translation_service.dart` resolves display names and backend keys to **FLORES wire codes** (`_resolveToNllbCode`) for caches, backend JSON, and HF/MyMemory, keeping behavior aligned with `polie_translate_language_options.dart`.  
- `llmModel` and `includePhraseBreakdown` are **safe** and echoed in `metadata` where implemented. Changing routing based on `llmModel` still requires backend product work.

## Implementation locations

- **Intermediary (push from here):** `C:\Users\HP\Desktop\LingAfriqMobile\node-backend-safe-push\src\controllers\hybrid-polie.controller.ts`  
- **Local Downloads clone:** `C:\Users\HP\Downloads\node-backend-main\src\controllers\hybrid-polie.controller.ts` (keep in sync when merging)

## Related mobile contract

- `lib/config/api_contract.dart` — `hybridTranslate` path.  
