# FLB Heritage — API and bundled fallback

## Primary (online)

Uses the existing **culture magazine** list endpoint:

- `GET /culture-magazine/articles?published=true&tags=flb-heritage`
- Optional: `search=...` (title/content/tags regex, see `cultureMagazine.controller.ts`)
- Pagination: `page`, `limit` (mongoose-paginate-v2; see `data.docs` in responses)

Articles must include the tag **`flb-heritage`** (AND-matched when multiple tags are supplied).

## Single item

- `GET /culture-magazine/articles/:slugOrId`  
  Resolves by **slug** or **Mongo ObjectId** string when `published: true`.

## Seeding (staging / production)

From `node-backend-safe-push`:

```bash
npm run seed:flb-heritage
```

Requires `MONGODB_URI` or `MONGO_URI`. Idempotent upsert by `slug`.

## Offline / API failure (mobile)

The app loads `assets/data/flb_heritage_archive.json` when the API fails or returns an empty list, so the archive screen is never a dead end.
