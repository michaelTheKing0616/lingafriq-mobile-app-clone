/**
 * P9-953 — teacher assignment console (Google Classroom assignments + can-do progress).
 */
import React, { useCallback, useEffect, useState } from 'react';

type CanDoProgressRow = {
  canDoId: string;
  statementEn: string;
  metCount: number;
  notMetCount: number;
  unsureCount: number;
  studentCount: number;
};

type AssignmentRow = {
  id: string;
  title: string;
  dueAt: string | null;
  publishStatus: string;
  type: string;
};

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

export function TeacherAssignmentsPanel(props: {
  classroomId: string;
  classroomName: string;
}): React.ReactElement {
  const { classroomId, classroomName } = props;
  const [assignments, setAssignments] = useState<AssignmentRow[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [progress, setProgress] = useState<CanDoProgressRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [overrideReason, setOverrideReason] = useState('');
  const [overrideScore, setOverrideScore] = useState('80');
  const [overrideStudentId, setOverrideStudentId] = useState('');
  const [message, setMessage] = useState<string | null>(null);

  const loadAssignments = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await apiFetch(`/api/v2/classroom/${encodeURIComponent(classroomId)}/assignments`);
      const list: AssignmentRow[] = (data.assignments ?? []).map((a: AssignmentRow) => ({
        id: String(a.id),
        title: a.title,
        dueAt: a.dueAt ?? null,
        publishStatus: a.publishStatus ?? 'draft',
        type: a.type,
      }));
      setAssignments(list);
      if (list.length > 0 && !selectedId) setSelectedId(list[0].id);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not load assignments');
    } finally {
      setLoading(false);
    }
  }, [classroomId, selectedId]);

  const loadProgress = useCallback(async () => {
    if (!selectedId) return;
    try {
      const data = await apiFetch(
        `/api/v2/classroom/${encodeURIComponent(classroomId)}/assignments/${encodeURIComponent(selectedId)}/progress`,
      );
      setProgress(data.canDoProgress ?? []);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not load can-do progress');
    }
  }, [classroomId, selectedId]);

  useEffect(() => {
    void loadAssignments();
  }, [loadAssignments]);

  useEffect(() => {
    void loadProgress();
  }, [loadProgress]);

  const publish = async (assignmentId: string) => {
    setMessage(null);
    try {
      await apiFetch(
        `/api/v2/classroom/${encodeURIComponent(classroomId)}/assignments/${encodeURIComponent(assignmentId)}/publish`,
        { method: 'POST', body: '{}' },
      );
      setMessage('Published — learners can see this assignment.');
      await loadAssignments();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Publish failed');
    }
  };

  const saveOverride = async () => {
    if (!selectedId || !overrideStudentId.trim()) return;
    setMessage(null);
    try {
      await apiFetch(
        `/api/v2/classroom/${encodeURIComponent(classroomId)}/assignments/${encodeURIComponent(selectedId)}/submissions/${encodeURIComponent(overrideStudentId.trim())}/override`,
        {
          method: 'POST',
          body: JSON.stringify({ score: Number(overrideScore), reason: overrideReason }),
        },
      );
      setMessage('Override saved. The learner will see your score and the auto-grade.');
      setOverrideReason('');
      await loadProgress();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Override failed');
    }
  };

  if (loading) {
    return <p role="status">Loading assignments…</p>;
  }

  return (
    <section aria-labelledby="assign-heading" style={{ maxWidth: 960, margin: '0 auto', padding: 24 }}>
      <h1 id="assign-heading" style={{ fontSize: 28, marginBottom: 8 }}>
        Assignments
      </h1>
      <p style={{ marginBottom: 24, color: '#444' }}>
        {classroomName} — progress by can-do statement, not minutes logged.
      </p>
      {error ? (
        <p role="alert" style={{ color: '#b00020' }}>
          {error}
        </p>
      ) : null}
      {message ? (
        <p role="status" style={{ color: '#0a6' }}>
          {message}
        </p>
      ) : null}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.2fr', gap: 24 }}>
        <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
          {assignments.map((a) => (
            <li key={a.id} style={{ marginBottom: 12 }}>
              <button
                type="button"
                onClick={() => setSelectedId(a.id)}
                aria-pressed={selectedId === a.id}
                style={{
                  width: '100%',
                  textAlign: 'left',
                  padding: 16,
                  borderRadius: 12,
                  border: selectedId === a.id ? '2px solid #2d6a4f' : '1px solid #ddd',
                  background: '#fff',
                  minHeight: 48,
                }}
              >
                <strong>{a.title}</strong>
                <div style={{ fontSize: 13, color: '#666' }}>
                  {a.publishStatus === 'published' ? 'Published' : 'Draft'} · {a.type}
                  {a.dueAt ? ` · Due ${new Date(a.dueAt).toLocaleString()}` : ''}
                </div>
              </button>
              {a.publishStatus !== 'published' ? (
                <button
                  type="button"
                  onClick={() => void publish(a.id)}
                  style={{ marginTop: 8, minHeight: 48, padding: '0 16px' }}
                >
                  Publish to class
                </button>
              ) : null}
            </li>
          ))}
        </ul>
        <div>
          <h2 style={{ fontSize: 20 }}>Can-do progress</h2>
          {progress.length === 0 ? (
            <p>No submissions yet — progress appears when learners submit speaking tasks.</p>
          ) : (
            <ul style={{ listStyle: 'none', padding: 0 }}>
              {progress.map((row) => (
                <li key={row.canDoId} style={{ marginBottom: 16, padding: 16, border: '1px solid #eee', borderRadius: 12 }}>
                  <div style={{ fontWeight: 600 }}>{row.statementEn}</div>
                  <div style={{ fontSize: 14, marginTop: 8 }}>
                    Met {row.metCount} · Not yet {row.notMetCount} · Unsure {row.unsureCount} (of {row.studentCount})
                  </div>
                </li>
              ))}
            </ul>
          )}
          <h2 style={{ fontSize: 20, marginTop: 32 }}>Override auto-grade</h2>
          <label htmlFor="student-id">Learner user id</label>
          <input
            id="student-id"
            value={overrideStudentId}
            onChange={(e) => setOverrideStudentId(e.target.value)}
            style={{ display: 'block', width: '100%', marginBottom: 12, minHeight: 48 }}
          />
          <label htmlFor="override-score">Score (0–100)</label>
          <input
            id="override-score"
            type="number"
            min={0}
            max={100}
            value={overrideScore}
            onChange={(e) => setOverrideScore(e.target.value)}
            style={{ display: 'block', width: '100%', marginBottom: 12, minHeight: 48 }}
          />
          <label htmlFor="override-reason">Reason (shown to learner)</label>
          <textarea
            id="override-reason"
            value={overrideReason}
            onChange={(e) => setOverrideReason(e.target.value)}
            rows={3}
            style={{ display: 'block', width: '100%', marginBottom: 12 }}
          />
          <button type="button" onClick={() => void saveOverride()} style={{ minHeight: 48, padding: '0 20px' }}>
            Save override
          </button>
        </div>
      </div>
    </section>
  );
}

export default TeacherAssignmentsPanel;
