# Point-and-Say held-out evaluation (P7-947)

## Manifests (not checked in until counsel signs image sources)

| Path | Role |
|---|---|
| `assets/data/point_say/training_manifest.jsonl` | Commercial or newly collected train rows |
| `assets/data/point_say/heldout_manifest.jsonl` | African-objects held-out set (never trained on) |

Each train row requires `licence_source_id` matching a row in `curriculum/sources/licence_register.json`.
Rows with `source_origin: siglip_match` require `learner_confirmed: true` and `learner_photo_opt_in: true`.

## Commands

```bash
python tools/point_say/finetune.py --mode fixture
python tools/point_say/eval_heldout.py
```

Default repo state: no training manifest → `LICENSED_DATASET_MISSING` (no checkpoint).

## Priority classes (when present in the licensed set)

plantain, garri, agbada, mortar_and_pestle, danfo, akara, kente — each must map to an `afr.*` `object_set_id` in `assets/lens/african_object_set.json`.
