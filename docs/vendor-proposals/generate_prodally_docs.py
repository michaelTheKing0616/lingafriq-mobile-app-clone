#!/usr/bin/env python3
"""Generate partner + Prodally PDF documents for the proposal gap analysis."""

from __future__ import annotations

from datetime import date
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT, TA_RIGHT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    Flowable,
    HRFlowable,
    KeepTogether,
    ListFlowable,
    ListItem,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

# Brand palette — deep forest + sand accent (not purple/cream AI defaults)
INK = colors.HexColor("#14211A")
MUTED = colors.HexColor("#5C6B62")
RULE = colors.HexColor("#D5DDD7")
SURFACE = colors.HexColor("#F4F7F4")
CARD = colors.HexColor("#FFFFFF")
ACCENT = colors.HexColor("#1F6B4A")
ACCENT_SOFT = colors.HexColor("#E7F2EC")
WARN = colors.HexColor("#8A5A12")
WARN_SOFT = colors.HexColor("#F8F0E2")
DANGER = colors.HexColor("#8B2E2E")
DANGER_SOFT = colors.HexColor("#F7E8E8")
INFO = colors.HexColor("#1E4D6B")
INFO_SOFT = colors.HexColor("#E7F0F6")

PAGE_W, PAGE_H = A4
MARGIN = 18 * mm

TODAY = date(2026, 9, 5).strftime("%-d %B %Y")

OUT_DIR = Path(
    "/Users/temitopeolaitanmichael/LingAfriq/lingafriq/lingafriq-mobile-app-clone/docs/vendor-proposals"
)
DOWNLOADS = Path("/Users/temitopeolaitanmichael/Downloads/LingAfriq-Prodally-Docs")

GAP_ROWS = [
    (
        "Auth, profile, settings, biometrics",
        "Login/signup, verify, biometrics, secure storage, privacy, delete account, dark mode, i18n",
        "Not itemized",
        "MISSING",
    ),
    (
        "Onboarding & placement",
        "Multiple onboarding flows + placement quiz/test",
        "Implied via personalization only",
        "PARTIAL",
    ),
    (
        "Curriculum / Authentic Path",
        "Lessons map, A1–C1 authentic path, certificates, bundled CMS, history & mannerisms",
        "Offline packs + cultural/history (high level); admin course mgmt",
        "PARTIAL",
    ),
    (
        "Grammar / vocab / skill practice",
        "Grammar hub, flashcards, listening/writing, speak missions, tone drills, SRS",
        "Lumped under language tools",
        "PARTIAL",
    ),
    (
        "Living Dictionary & Phrase DNA",
        "Shipped in app",
        "Named in Module 1",
        "NAMED (rebuild risk)",
    ),
    (
        "Dialect customization",
        "Dialect preference + variant picker",
        "Named in Module 1",
        "NAMED (rebuild risk)",
    ),
    (
        "Translation (Polie / Live / Offline)",
        "Multi-path translation stack already live",
        "Real-time translation & dictionary upgrade",
        "PARTIAL",
    ),
    (
        "Pronunciation / African TTS / STT",
        "African TTS, scoring, tone detection, pitch viz, ASR game scorer",
        "Pronunciation & rhythm coaching",
        "PARTIAL",
    ),
    (
        "Polie AI tutor (multi-mode)",
        "Translation, Tutor, Roleplay, Vocabulary, Review + hybrid orchestrator",
        "AI chat coach (one line)",
        "PARTIAL",
    ),
    (
        "Historical personas & missions",
        "26 personas + mission flows + safety/assessment",
        "Not mentioned",
        "MISSING",
    ),
    (
        "Human tutor marketplace",
        "Not a full booking marketplace today",
        "Discovery, booking, session management",
        "NET-NEW",
    ),
    (
        "Live classrooms (LiveKit)",
        "Classroom, lobby, notes, queue, roster, assignments",
        "Scheduling & attendance",
        "NAMED (rebuild risk)",
    ),
    (
        "Practice / conversation rooms",
        "Practice room setup, collaborative LiveKit sessions",
        "Role-play / guided conversation rooms",
        "PARTIAL",
    ),
    (
        "Games catalog",
        "42 registered game types + Flame/Rive infrastructure",
        "Not mentioned",
        "MISSING",
    ),
    (
        "Gamification systems",
        "Hearts, quests, seasonal events, magic items, ancestral tree, leagues, tribe wars",
        "Streaks/XP/badges extended; leaderboards; challenges",
        "PARTIAL",
    ),
    (
        "Villages & Tribes",
        "Hub, maps, market/cafe/elder hut, Tribe vs Tribe, tribal duel",
        "Language Village + My Tribe",
        "PARTIAL",
    ),
    (
        "Chat (global / tribe / private)",
        "Socket.IO chats, WA-style DM, call history, @Polie, moderation",
        "Global chat + private messaging + reporting",
        "PARTIAL",
    ),
    (
        "X-style community feed",
        "Home, compose, explore, lists, notifications, profiles",
        "Not mentioned",
        "MISSING",
    ),
    (
        "Snap + WA status social",
        "Snap inbox/camera/stories; WA status; starred/media",
        "Not mentioned",
        "MISSING",
    ),
    (
        "Social audio rooms",
        "Discovery, create, following, moderation, scheduled",
        "Not mentioned",
        "MISSING",
    ),
    (
        "Micro-mentor + staff reports",
        "Peer mentoring hub/session + staff moderation",
        "Not mentioned",
        "MISSING",
    ),
    (
        "Offline / sync v2",
        "Hive, Workmanager, selective sync, outbox, conflict resolution, encrypted cache",
        "Offline access & downloadable packs",
        "PARTIAL",
    ),
    (
        "UGC / import media / native review",
        "UGC hub, create lesson/quiz/story, import media, voice contribution",
        "UGC + imported media named",
        "NAMED (rebuild risk)",
    ),
    (
        "Culture magazine & FLB heritage",
        "Magazine + FLB heritage archive",
        "Cultural/history/heritage (high level)",
        "PARTIAL",
    ),
    (
        "Point & Say (ML Kit)",
        "Camera object → speak word",
        "Not mentioned",
        "MISSING",
    ),
    (
        "Passport credentials",
        "Proctored session + credential screens",
        "Not mentioned",
        "MISSING",
    ),
    (
        "Subscriptions (mobile)",
        "Tier UI + RevenueCat + family dashboard",
        "Freemium/monetization + admin tier config",
        "PARTIAL",
    ),
    (
        "Admin & content console",
        "No full CMS admin in Flutter client",
        "Full Module 3 priced",
        "NET-NEW",
    ),
    (
        "Institutional licensing & telco/CSR",
        "Not productized",
        "Marketed in overview; page 11 may exclude telco/CSR",
        "NET-NEW / CONTRADICTORY",
    ),
    (
        "Observability & security",
        "Sentry, certificate pinning, telemetry, health checks",
        "Not in build scope",
        "MISSING",
    ),
    (
        "Client platform / stack",
        "Production Flutter app (Riverpod, LiveKit, Socket.IO, Hive, Firebase)",
        "Frontend Developer (React Native)",
        "STACK MISMATCH",
    ),
    (
        "Learner Web App",
        "Mobile-first Flutter today",
        "Title says Web & Mobile; only Admin React clearly scoped",
        "PARTIAL",
    ),
]


class ColorBand(Flowable):
    def __init__(self, height=6, color=ACCENT):
        super().__init__()
        self.height = height
        self.color = color
        self.width = PAGE_W - 2 * MARGIN

    def draw(self):
        self.canv.setFillColor(self.color)
        self.canv.rect(0, 0, self.width, self.height, fill=1, stroke=0)


class StatusChip(Flowable):
    """Small status label used inside tables."""

    def __init__(self, text: str, kind: str):
        super().__init__()
        self.text = text
        self.kind = kind
        self.height = 14
        self.width = 92

    def wrap(self, availWidth, availHeight):
        return (min(self.width, availWidth), self.height)

    def draw(self):
        mapping = {
            "MISSING": (DANGER_SOFT, DANGER),
            "PARTIAL": (WARN_SOFT, WARN),
            "NAMED (rebuild risk)": (WARN_SOFT, WARN),
            "NET-NEW": (INFO_SOFT, INFO),
            "NET-NEW / CONTRADICTORY": (DANGER_SOFT, DANGER),
            "STACK MISMATCH": (DANGER_SOFT, DANGER),
        }
        bg, fg = mapping.get(self.kind, (SURFACE, MUTED))
        self.canv.setFillColor(bg)
        self.canv.roundRect(0, 0, self.width, self.height, 3, fill=1, stroke=0)
        self.canv.setFillColor(fg)
        self.canv.setFont("Helvetica-Bold", 7)
        self.canv.drawCentredString(self.width / 2, 4, self.text[:22])


def styles():
    base = getSampleStyleSheet()
    s = {
        "cover_kicker": ParagraphStyle(
            "cover_kicker",
            parent=base["Normal"],
            fontName="Helvetica-Bold",
            fontSize=9,
            textColor=ACCENT,
            tracking=1.2,
            spaceAfter=8,
        ),
        "cover_title": ParagraphStyle(
            "cover_title",
            parent=base["Normal"],
            fontName="Helvetica-Bold",
            fontSize=26,
            leading=30,
            textColor=INK,
            spaceAfter=10,
        ),
        "cover_sub": ParagraphStyle(
            "cover_sub",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=11,
            leading=16,
            textColor=MUTED,
            spaceAfter=6,
        ),
        "h1": ParagraphStyle(
            "h1",
            parent=base["Heading1"],
            fontName="Helvetica-Bold",
            fontSize=16,
            leading=20,
            textColor=INK,
            spaceBefore=14,
            spaceAfter=8,
        ),
        "h2": ParagraphStyle(
            "h2",
            parent=base["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=12,
            leading=15,
            textColor=INK,
            spaceBefore=12,
            spaceAfter=6,
        ),
        "body": ParagraphStyle(
            "body",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=9.5,
            leading=13.5,
            textColor=INK,
            alignment=TA_JUSTIFY,
            spaceAfter=7,
        ),
        "body_left": ParagraphStyle(
            "body_left",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=9.5,
            leading=13.5,
            textColor=INK,
            alignment=TA_LEFT,
            spaceAfter=6,
        ),
        "small": ParagraphStyle(
            "small",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=8,
            leading=11,
            textColor=MUTED,
        ),
        "cell": ParagraphStyle(
            "cell",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=7.5,
            leading=10,
            textColor=INK,
        ),
        "cell_head": ParagraphStyle(
            "cell_head",
            parent=base["Normal"],
            fontName="Helvetica-Bold",
            fontSize=8,
            leading=10,
            textColor=INK,
        ),
        "callout_title": ParagraphStyle(
            "callout_title",
            parent=base["Normal"],
            fontName="Helvetica-Bold",
            fontSize=10,
            leading=13,
            textColor=DANGER,
            spaceAfter=4,
        ),
        "callout_body": ParagraphStyle(
            "callout_body",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=9,
            leading=12.5,
            textColor=INK,
        ),
        "bullet": ParagraphStyle(
            "bullet",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=9.5,
            leading=13,
            textColor=INK,
            leftIndent=0,
        ),
        "footer": ParagraphStyle(
            "footer",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=8,
            textColor=MUTED,
            alignment=TA_CENTER,
        ),
        "letter_meta": ParagraphStyle(
            "letter_meta",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=9.5,
            leading=13,
            textColor=INK,
            spaceAfter=2,
        ),
    }
    return s


def footer_factory(label: str):
    def _footer(canvas, doc):
        canvas.saveState()
        canvas.setStrokeColor(RULE)
        canvas.setLineWidth(0.6)
        y = 12 * mm
        canvas.line(MARGIN, y + 6, PAGE_W - MARGIN, y + 6)
        canvas.setFont("Helvetica", 8)
        canvas.setFillColor(MUTED)
        canvas.drawString(MARGIN, y, label)
        canvas.drawRightString(PAGE_W - MARGIN, y, f"Page {doc.page}")
        canvas.restoreState()

    return _footer


def callout(title: str, body: str, s, kind="danger"):
    bg = DANGER_SOFT if kind == "danger" else WARN_SOFT if kind == "warn" else INFO_SOFT
    title_c = DANGER if kind == "danger" else WARN if kind == "warn" else INFO
    title_style = ParagraphStyle(
        "tmp_callout_title", parent=s["callout_title"], textColor=title_c
    )
    data = [[Paragraph(f"<b>{title}</b>", title_style)], [Paragraph(body, s["callout_body"])]]
    t = Table(data, colWidths=[PAGE_W - 2 * MARGIN - 8])
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), bg),
                ("BOX", (0, 0), (-1, -1), 0.8, title_c),
                ("LEFTPADDING", (0, 0), (-1, -1), 10),
                ("RIGHTPADDING", (0, 0), (-1, -1), 10),
                ("TOPPADDING", (0, 0), (-1, 0), 8),
                ("BOTTOMPADDING", (0, -1), (-1, -1), 8),
                ("TOPPADDING", (0, 1), (-1, 1), 0),
            ]
        )
    )
    return t


def metric_row(items, s):
    cells = []
    for value, label, tone in items:
        bg = {
            "danger": DANGER_SOFT,
            "warn": WARN_SOFT,
            "info": INFO_SOFT,
            "ok": ACCENT_SOFT,
        }[tone]
        fg = {
            "danger": DANGER,
            "warn": WARN,
            "info": INFO,
            "ok": ACCENT,
        }[tone]
        inner = [
            [Paragraph(f'<font color="{fg.hexval()}" size="16"><b>{value}</b></font>', s["body_left"])],
            [Paragraph(f'<font color="{MUTED.hexval()}" size="8">{label}</font>', s["small"])],
        ]
        box = Table(inner, colWidths=[40 * mm])
        box.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, -1), bg),
                    ("BOX", (0, 0), (-1, -1), 0.5, RULE),
                    ("LEFTPADDING", (0, 0), (-1, -1), 8),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                    ("TOPPADDING", (0, 0), (-1, -1), 8),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
                ]
            )
        )
        cells.append(box)
    t = Table([cells], colWidths=[45 * mm] * len(items))
    t.setStyle(TableStyle([("LEFTPADDING", (0, 0), (-1, -1), 0), ("RIGHTPADDING", (0, 0), (-1, -1), 4)]))
    return t


def gap_table(s, compact=False):
    header = [
        Paragraph("<b>Domain</b>", s["cell_head"]),
        Paragraph("<b>In current app</b>", s["cell_head"]),
        Paragraph("<b>In Prodally SOW</b>", s["cell_head"]),
        Paragraph("<b>Coverage</b>", s["cell_head"]),
    ]
    rows = [header]
    for domain, in_app, in_prop, cov in GAP_ROWS:
        rows.append(
            [
                Paragraph(domain, s["cell"]),
                Paragraph(in_app, s["cell"]),
                Paragraph(in_prop, s["cell"]),
                Paragraph(f"<b>{cov}</b>", s["cell"]),
            ]
        )
    widths = [38 * mm, 58 * mm, 48 * mm, 30 * mm]
    t = Table(rows, colWidths=widths, repeatRows=1)
    style_cmds = [
        ("BACKGROUND", (0, 0), (-1, 0), ACCENT_SOFT),
        ("GRID", (0, 0), (-1, -1), 0.4, RULE),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]
    for i, (_, _, _, cov) in enumerate(GAP_ROWS, start=1):
        if cov in ("MISSING", "STACK MISMATCH", "NET-NEW / CONTRADICTORY"):
            style_cmds.append(("BACKGROUND", (3, i), (3, i), DANGER_SOFT))
        elif "NAMED" in cov or cov == "PARTIAL":
            style_cmds.append(("BACKGROUND", (3, i), (3, i), WARN_SOFT))
        elif cov == "NET-NEW":
            style_cmds.append(("BACKGROUND", (3, i), (3, i), INFO_SOFT))
    t.setStyle(TableStyle(style_cmds))
    return t


def bullets(items, s):
    flow = []
    for item in items:
        flow.append(Paragraph(f"• {item}", s["bullet"]))
    return flow


def build_partner_pdf(path: Path):
    s = styles()
    doc = SimpleDocTemplate(
        str(path),
        pagesize=A4,
        leftMargin=MARGIN,
        rightMargin=MARGIN,
        topMargin=16 * mm,
        bottomMargin=18 * mm,
        title="LingAfriq Partner Brief — Prodally Proposal Assessment",
        author="LingAfriq",
    )
    story = []

    story.append(ColorBand(5, ACCENT))
    story.append(Spacer(1, 10))
    story.append(Paragraph("CONFIDENTIAL — PARTNER BRIEF", s["cover_kicker"]))
    story.append(
        Paragraph(
            "Prodally Development Proposal:<br/>Strategic Gap Assessment",
            s["cover_title"],
        )
    )
    story.append(
        Paragraph(
            "Comparison of Prodally’s 21-page Mobile &amp; Web App Development Proposal "
            "against the live LingAfriq Flutter production codebase (v1.6.2+330).",
            s["cover_sub"],
        )
    )
    story.append(Paragraph(f"Prepared for LingAfriq partners · {TODAY}", s["small"]))
    story.append(Spacer(1, 8))
    story.append(HRFlowable(width="100%", thickness=0.8, color=RULE, spaceAfter=12))

    story.append(
        metric_row(
            [
                ("32", "Domains compared", "ok"),
                ("11+", "In-app / missing from SOW", "danger"),
                ("₦22M", "Quoted total (excl. VAT/AI)", "warn"),
                ("RN≠Flutter", "Stack mismatch", "danger"),
            ],
            s,
        )
    )
    story.append(Spacer(1, 12))

    story.append(
        callout(
            "Recommendation",
            "Do <b>not</b> accept the Prodally proposal as written. It under-scopes the live product, "
            "prices greenfield work against features already shipping, and uses a Change Request clause "
            "(page 11) that can exclude any screen not explicitly listed. Require a rewritten SOW with "
            "Flutter continuity and a preserve-and-extend Appendix A before any deposit.",
            s,
            "danger",
        )
    )

    story.append(Paragraph("1. Context", s["h1"]))
    story.append(
        Paragraph(
            "Prodally proposes a 22–26 week engagement covering (1) Member Mobile App premium layer, "
            "(2) Community/Content/Offline, and (3) Admin &amp; Content Console, totaling "
            "<b>₦22,000,000</b> (Modules ₦12M / ₦5.5M / ₦4.5M), excluding VAT, hosting, and AI inference. "
            "The proposal references LingAfriq’s Strategic Overview (1 September 2026) and early traction "
            "metrics. Contact: john@prodally.com.",
            s["body"],
        )
    )
    story.append(
        Paragraph(
            "LingAfriq’s production client is a mature <b>Flutter</b> application with ~262 screen files, "
            "a 42-type game catalog, multi-mode Polie AI, LiveKit classrooms, Socket.IO social surfaces, "
            "offline sync, RevenueCat subscriptions, and extensive cultural/heritage modules. "
            "There is no full in-app CMS admin in the Flutter client; admin work is legitimately net-new "
            "if integrated with the existing backend at admin.lingafriq.com.",
            s["body"],
        )
    )

    story.append(Paragraph("2. What is useful in their proposal", s["h1"]))
    story.extend(
        bullets(
            [
                "Correct freemium thesis: premium tools, coaching, community, offline, admin, monetization.",
                "Admin console, institutional licensing, tutor marketplace booking, and revenue/AI-cost dashboards are real business gaps.",
                "Itemized module pricing and optional retainership (₦0.5–1.0M/mo) are commercially readable.",
                "Recognition of AI cost control, dialect scale, and trust &amp; safety as key risks.",
            ],
            s,
        )
    )

    story.append(Paragraph("3. Critical risks", s["h1"]))
    story.append(Paragraph("3.1 Stack mismatch", s["h2"]))
    story.append(
        Paragraph(
            "The commercial offer staffs a <b>Frontend Developer (React Native)</b> against a production "
            "<b>Flutter</b> codebase. That is a rewrite posture, not an extend posture. A dual-client "
            "migration would require a separate multi-phase budget, far beyond ₦22M and 26 weeks.",
            s["body"],
        )
    )
    story.append(Paragraph("3.2 Change Request trap (page 11)", s["h2"]))
    story.append(
        Paragraph(
            "Prodally states that any screen, flow, integration, or feature not explicitly documented—"
            "including AI model selection and telco/CSR partnership integrations—falls outside scope and "
            "requires a formal Change Request. Combined with a thin feature list, this lets large product "
            "pillars (games, personas, Snap/X/WA social, passport) be excluded from “done” while Module 1–2 "
            "fees are still collected for work that overlaps existing capabilities.",
            s["body"],
        )
    )
    story.append(Paragraph("3.3 Rebuild billing risk", s["h2"]))
    story.append(
        Paragraph(
            "Module 1 (₦12M) names translation, pronunciation, Phrase DNA, Living Dictionary, AI coach, "
            "live classrooms, villages/tribes chat, and offline—capabilities that largely already exist. "
            "Without a preserve-and-extend obligation, LingAfriq risks paying greenfield rates for "
            "re-implementation while unprotected surfaces regress or disappear.",
            s["body"],
        )
    )
    story.append(Paragraph("3.4 Scope contradictions", s["h2"]))
    story.append(
        Paragraph(
            "Telco/CSR readiness is marketed in the project overview, then treated as out-of-scope / CR "
            "on page 11. The title says “Web &amp; Mobile,” but learner web is not clearly SOW’d—only a "
            "React Admin console is clearly priced.",
            s["body"],
        )
    )

    story.append(PageBreak())
    story.append(Paragraph("4. Domain coverage matrix", s["h1"]))
    story.append(
        Paragraph(
            "Status key: <b>MISSING</b> = in production app, not protected by SOW · "
            "<b>PARTIAL</b> = vaguely referenced · <b>NAMED</b> = listed but rebuild risk · "
            "<b>NET-NEW</b> = legitimate new work · <b>STACK MISMATCH</b> = Flutter vs React Native.",
            s["small"],
        )
    )
    story.append(Spacer(1, 6))
    story.append(gap_table(s))

    story.append(Paragraph("5. Highest-priority omissions (must attach as Appendix A)", s["h1"]))
    story.extend(
        bullets(
            [
                "<b>Games catalog</b> — 42 registered types including cultural and traditional board/card games.",
                "<b>Polie multi-mode workspace</b> — Tutor / Roleplay / Vocabulary / Review / Translation, not a single “AI chat coach.”",
                "<b>26 historical personas + persona missions</b> with safety and assessment.",
                "<b>Social upgrades</b> — X-style feed, Snap stories, WA status, social audio rooms.",
                "<b>Passport</b> proctored credentials; <b>Point &amp; Say</b> (ML Kit); micro-mentor + staff reports.",
                "<b>Gamification depth</b> — hearts, seasonal events, magic items, ancestral tree, Tribe vs Tribe.",
                "<b>Hardening</b> — Sentry, certificate pinning, sync v2/outbox, African TTS stack.",
            ],
            s,
        )
    )

    story.append(Paragraph("6. Commercial opinion", s["h1"]))
    story.append(
        Paragraph(
            "As priced, Module 1 heavily overlaps shipping capabilities. Module 3 Admin (₦4.5M) is the "
            "clearest net-new value <i>if</i> integrated with the current backend rather than replaced "
            "blindly. The 22–26 week timeline is plausible only for a narrow premium/admin slice—not for "
            "owning the full current product surface. Retainership form is reasonable; it does not fix an "
            "under-scoped build contract.",
            s["body"],
        )
    )

    story.append(Paragraph("7. Recommended partner actions", s["h1"]))
    story.extend(
        bullets(
            [
                "Reject acceptance of the PDF as the binding SOW.",
                "Issue a counter-package: Flutter continuity mandate + Appendix A inventory + acceptance matrix.",
                "Reprice as three workstreams: (A) harden/extend existing Flutter mobile, (B) admin console upgrade, (C) net-new marketplace/licensing.",
                "Require Prodally to demonstrate fluency in the current repository before kickoff payment.",
                "If they insist on React Native or refuse Appendix A: confine engagement to Admin-only, or decline.",
            ],
            s,
        )
    )

    story.append(Spacer(1, 14))
    story.append(HRFlowable(width="100%", thickness=0.6, color=RULE, spaceAfter=8))
    story.append(
        Paragraph(
            "Reference sources: Prodally “LingAfriq Development Proposal.pdf” (21 pages) · "
            "codebase routes (lib/my_app.dart) · game_catalog.dart · features_guide_screen.dart · pubspec.yaml · "
            "app version 1.6.2+330.",
            s["small"],
        )
    )

    doc.build(story, onFirstPage=footer_factory("LingAfriq · Confidential Partner Brief"), onLaterPages=footer_factory("LingAfriq · Confidential Partner Brief"))


def build_prodally_pdf(path: Path):
    s = styles()
    doc = SimpleDocTemplate(
        str(path),
        pagesize=A4,
        leftMargin=MARGIN,
        rightMargin=MARGIN,
        topMargin=16 * mm,
        bottomMargin=18 * mm,
        title="LingAfriq Response to Prodally Development Proposal",
        author="LingAfriq",
    )
    story = []

    story.append(ColorBand(5, ACCENT))
    story.append(Spacer(1, 10))
    story.append(Paragraph("FORMAL RESPONSE", s["cover_kicker"]))
    story.append(
        Paragraph(
            "Response to Prodally<br/>Development Proposal",
            s["cover_title"],
        )
    )
    story.append(
        Paragraph(
            "Required SOW amendments, technology constraints, and Appendix A — "
            "Current Product Surface (preserve-and-extend).",
            s["cover_sub"],
        )
    )
    story.append(Spacer(1, 6))

    meta = [
        Paragraph(f"<b>Date:</b> {TODAY}", s["letter_meta"]),
        Paragraph("<b>To:</b> Prodally Technologies (john@prodally.com)", s["letter_meta"]),
        Paragraph("<b>From:</b> LingAfriq", s["letter_meta"]),
        Paragraph(
            "<b>Re:</b> Mobile &amp; Web App Development Proposal — scope alignment before engagement",
            s["letter_meta"],
        ),
        Paragraph(
            "<b>Ref:</b> Proposal received September 2026 · LingAfriq production app v1.6.2+330 (Flutter)",
            s["letter_meta"],
        ),
    ]
    for m in meta:
        story.append(m)
    story.append(Spacer(1, 8))
    story.append(HRFlowable(width="100%", thickness=0.8, color=RULE, spaceAfter=10))

    story.append(Paragraph("Dear Prodally team,", s["body_left"]))
    story.append(
        Paragraph(
            "Thank you for the Development Proposal and for engaging with LingAfriq’s strategic direction. "
            "We appreciate the clarity of your module pricing and the focus on freemium conversion, "
            "community retention, and an admin/monetization layer.",
            s["body"],
        )
    )
    story.append(
        Paragraph(
            "Before we can proceed to kickoff or deposit, we must align the Statement of Work with the "
            "<b>existing production codebase</b>. LingAfriq already operates a substantial Flutter "
            "application. Several items priced in Modules 1 and 2 are already implemented in whole or in "
            "part. Equally, major live product surfaces are not named in the proposal and would fall "
            "outside scope under page 11 as currently written.",
            s["body"],
        )
    )
    story.append(
        callout(
            "Position",
            "We are not accepting the proposal PDF as the binding SOW in its current form. "
            "We invite a revised proposal that adopts the mandatory conditions and Appendix A below. "
            "We remain open to collaborating—particularly on Admin Console, institutional licensing, "
            "and true net-new marketplace capabilities—on terms that protect continuity of the live product.",
            s,
            "warn",
        )
    )

    story.append(Paragraph("1. Mandatory conditions for a revised SOW", s["h1"]))

    story.append(Paragraph("1.1 Technology continuity — Flutter", s["h2"]))
    story.append(
        Paragraph(
            "The member mobile application must be extended in the <b>existing Flutter repository</b>. "
            "The proposal’s staffing of React Native is not acceptable for the production member app. "
            "Any React Native or separate-client rewrite would require an explicitly separate engagement, "
            "migration plan, dual-running strategy, and budget. Admin Console work in React is acceptable "
            "for the web console only.",
            s["body"],
        )
    )

    story.append(Paragraph("1.2 Preserve-and-extend obligation", s["h2"]))
    story.append(
        Paragraph(
            "Replace the page-11 formulation that excludes unlisted screens by default. The revised SOW "
            "must state that Vendor shall <b>preserve and extend all Appendix A features</b> unless "
            "LingAfriq explicitly defers a feature in writing. Deferred items may be scheduled later; "
            "undeclared omissions are not an acceptable definition of done.",
            s["body"],
        )
    )

    story.append(Paragraph("1.3 No silent rebuild billing", s["h2"]))
    story.append(
        Paragraph(
            "Where Module 1/2 line items overlap existing capabilities (translation, pronunciation, "
            "dictionary/Phrase DNA, AI coaching, live classroom, villages/tribes chat, offline, UGC, "
            "retention), the SOW must describe work as <b>audit, harden, upgrade, and integrate</b>—not "
            "as greenfield invention—unless LingAfriq authorizes a rewrite of a specific subsystem.",
            s["body"],
        )
    )

    story.append(Paragraph("1.4 Acceptance criteria", s["h2"]))
    story.append(
        Paragraph(
            "Delivery acceptance must include regression verification against:",
            s["body"],
        )
    )
    story.extend(
        bullets(
            [
                "Named routes and primary drawer destinations in the Flutter app",
                "All entries in the games catalog (currently 42 types)",
                "Polie mode surfaces and LiveKit classroom/practice flows",
                "Existing chat/social entry points listed in Appendix A",
                "Offline download/sync paths, RevenueCat subscription surfaces, and monitoring/security hooks already present",
            ],
            s,
        )
    )

    story.append(Paragraph("1.5 Clarify contradictions", s["h2"]))
    story.extend(
        bullets(
            [
                "<b>Telco/CSR:</b> either include with priced milestones or explicitly remove from marketing/overview language.",
                "<b>Learner Web App:</b> confirm in or out. Today only the Admin React console is clearly scoped.",
                "<b>Human tutor marketplace:</b> treat as net-new; define API contracts against existing backend.",
                "<b>AI vendors:</b> integration role is fine; model selection remains LingAfriq-owned as you noted—ensure this does not zero out existing hybrid provider wiring without approval.",
            ],
            s,
        )
    )

    story.append(Paragraph("2. Preferred commercial structure", s["h1"]))
    story.append(
        Paragraph(
            "Please reprice and rephase as three explicit workstreams:",
            s["body"],
        )
    )
    story.extend(
        bullets(
            [
                "<b>Workstream A — Flutter mobile continuity:</b> harden and extend Appendix A surfaces; premium packaging/paywalls; quality/regression.",
                "<b>Workstream B — Admin &amp; Content Console:</b> curriculum ops, moderation, RBAC, subscription/revenue/AI-cost dashboards, integrated with admin.lingafriq.com / existing APIs.",
                "<b>Workstream C — Net-new growth:</b> tutor/immersion marketplace booking, institutional licensing, and any agreed distribution integrations.",
            ],
            s,
        )
    )
    story.append(
        Paragraph(
            "We welcome revised timelines and fees under this structure. Optional retainership may be "
            "discussed after a successful delivery definition is agreed.",
            s["body"],
        )
    )

    story.append(Paragraph("3. Immediate next steps requested", s["h1"]))
    story.extend(
        bullets(
            [
                "Written acknowledgement of Flutter continuity for the member app.",
                "Revised SOW incorporating Sections 1–2 and Appendix A.",
                "Updated pricing by workstream (A/B/C), with clear “extend existing” vs “net-new” labels.",
                "Short technical walkthrough demonstrating familiarity with the current Flutter repository and backend contracts.",
                "Confirmation of staging/production GitHub CI practices compatible with our existing pipelines.",
            ],
            s,
        )
    )
    story.append(
        Paragraph(
            "We value the dialogue and hope to find a path that strengthens monetization and operations "
            "without discarding the product surface our users already depend on.",
            s["body"],
        )
    )
    story.append(Paragraph("Sincerely,", s["body_left"]))
    story.append(Spacer(1, 10))
    story.append(Paragraph("<b>LingAfriq</b>", s["body_left"]))
    story.append(Paragraph("Product &amp; Engineering", s["small"]))

    story.append(PageBreak())
    story.append(ColorBand(4, ACCENT))
    story.append(Spacer(1, 8))
    story.append(Paragraph("APPENDIX A", s["cover_kicker"]))
    story.append(
        Paragraph(
            "Current Product Surface<br/>(Preserve-and-Extend)",
            s["cover_title"],
        )
    )
    story.append(
        Paragraph(
            "This Appendix forms part of any revised SOW. Features below exist in the LingAfriq "
            "production Flutter application and related services unless marked NET-NEW. Vendor must "
            "preserve behavior and extend quality unless LingAfriq defers an item in writing.",
            s["cover_sub"],
        )
    )
    story.append(Spacer(1, 6))
    story.append(gap_table(s))

    story.append(Paragraph("Appendix A — Non-exhaustive feature clusters", s["h1"]))
    story.append(
        Paragraph(
            "The matrix above is the coverage control list. For avoidance of doubt, the following "
            "clusters are in production and must not be silently dropped:",
            s["body"],
        )
    )
    clusters = [
        (
            "Learning &amp; curriculum",
            "Onboarding/placement; home/courses; lessons map; Authentic Path; grammar/vocab/listening/writing; "
            "conversation scenarios; speak missions; spaced repetition; dialect preference; certificates.",
        ),
        (
            "Polie &amp; AI",
            "Mode selection and workspace (Translation, Tutor, Roleplay, Vocabulary, Review); tutor sub-modes; "
            "hybrid orchestration; live translate; offline translation; historical personas and persona missions.",
        ),
        (
            "Voice &amp; pronunciation",
            "African TTS; STT; pronunciation scoring; tone drills/error detection; synthetic voice styles; "
            "voice contribution; game ASR scoring.",
        ),
        (
            "Games",
            "Full catalog of forty-two (42) game types spanning skill, cultural, and traditional board/card "
            "experiences, plus catalog/router/results infrastructure.",
        ),
        (
            "Gamification",
            "Hearts; daily goals/challenges; XP/streaks/badges; quests; seasonal events; magic items; "
            "ancestral tree; leaderboards/standings; tribe competitions.",
        ),
        (
            "Villages, tribes, classroom",
            "Villages hub and location scenes; tribe membership/discovery; Tribe vs Tribe; LiveKit live "
            "classroom and practice rooms.",
        ),
        (
            "Social &amp; chat",
            "Global/community/tribe chat; private messaging; call history; X-style feed; Snap flows; "
            "WA status; social audio; micro-mentor; moderation tools.",
        ),
        (
            "Content &amp; culture",
            "Offline packs/sync; UGC; imported media; native content review; culture magazine; FLB heritage; "
            "Point &amp; Say; passport credentials.",
        ),
        (
            "Account, payments, platform",
            "Auth/profile/settings/biometrics; RevenueCat subscriptions and family dashboard; Firebase "
            "notifications; Sentry; certificate pinning; deep links; localization.",
        ),
        (
            "Net-new (welcome if properly priced)",
            "Full Admin &amp; Content Console; institutional licensing; tutor/immersion marketplace booking "
            "and commission tracking; agreed distribution/telco integrations if explicitly included.",
        ),
    ]
    for title, body in clusters:
        story.append(Paragraph(f"<b>{title}.</b> {body}", s["body"]))

    story.append(Spacer(1, 8))
    story.append(
        callout(
            "Appendix control statement",
            "If a feature exists in the production app and is not explicitly deferred by LingAfriq in "
            "writing, it remains in scope for preserve-and-extend. Discovery may refine UX, but may not "
            "remove product pillars without written approval.",
            s,
            "info",
        )
    )
    story.append(Spacer(1, 10))
    story.append(
        Paragraph(
            "Reference anchors for technical acceptance: lib/my_app.dart · "
            "lib/screens/games/game_catalog.dart · lib/screens/tabs_view/app_drawer/ · "
            "lib/screens/help/features_guide_screen.dart · pubspec.yaml · backend base admin.lingafriq.com.",
            s["small"],
        )
    )

    doc.build(
        story,
        onFirstPage=footer_factory("LingAfriq · Formal Response to Prodally"),
        onLaterPages=footer_factory("LingAfriq · Formal Response to Prodally · Appendix A"),
    )


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    DOWNLOADS.mkdir(parents=True, exist_ok=True)

    partner = OUT_DIR / "LingAfriq_Partner_Brief_Prodally_Proposal_Assessment.pdf"
    prodally = OUT_DIR / "LingAfriq_Formal_Response_to_Prodally.pdf"

    build_partner_pdf(partner)
    build_prodally_pdf(prodally)

    # Mirror to Downloads for easy sharing
    partner_dl = DOWNLOADS / partner.name
    prodally_dl = DOWNLOADS / prodally.name
    partner_dl.write_bytes(partner.read_bytes())
    prodally_dl.write_bytes(prodally.read_bytes())

    print(f"PARTNER={partner}")
    print(f"PRODALLY={prodally}")
    print(f"DOWNLOADS={DOWNLOADS}")
    print(f"sizes partner={partner.stat().st_size} prodally={prodally.stat().st_size}")


if __name__ == "__main__":
    main()
