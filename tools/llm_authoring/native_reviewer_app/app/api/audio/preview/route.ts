import { NextRequest, NextResponse } from "next/server";
import { assertReviewerAuth } from "@/lib/auth";

export async function POST(req: NextRequest) {
  try {
    assertReviewerAuth(req);
    const body = await req.json();
    const text = String(body.text ?? "").trim();
    const language = String(body.language ?? "yoruba");
    if (!text) {
      return NextResponse.json({ error: "text required" }, { status: 400 });
    }

    const base = (process.env.TTS_PREVIEW_URL ?? "http://127.0.0.1:8080/v1/synthesize").replace(
      /\/+$/,
      "",
    );
    const token = process.env.TTS_INTERNAL_TOKEN?.trim();
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
    };
    if (token) headers.Authorization = `Bearer ${token}`;

    const upstream = await fetch(base, {
      method: "POST",
      headers,
      body: JSON.stringify({ text, language, speed: 1.0 }),
    });

    if (!upstream.ok) {
      const errText = await upstream.text();
      return NextResponse.json(
        { error: "tts_failed", detail: errText },
        { status: upstream.status },
      );
    }

    const audio = await upstream.arrayBuffer();
    return new NextResponse(audio, {
      status: 200,
      headers: { "Content-Type": "audio/wav" },
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : "error";
    const status = message === "unauthorized" ? 401 : 500;
    return NextResponse.json({ error: message }, { status });
  }
}
