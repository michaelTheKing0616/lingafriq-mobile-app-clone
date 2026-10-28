/**
 * P9-952 — teacher web dashboard (Google Classroom–style class list + roster import).
 * Mount from Flutter web or staff shell; auth token via session cookie / Bearer.
 */
import React, { useCallback, useEffect, useState } from 'react';

type ClassroomSummary = {
  id: string;
  name: string;
  language_tag: string;
  classroom_code: string | null;
  organisation_type: 'independent' | 'school' | 'congregation';
  members_count: number;
};

type ImportError = { lineNumber: number; reason: string };

const API_BASE = (typeof window !== 'undefined' && (window as { __LINGAFRIQ_API__?: string }).__LINGAFRIQ_API__) || '';

async function apiFetch(path: string, init?: RequestInit) {
  const res = await fetch(`${API_BASE}${path}`, {
    credentials: 'include',
    headers: { 'Content-Type': 'application/json', ...(init?.headers ?? {}) },
    ...init,
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(json.error ?? `Request failed (${res.status})`);
  return json;
}

export function TeacherDashboard(): React.ReactElement {
  const [classrooms, setClassrooms] = useState<ClassroomSummary[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [importing, setImporting] = useState(false);
  const [parseErrors, setParseErrors] = useState<ImportError[]>([]);
  const [importMessage, setImportMessage] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await apiFetch('/api/v2/classroom/teacher/classrooms');
      const list: ClassroomSummary[] = data.classrooms ?? [];
      setClassrooms(list);
      if (list.length > 0 && !selectedId) setSelectedId(list[0].id);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not load your classes');
    } finally {
      setLoading(false);
    }
  }, [selectedId]);

  useEffect(() => {
    void load();
  }, [load]);

  const onImportFile = async (file: File) => {
    if (!selectedId) return;
    setImporting(true);
    setParseErrors([]);
    setImportMessage(null);
    try {
      const csv = await file.text();
      const data = await apiFetch(`/api/v2/classroom/${encodeURIComponent(selectedId)}/roster/import`, {
        method: 'POST',
        body: JSON.stringify({ csv }),
      });
      setParseErrors(data.parseErrors ?? []);
      const okCount = (data.imported ?? []).filter((r: { ok: boolean }) => r.ok).length;
      const failCount = (data.imported ?? []).filter((r: { ok: boolean }) => !r.ok).length;
      setImportMessage(`Added ${okCount} learners${failCount ? `, ${failCount} need attention` : ''}.`);
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Import failed');
    } finally {
      setImporting(false);
    }
  };

  const selected = classrooms.find((c) => c.id === selectedId);

  return (
    <main
      style={{
        fontFamily: 'system-ui, sans-serif',
        maxWidth: 960,
        margin: '0 auto',
        padding: 24,
        color: '#1a1a1a',
      }}
    >
      <header style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 28, fontWeight: 700, margin: 0 }}>Your classes</h1>
        <p style={{ marginTop: 8, color: '#444' }}>
          Manage rosters and invite learners. Only classes you teach appear here.
        </p>
      </header>

      {loading && <p role="status">Loading classes…</p>}
      {error && (
        <p role="alert" style={{ color: '#b00020' }}>
          {error}
        </p>
      )}

      {!loading && classrooms.length === 0 && (
        <p>No classes yet. Create one from the LingAfriq app to get started.</p>
      )}

      {classrooms.length > 0 && (
        <section aria-label="Class list" style={{ display: 'grid', gap: 16 }}>
          <label htmlFor="class-select" style={{ fontWeight: 600 }}>
            Class
          </label>
          <select
            id="class-select"
            value={selectedId ?? ''}
            onChange={(e) => setSelectedId(e.target.value)}
            style={{ minHeight: 48, fontSize: 16, padding: '8px 12px' }}
          >
            {classrooms.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name} ({c.language_tag}) — {c.organisation_type}
              </option>
            ))}
          </select>

          {selected && (
            <article
              style={{
                border: '1px solid #e0e0e0',
                borderRadius: 12,
                padding: 20,
                background: '#fafafa',
              }}
            >
              <h2 style={{ marginTop: 0, fontSize: 20 }}>{selected.name}</h2>
              <p style={{ margin: '4px 0' }}>
                Join code: <strong>{selected.classroom_code ?? '—'}</strong>
              </p>
              <p style={{ margin: '4px 0' }}>Learners enrolled: {selected.members_count}</p>

              <div style={{ marginTop: 20 }}>
                <label htmlFor="roster-csv" style={{ display: 'block', fontWeight: 600, marginBottom: 8 }}>
                  Import roster (CSV)
                </label>
                <input
                  id="roster-csv"
                  type="file"
                  accept=".csv,text/csv"
                  disabled={importing}
                  onChange={(e) => {
                    const f = e.target.files?.[0];
                    if (f) void onImportFile(f);
                  }}
                  style={{ minHeight: 48 }}
                />
                <p style={{ fontSize: 14, color: '#555', marginTop: 8 }}>
                  Columns: student_local_id, first_name, birth_year, last_name (optional), email (optional). Under-18
                  accounts stay pending until school or guardian consent.
                </p>
              </div>

              {importMessage && (
                <p role="status" style={{ color: '#0d6b3a', marginTop: 12 }}>
                  {importMessage}
                </p>
              )}
              {parseErrors.length > 0 && (
                <ul role="alert" style={{ color: '#b00020', marginTop: 12 }}>
                  {parseErrors.map((err) => (
                    <li key={`${err.lineNumber}-${err.reason}`}>
                      Line {err.lineNumber}: {err.reason}
                    </li>
                  ))}
                </ul>
              )}
            </article>
          )}
        </section>
      )}
    </main>
  );
}

export default TeacherDashboard;
