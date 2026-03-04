# Rollout Evidence Bundle

This index points to release-readiness artifacts across the current revamp repositories.

## Artifact Locations

### Mobile Main

- Scorecard: `C:/Users/HP/Desktop/LingAfriqMobile/mobile-app-main/docs/RELEASE_READINESS_SCORECARD.md`
- Evidence script: `C:/Users/HP/Desktop/LingAfriqMobile/mobile-app-main/scripts/collect-release-evidence.ps1`
- Evidence logs output: `C:/Users/HP/Desktop/LingAfriqMobile/mobile-app-main/docs/evidence/`

### Mobile Safe Push

- Scorecard: `C:/Users/HP/Desktop/LingAfriqMobile/mobile-app-safe-push-michael/docs/RELEASE_READINESS_SCORECARD.md`
- Evidence script: `C:/Users/HP/Desktop/LingAfriqMobile/mobile-app-safe-push-michael/scripts/collect-release-evidence.ps1`
- Evidence logs output: `C:/Users/HP/Desktop/LingAfriqMobile/mobile-app-safe-push-michael/docs/evidence/`

### Backend

- Scorecard: `C:/Users/HP/Downloads/node-backend-main/node-backend-main/docs/BACKEND_RESILIENCE_AND_LOAD_SCORECARD.md`
- Evidence script: `C:/Users/HP/Downloads/node-backend-main/node-backend-main/scripts/collect-backend-release-evidence.ps1`
- Evidence logs output: `C:/Users/HP/Downloads/node-backend-main/node-backend-main/docs/evidence/`

## Evidence Collection Commands

Run from each repository root.

### Mobile Main

`powershell -ExecutionPolicy Bypass -File .\scripts\collect-release-evidence.ps1`

### Mobile Safe Push

`powershell -ExecutionPolicy Bypass -File .\scripts\collect-release-evidence.ps1`

### Backend

`powershell -ExecutionPolicy Bypass -File .\scripts\collect-backend-release-evidence.ps1`

## Bundle Completion Checklist

- [ ] Mobile main scorecard completed with evidence links
- [ ] Mobile safe scorecard completed with evidence links
- [ ] Backend scorecard completed with evidence links
- [ ] Latest evidence logs attached to release ticket
- [ ] GO/NO-GO decision recorded with approvers
