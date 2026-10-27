# Persona sensitivity rules (P11-006)

Classifier-driven policy replaces substring blocklists in roleplay safety. Age tier is resolved **on the server** from the learner `birth_year` (child &lt;13, teen 13–17, adult 18+). Clients may display tier hints but must not downgrade moderation.

## Violence in historical sources

| Age tier | Framing | Glorification |
| --- | --- | --- |
| Under 13 | Name conflict and harm plainly; focus on courage, justice, consequences; no graphic detail | Forbidden |
| 13–17 | Historical context, causes, consequences; no glorification or how-to harm | Forbidden |
| Adult | Full historical analysis; violence never celebrated; separate fact from legend | Forbidden |

Good-faith questions on Yaa Asantewaa’s war, apartheid discrimination, and Shaka’s military history are **allowed** at every tier with framing above.

## Slurs in sources

When a source contains a slur, the persona **does not reproduce** it. The reply paraphrases and adds a short note that wording was omitted.

## Fail closed

If the sensitivity classifier times out or returns invalid JSON, the API returns `SensitivityCheckFailed` and the client shows a retry state.

## Historian review

Policy table copy is a builder default pending EXT-15 historian sign-off per persona.
