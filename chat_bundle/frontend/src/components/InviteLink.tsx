import React, { useState } from "react";
import axios from "axios";
import QRCode from "qrcode.react";

type InviteCreatePayload = {
  created_by: string;
  purpose?: string;
  scope?: string[];
  uses?: number;
  expires_in_minutes?: number;
};

export default function InviteLink({ currentUser }: { currentUser: string }) {
  const [link, setLink] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function createInvite() {
    setLoading(true);
    setError(null);
    try {
      const payload: InviteCreatePayload = {
        created_by: currentUser,
        purpose: "add_contact",
        scope: ["add_contact"],
        uses: 1,
        expires_in_minutes: 60
      };
      const res = await axios.post("http://localhost:8000/invites/create", payload);
      const inviteLink = res.data.link;
      setLink(inviteLink);
    } catch (err: any) {
      setError(err?.response?.data?.detail || err.message || "Failed to create invite");
    } finally {
      setLoading(false);
    }
  }

  function copyToClipboard() {
    if (!link) return;
    navigator.clipboard.writeText(link).then(() => alert("Link copied to clipboard!"));
  }

  return (
    <div style={{ border: '1px solid #eee', padding: 12, borderRadius: 8, maxWidth: 420 }}>
      <h4>Create a connection invite</h4>
      <p>Generate a single-use invite link or QR code to add you as a contact.</p>
      <div style={{ display: 'flex', gap: 8, marginBottom: 8 }}>
        <button onClick={createInvite} disabled={loading}>
          {loading ? 'Creating…' : 'Create Invite'}
        </button>
        <button onClick={() => { setLink(null); setError(null); }}>Reset</button>
      </div>
      {error && <div style={{ color: 'crimson' }}>{error}</div>}
      {link && (
        <div>
          <label style={{ fontSize: 12 }}>Invite link (share on WhatsApp, email, etc.)</label>
          <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginTop: 6 }}>
            <input
              readOnly
              value={link}
              style={{ flex: 1, padding: 8, borderRadius: 6, border: '1px solid #ddd' }}
            />
            <button onClick={copyToClipboard}>Copy</button>
          </div>
          <div style={{ marginTop: 10, display: 'flex', gap: 12, alignItems: 'center' }}>
            <div>
              <QRCode value={link} size={110} />
              <div style={{ fontSize: 12, color: '#666', marginTop: 6 }}>Scan to accept</div>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13 }}>Invite details:</div>
              <ul style={{ marginTop: 6 }}>
                <li>Purpose: Add contact</li>
                <li>Uses: 1</li>
                <li>Expires: 60 minutes</li>
              </ul>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

