charter: v2

# African Storybook — Igbo catalogue check (2026-10-23)

**Date:** 2026-10-23  
**Register row:** `african-storybook`

## URLs opened

1. https://www.africanstorybook.org/

## What the pages showed

### https://www.africanstorybook.org/

HTTP 200. The response body was not the storybook catalogue. It was the CentOS/Apache default test page:

> This page is used to test the proper operation of the Apache HTTP server after it has been installed. If you can read this page it means that this site is working properly.

> The website you just visited is either experiencing problems or is undergoing routine maintenance.

The page did not list languages, did not mention Igbo, and did not state any count of Igbo titles or CC BY Igbo titles.

### https://www.africanstorybook.org/read/downloadbook.php?a=1&d=0&id=33900&layout=landscape

HTTP 404. Body:

> Not Found
>
> The requested URL /read/downloadbook.php was not found on this server.

## Search index vs live fetch (2026-10-23)

- The live homepage fetch was the Apache test page already quoted.
- https://www.africanstorybook.org/read/downloadbook.php?a=1&d=0&id=33900&layout=landscape returned HTTP 404 when opened, and a search index for that same URL quotes the lines `Language - Igbo` and `Creative Commons: Attribution 4.0`.
- Search index entries for booklet id 39597 and downloadbook id 47380 also quote `Language - Igbo` and `Creative Commons: Attribution 4.0`.
- A search snippet for the homepage quotes 262 languages and 5513 storybooks. Those figures are the whole catalogue, not an Igbo count.
- No page opened live stated how many Igbo titles are CC BY. The register value stays `unverified`. `none` would be false.

## Outcome

**CC BY Igbo count not confirmed** — No live page stated an Igbo CC BY title count. Register `igbo_cc_by_titles` remains `unverified`.
