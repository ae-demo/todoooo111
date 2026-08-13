import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Layout } from "../components/Layout";
import { fetchLists, fetchMembers, fetchMyInvitations, fetchTasks, type List } from "../api";
import { getCurrentUserId } from "../auth";

type Row = {
  list: List;
  role: "Owner" | "Member";
  members: number;
  openTasks: number;
};

export default function MyLists() {
  const navigate = useNavigate();
  const [rows, setRows] = useState<Row[]>([]);
  const [pendingCount, setPendingCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    async function load() {
      setLoading(true);
      setError(null);
      try {
        const userId = await getCurrentUserId();
        const [{ data: lists }, invitations] = await Promise.all([
          fetchLists(),
          fetchMyInvitations(),
        ]);
        const withDetails = await Promise.all(
          lists.map(async (list) => {
            const [members, openTasks] = await Promise.all([
              fetchMembers(list.id),
              fetchTasks(list.id, { done: false }),
            ]);
            return {
              list,
              role: (list.ownerId === userId ? "Owner" : "Member") as Row["role"],
              members: members.count,
              openTasks: openTasks.count,
            };
          }),
        );
        if (cancelled) return;
        setRows(withDetails);
        setPendingCount(invitations.count);
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : "Failed to load lists");
      } finally {
        if (!cancelled) setLoading(false);
      }
    }
    void load();
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <Layout>
      <div className="row">
        <h1>My Lists</h1>
        <div className="spacer" />
        <button className="btn primary" onClick={() => navigate("/lists/new")}>
          New list
        </button>
      </div>
      <div className="row cards">
        <div className="card">
          <div className="card-label">Lists</div>
          <div className="card-value">{rows.length}</div>
          <div className="card-caption">you own or belong to</div>
        </div>
        <div className="card">
          <div className="card-label">Pending invitations</div>
          <div className="card-value">{pendingCount}</div>
          <div className="card-caption">waiting on you</div>
        </div>
      </div>
      {error && <p className="error">{error}</p>}
      {loading ? (
        <p>Loading…</p>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>List</th>
              <th>Role</th>
              <th>Members</th>
              <th>Open tasks</th>
            </tr>
          </thead>
          <tbody>
            {rows.map(({ list, role, members, openTasks }) => (
              <tr
                key={list.id}
                className="clickable"
                onClick={() => navigate(`/lists/${list.id}`)}
              >
                <td>{list.name}</td>
                <td>{role}</td>
                <td>{members}</td>
                <td>{openTasks}</td>
              </tr>
            ))}
            {rows.length === 0 && (
              <tr>
                <td colSpan={4}>No lists yet — create your first one.</td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </Layout>
  );
}
