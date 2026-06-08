import { NextRequest, NextResponse } from "next/server";
import { draftsCollection } from "@/lib/mongodb";
import { assertReviewerAuth } from "@/lib/auth";

export async function GET(req: NextRequest) {
  try {
    assertReviewerAuth(req);
    const { searchParams } = new URL(req.url);
    const lang = searchParams.get("lang");
    const level = searchParams.get("level");
    const status = searchParams.get("status") ?? "pending_review";

    const filter: Record<string, string> = { status };
    if (lang) filter.lang = lang;
    if (level) filter.level = level;

    const col = await draftsCollection();
    const items = await col
      .find(filter)
      .sort({ updatedAt: -1 })
      .limit(200)
      .toArray();

    return NextResponse.json({ items });
  } catch (e) {
    const message = e instanceof Error ? e.message : "error";
    const status = message === "unauthorized" ? 401 : 500;
    return NextResponse.json({ error: message }, { status });
  }
}

export async function POST(req: NextRequest) {
  try {
    assertReviewerAuth(req);
    const body = await req.json();
    const now = new Date().toISOString();
    const doc = {
      draftId: String(body.draftId),
      kind: body.kind === "games" ? "games" : "curriculum",
      lang: String(body.lang).toLowerCase(),
      level: String(body.level),
      status: "pending_review" as const,
      payload: body.payload ?? {},
      sourcePath: String(body.sourcePath ?? ""),
      createdAt: now,
      updatedAt: now,
    };
    const col = await draftsCollection();
    await col.updateOne(
      { draftId: doc.draftId },
      { $set: doc },
      { upsert: true },
    );
    return NextResponse.json({ ok: true, draftId: doc.draftId });
  } catch (e) {
    const message = e instanceof Error ? e.message : "error";
    const status = message === "unauthorized" ? 401 : 500;
    return NextResponse.json({ error: message }, { status });
  }
}
