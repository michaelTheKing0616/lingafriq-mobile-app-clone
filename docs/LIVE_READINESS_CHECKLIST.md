# Live readiness checklist (per screen / feature)

Use this for every surface before marking **Pass** in `SCREEN_API_MATRIX.md`.

1. **Navigation**
   - Primary CTA reaches the intended destination with correct arguments.
   - Secondary actions and back navigation behave predictably (no orphaned routes).

2. **Data states**
   - **Loading:** Shown within ~1 frame of request; no blank screen with no feedback.
   - **Empty:** Explains why empty; offers a next step (e.g. refresh, change filter, sign in).
   - **Error:** User-visible message; **Retry** where the operation is idempotent; do not swallow HTTP 5xx as “empty list”.

3. **Auth**
   - Guest vs signed-in behavior is defined and tested for the feature.
   - 401/403: redirect to login or inline message—not silent failure.

4. **Observability**
   - Failures log structured context (route, status code); **never** log tokens or PII.

5. **Tests**
   - Non-trivial logic has unit tests; critical flows have widget/integration coverage where feasible.

6. **Backend contract**
   - Mobile paths match [`lib/config/api_contract.dart`](../lib/config/api_contract.dart) and deployed Node routes.
