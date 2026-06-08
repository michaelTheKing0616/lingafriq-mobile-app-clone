import { NextRequest, NextResponse } from "next/server";
import { draftsCollection } from "@/lib/mongodb";
import { assertReviewerAuth } from "@/lib/auth";

type Params = { params: Promise<{ id: string }> };

export async function GET(req: NextRequest, { params }: Params) {
  try {
    assertReviewerAuth(req);
    const { id } = await params;
    const col = await draftsCollection();
    const doc = await col.findOne({ draftId: id });
    if (!doc) {
      return NextResponse.json({ error: "not_found" }, { status: 404 });
    }
    return NextResponse.json(doc);
  } catch (e) {
    const message = e instanceof Error ? e.message : "error";
    const status = message === "unauthorized" ? 401 : 500;
    return NextResponse.json({ error: message }, { status });
  }
}

export async function PATCH(req: NextRequest, { params }: Params) {
  try {
    assertReviewerAuth(req);
    const { id } = await params;
    const body = await req.json();
    const col = await draftsCollection();
    const update: Record<string, unknown> = {
      updatedAt: new Date().toISOString(),
    };
    if (body.payload) update.payload = body.payload;
    if (body.reviewerNotes !== undefined) update.reviewerNotes = body.reviewerNotes;
    if (body.reviewer) update.reviewer = body.reviewer;
    if (body.status) update.status = body.status;

    const result = await col.findOneAndUpdate(
      { draftId: id },
      { $set: update },
      { returnDocument: "after" },
    );
    if (!result) {
      return NextResponse.json({ error: "not_found" }, { status: 404 });
    }
    return NextResponse.json(result);
  } catch (e) {
    const message = e instanceof Error ? e.message : "error";
    const status = message === "unauthorized" ? 401 : 500;
    return NextResponse.json({ error: message }, { status });
  }
}
