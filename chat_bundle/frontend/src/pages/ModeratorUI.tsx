import React, { useEffect, useState } from "react";
import axios from "axios";

export default function ModeratorUI() {
  const [queue, setQueue] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  async function load() {
    setLoading(true);
    try {
      const r = await axios.get("http://localhost:8000/moderation/queue");
      setQueue(r.data.items || []);
    } catch (err) {
      console.error("Failed to load queue", err);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
    const interval = setInterval(load, 5000); // Refresh every 5 seconds
    return () => clearInterval(interval);
  }, []);

  async function applyDecision(message_id: string, action: string) {
    try {
      await axios.post("http://localhost:8000/moderation/decide", { message_id, action });
      load();
    } catch (err) {
      console.error("Failed to apply decision", err);
      alert("Failed to apply decision");
    }
  }

  return (
    <div style={{ padding: 12 }}>
      <h2>Moderator Queue</h2>
      <div>Pending: {queue.length}</div>
      <button onClick={load} disabled={loading} style={{ marginTop: 8 }}>
        {loading ? "Loading…" : "Refresh"}
      </button>
      <div style={{ marginTop: 10 }}>
        {queue.length === 0 ? (
          <div style={{ color: "#666", fontStyle: "italic" }}>No items in queue</div>
        ) : (
          queue.map((item) => (
            <div
              key={item.message_id}
              style={{
                border: "1px solid #ddd",
                padding: 10,
                marginBottom: 8,
                borderRadius: 6,
                backgroundColor: item.score >= 0.7 ? "#ffe6e6" : "#fff9e6"
              }}
            >
              <div style={{ fontWeight: 600 }}>
                {item.sender} • score: {item.score.toFixed(2)} • action: {item.action}
              </div>
              <div style={{ marginTop: 6, padding: 8, backgroundColor: "#f5f5f5", borderRadius: 4 }}>
                {item.text}
              </div>
              <div style={{ marginTop: 8, display: "flex", gap: 8 }}>
                <button onClick={() => applyDecision(item.message_id, "approve")}>Approve</button>
                <button onClick={() => applyDecision(item.message_id, "remove")}>Remove</button>
                <button onClick={() => applyDecision(item.message_id, "block")}>Block</button>
              </div>
              <div style={{ fontSize: 12, color: "#666", marginTop: 6 }}>
                Reasons: {JSON.stringify(item.reasons)}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

