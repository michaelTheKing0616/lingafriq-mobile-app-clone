import React, { useState } from "react";
import axios from "axios";

type ComposerProps = {
  chatId: string;
  currentUser: string;
  onSent?: (msg: any) => void;
};

export default function Composer({ chatId, currentUser, onSent }: ComposerProps) {
  const [text, setText] = useState("");
  const [lang, setLang] = useState("yoruba");
  const [sending, setSending] = useState(false);

  async function send() {
    if (!text.trim()) return;
    setSending(true);
    try {
      const payload = { sender: currentUser, body: text, lang };
      const res = await axios.post(`http://localhost:8000/chats/${chatId}/send`, payload);
      setText("");
      onSent && onSent(res.data);
    } catch (err: any) {
      console.error("Send failed", err);
      const errorMsg = err?.response?.data?.detail || err.message || "Failed to send message";
      alert(errorMsg);
    } finally {
      setSending(false);
    }
  }

  return (
    <div style={{ display: "flex", gap: 8, marginTop: 8 }}>
      <select value={lang} onChange={(e) => setLang(e.target.value)}>
        <option value="yoruba">Yoruba</option>
        <option value="swahili">Swahili</option>
      </select>
      <input
        value={text}
        onChange={(e) => setText(e.target.value)}
        placeholder="Type a message"
        style={{ flex: 1, padding: 8, borderRadius: 8 }}
        onKeyPress={(e) => e.key === "Enter" && send()}
      />
      <button onClick={send} disabled={sending} style={{ padding: "8px 12px" }}>
        {sending ? "Sending…" : "Send"}
      </button>
    </div>
  );
}
