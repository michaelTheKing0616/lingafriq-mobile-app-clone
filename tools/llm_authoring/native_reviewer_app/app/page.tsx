async function fetchQueue() {
  const base = process.env.NEXT_PUBLIC_APP_URL ?? "http://127.0.0.1:3100";
  const res = await fetch(`${base}/api/queue?status=pending_review`, {
    cache: "no-store",
    headers: process.env.REVIEWER_API_TOKEN
      ? { Authorization: `Bearer ${process.env.REVIEWER_API_TOKEN}` }
      : {},
  });
  if (!res.ok) {
    return { items: [], error: await res.text() };
  }
  return res.json();
}

export default async function QueuePage() {
  const data = await fetchQueue();
  const items: Array<{
    draftId: string;
    kind: string;
    lang: string;
    level: string;
    status: string;
    updatedAt: string;
  }> = data.items ?? [];

  return (
    <div>
      <h1>Reviewer queue</h1>
      <p className="muted">
        Pending native review for curriculum lessons and game content batches.
      </p>
      {data.error && (
        <p style={{ color: "var(--danger)" }}>Failed to load queue: {data.error}</p>
      )}
      {items.length === 0 && !data.error && (
        <p className="muted">No drafts awaiting review.</p>
      )}
      {items.map((item) => (
        <div className="card" key={item.draftId}>
          <div className="row">
            <strong>{item.kind}</strong>
            <span>
              {item.lang} · {item.level}
            </span>
            <span className="muted">{item.updatedAt}</span>
          </div>
          <p>
            <a href={`/review/${encodeURIComponent(item.draftId)}`}>
              Open draft →
            </a>
          </p>
        </div>
      ))}
    </div>
  );
}
