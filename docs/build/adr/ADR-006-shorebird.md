charter: v2

# ADR-006 — Shorebird Dart patching

Status: builder default, 2026-10-23. Tope may override. Card P2-039.

## Recommendation

Do not enable Shorebird in this build.

## Policy fit

Store rules still require a review for native code and for some behavior changes. A Dart patch can ship a lesson bugfix without a store review, and it can also ship a behavior change the stores did not see. The release gates (crash-free users 0.995, ANR rate 0.0047) apply to a patched binary the same way they apply to a store build. Elevation allows a patch tool only if policy allows it.

## Risk

A bad patch reaches installed apps without the staged store rollout. Rollback is a second patch, not a store halt. The crash gate does not by itself block a patch.

## Choice

Shorebird stays off. No Shorebird app id, no patch channel, and no code changes through that tool. A later signature from Tope can turn it on. Until then, fixes ship through the store with the existing rollout stages.
