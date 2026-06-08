"use client";

import { useParams } from "next/navigation";
import { useEffect, useState } from "react";

type Draft = {
  draftId: string;
  kind: string;
  lang: string;
  level: string;
  status: string;
  payload: Record<string, unknown>;
  reviewerNotes?: string;
};

export default function ReviewPage() {
  const routeParams = useParams<{ id: string }>();
  const draftId = decodeURIComponent(routeParams.id ?? "");
  const [draft, setDraft] = useState<Draft | null>(null);
  const [jsonText, setJsonText] = useState("");
  const [notes, setNotes] = useState("");
  const [message, setMessage] = useState("");
  const [audioUrl, setAudioUrl] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      const res = await fetch(`/api/drafts/${encodeURIComponent(draftId)}`);
      if (!res.ok) {
        setMessage("Failed to load draft");
        return;
      }
      const data = (await res.json()) as Draft;
      setDraft(data);
      setJsonText(JSON.stringify(data.payload, null, 2));
      setNotes(data.reviewerNotes ?? "");
    })();
  }, [draftId]);

  async function saveDraft() {
    let payload: Record<string, unknown>;
    try {
      payload = JSON.parse(jsonText);
    } catch {
      setMessage("Invalid JSON");
      return;
    }
    const res = await fetch(`/api/drafts/${encodeURIComponent(draftId)}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ payload, reviewerNotes: notes }),
    });
    setMessage(res.ok ? "Saved edits" : "Save failed");
    if (res.ok) {
      const data = (await res.json()) as Draft;
      setDraft(data);
    }
  }

  async function approve() {
    const res = await fetch(
      `/api/drafts/${encodeURIComponent(draftId)}/approve`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ reviewer: "native_reviewer" }),
      },
    );
    setMessage(res.ok ? "Approved — ready for publish_bundle.py" : "Approve failed");
  }

  async function previewAudio() {
    if (!draft) return;
    const sample =
      (draft.payload.title as string) ||
      ((draft.payload.vocab as Array<{ word: string }>)?.[0]?.word ?? "");
    if (!sample) {
      setMessage("No text available for audio preview");
      return;
    }
    const res = await fetch("/api/audio/preview", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text: sample, language: draft.lang }),
    });
    if (!res.ok) {
      setMessage("TTS preview failed");
      return;
    }
    const blob = await res.blob();
    if (audioUrl) URL.revokeObjectURL(audioUrl);
    setAudioUrl(URL.createObjectURL(blob));
  }

  if (!draft) {
    return <p className="muted">Loading…</p>;
  }

  return (
    <div>
      <h1>
        {draft.kind} · {draft.lang} {draft.level}
      </h1>
      <p className="muted">Draft ID: {draft.draftId}</p>
      <div className="row" style={{ marginBottom: "1rem" }}>
        <button className="btn" type="button" onClick={saveDraft}>
          Save edits
        </button>
        <button className="btn secondary" type="button" onClick={approve}>
          Approve
        </button>
        <button className="btn secondary" type="button" onClick={previewAudio}>
          Preview TTS
        </button>
      </div>
      {audioUrl && <audio controls src={audioUrl} style={{ width: "100%" }} />}
      {message && <p>{message}</p>}
      <label>
        <span>Reviewer notes</span>
        <textarea
          rows={3}
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
        />
      </label>
      <label>
        <span>Payload JSON</span>
        <textarea
          rows={24}
          value={jsonText}
          onChange={(e) => setJsonText(e.target.value)}
          style={{ fontFamily: "monospace", marginTop: "0.5rem" }}
        />
      </label>
    </div>
  );
}
