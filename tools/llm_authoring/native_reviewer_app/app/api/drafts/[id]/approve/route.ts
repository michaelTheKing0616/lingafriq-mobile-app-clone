import { NextRequest, NextResponse } from "next/server";
import { draftsCollection } from "@/lib/mongodb";
import { assertReviewerAuth } from "@/lib/auth";
import fs from "fs/promises";
import path from "path";

type Params = { params: Promise<{ id: string }> };

export async function POST(req: NextRequest, { params }: Params) {
  try {
    assertReviewerAuth(req);
    const { id } = await params;
    const body = await req.json();
    const reviewer = String(body.reviewer ?? "native_reviewer");
    const col = await draftsCollection();
    const doc = await col.findOne({ draftId: id });
    if (!doc) {
      return NextResponse.json({ error: "not_found" }, { status: 404 });
    }

    const approvedPayload = {
      ...doc.payload,
      review_status: "approved",
      reviewed_by: reviewer,
      reviewed_at: new Date().toISOString(),
    };

    if (doc.sourcePath) {
      const root = path.resolve(process.cwd(), "..", "..");
      const target = path.isAbsolute(doc.sourcePath)
        ? doc.sourcePath
        : path.join(root, doc.sourcePath);
      await fs.mkdir(path.dirname(target), { recursive: true });
      await fs.writeFile(
        target,
        JSON.stringify(approvedPayload, null, 2) + "\n",
        "utf-8",
      );
    }

    await col.updateOne(
      { draftId: id },
      {
        $set: {
          status: "approved",
          payload: approvedPayload,
          reviewer,
          updatedAt: new Date().toISOString(),
        },
      },
    );

    return NextResponse.json({ ok: true, draftId: id, status: "approved" });
  } catch (e) {
    const message = e instanceof Error ? e.message : "error";
    const status = message === "unauthorized" ? 401 : 500;
    return NextResponse.json({ error: message }, { status });
  }
}
