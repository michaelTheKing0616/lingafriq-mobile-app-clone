# Mockup fidelity (Phase D) — stitch HTML clusters

**Source:** `Elite Features to implement/stitch_private_chat/stitch_private_chat/**/code.html` (~88 files).

## Process

1. **Cluster** by journey: Village hub, AI chat, Classroom, Learning path, Games-adjacent, Settings.
2. For each Flutter screen in the cluster, compare:
   - App bar / navigation pattern
   - Spacing and section rhythm (use existing design tokens)
   - Typography roles (title / body / caption)
   - Primary CTA visibility and tap targets
3. **Acceptance:** Flutter meets UX contract; pixel-perfect match optional—document gaps in `SCREEN_API_MATRIX.md` **Won’t fix** with reason.

## Clusters (fill during passes)

| Cluster | HTML count (approx.) | Flutter counterparts | Status |
|---------|----------------------|----------------------|--------|
| Village + Polie CTA | TBD | `VillagesHubScreen`, village routes | Checklist template — fill per PR |
| Chat | TBD | `GlobalChatScreenMaterial3`, private chat | Checklist template — fill per PR |
| Classroom | TBD | `live_classroom_*` | Checklist template — fill per PR |
| Learning path | TBD | `LearningPathScreen`, hub | Checklist template — fill per PR |

**Gate:** Mark **Pass** only after the four checklist bullets in **Process** are explicitly verified for that cluster (or document **Won’t fix** in the matrix).
