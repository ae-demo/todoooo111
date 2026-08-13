import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { Layout } from "../components/Layout";
import {
  fetchList,
  fetchMembers,
  fetchTasks,
  inviteByEmail,
  leaveList,
  removeMember,
  updateTask,
  type List,
  type ListMember,
  type Priority,
  type Task,
  type TaskSort,
} from "../api";
import { getCurrentUserId } from "../auth";

type Tab = "all" | "open" | "done";

function doneFilterFor(tab: Tab): boolean | undefined {
  if (tab === "open") return false;
  if (tab === "done") return true;
  return undefined;
}

export default function ListDetail() {
  const { listId } = useParams<{ listId: string }>();
  const navigate = useNavigate();

  const [list, setList] = useState<List | null>(null);
  const [userId, setUserId] = useState<string | null>(null);
  const [members, setMembers] = useState<ListMember[]>([]);
  const [tasks, setTasks] = useState<Task[]>([]);
  const [counts, setCounts] = useState({ all: 0, open: 0, done: 0 });
  const [tab, setTab] = useState<Tab>("all");
  const [sort, setSort] = useState<TaskSort>("dueDate");
  const [priorityFilter, setPriorityFilter] = useState<Priority | "">("");
  const [inviteEmail, setInviteEmail] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [refreshToken, setRefreshToken] = useState(0);

  // List + members: reloaded on mount and after any membership change.
  useEffect(() => {
    if (!listId) return;
    const id = listId;
    let cancelled = false;
    async function load() {
      setLoading(true);
      setError(null);
      try {
        const [me, listData, memberData] = await Promise.all([
          getCurrentUserId(),
          fetchList(id),
          fetchMembers(id),
        ]);
        if (cancelled) return;
        setUserId(me);
        setList(listData);
        setMembers(memberData.data);
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : "Failed to load list");
      } finally {
        if (!cancelled) setLoading(false);
      }
    }
    void load();
    return () => {
      cancelled = true;
    };
  }, [listId, refreshToken]);

  // Tasks + tab counts: reloaded whenever the filters or the task data change.
  useEffect(() => {
    if (!listId) return;
    const id = listId;
    let cancelled = false;
    async function load() {
      try {
        const priority = priorityFilter || undefined;
        const [all, open, doneCount, filtered] = await Promise.all([
          fetchTasks(id, { priority }),
          fetchTasks(id, { priority, done: false }),
          fetchTasks(id, { priority, done: true }),
          fetchTasks(id, { priority, sort, done: doneFilterFor(tab) }),
        ]);
        if (cancelled) return;
        setCounts({ all: all.count, open: open.count, done: doneCount.count });
        setTasks(filtered.data);
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : "Failed to load tasks");
      }
    }
    void load();
    return () => {
      cancelled = true;
    };
  }, [listId, tab, sort, priorityFilter, refreshToken]);

  const isOwner = Boolean(list && userId && list.ownerId === userId);

  async function handleInvite() {
    if (!listId || !inviteEmail.trim()) return;
    try {
      await inviteByEmail(listId, inviteEmail.trim());
      setInviteEmail("");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to invite member");
    }
  }

  async function handleRemoveMember(memberId: string) {
    if (!listId) return;
    try {
      await removeMember(listId, memberId);
      setRefreshToken((n) => n + 1);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to remove member");
    }
  }

  async function handleLeave() {
    if (!listId) return;
    try {
      await leaveList(listId);
      navigate("/");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to leave list");
    }
  }

  async function handleToggleDone(task: Task) {
    try {
      await updateTask(task.id, { done: !task.done });
      setRefreshToken((n) => n + 1);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to update task");
    }
  }

  if (loading) {
    return (
      <Layout>
        <p>Loading…</p>
      </Layout>
    );
  }

  if (!list || !listId) {
    return (
      <Layout>
        <p className="error">{error ?? "List not found"}</p>
      </Layout>
    );
  }

  return (
    <Layout>
      <p className="breadcrumb">My Lists / {list.name}</p>
      <div className="row">
        <h1>{list.name}</h1>
        <span className={isOwner ? "badge info" : "badge"}>{isOwner ? "Owner" : "Member"}</span>
        <div className="spacer" />
        <button className="btn" onClick={() => void handleLeave()}>
          Leave list
        </button>
      </div>
      {error && <p className="error">{error}</p>}

      <div className="row">
        <div className="tabs">
          <button className={tab === "all" ? "tab active" : "tab"} onClick={() => setTab("all")}>
            All ({counts.all})
          </button>
          <button className={tab === "open" ? "tab active" : "tab"} onClick={() => setTab("open")}>
            Open ({counts.open})
          </button>
          <button className={tab === "done" ? "tab active" : "tab"} onClick={() => setTab("done")}>
            Done ({counts.done})
          </button>
        </div>
        <div className="spacer" />
        <select
          className="select"
          value={priorityFilter}
          onChange={(e) => setPriorityFilter(e.target.value as Priority | "")}
        >
          <option value="">Priority: All</option>
          <option value="low">Priority: Low</option>
          <option value="medium">Priority: Medium</option>
          <option value="high">Priority: High</option>
        </select>
        <select
          className="select"
          value={sort}
          onChange={(e) => setSort(e.target.value as TaskSort)}
        >
          <option value="dueDate">Sort: Due date</option>
          <option value="priority">Sort: Priority</option>
        </select>
        <button className="btn primary" onClick={() => navigate(`/lists/${listId}/tasks/new`)}>
          Add task
        </button>
      </div>

      <table className="table">
        <thead>
          <tr>
            <th>Task</th>
            <th>Due</th>
            <th>Priority</th>
            <th>Added by</th>
            <th>Completed by</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          {tasks.map((task) => (
            <tr
              key={task.id}
              className="clickable"
              onClick={() => navigate(`/lists/${listId}/tasks/new`)}
            >
              <td>{task.title}</td>
              <td>{task.dueDate ?? "—"}</td>
              <td>{task.priority}</td>
              <td>{task.createdBy}</td>
              <td>{task.completedBy ?? "—"}</td>
              <td>
                <button
                  className="btn small"
                  onClick={(e) => {
                    e.stopPropagation();
                    void handleToggleDone(task);
                  }}
                >
                  {task.done ? "Done" : "Open"}
                </button>
              </td>
            </tr>
          ))}
          {tasks.length === 0 && (
            <tr>
              <td colSpan={6}>No tasks match this view.</td>
            </tr>
          )}
        </tbody>
      </table>

      <div className="row">
        <h2>Members</h2>
        <div className="spacer" />
        {isOwner && (
          <>
            <input
              className="input inline"
              placeholder="Invite by email"
              value={inviteEmail}
              onChange={(e) => setInviteEmail(e.target.value)}
            />
            <button className="btn primary" onClick={() => void handleInvite()}>
              Invite by email
            </button>
          </>
        )}
      </div>
      <table className="table">
        <thead>
          <tr>
            <th>Member</th>
            <th>Role</th>
            <th>Joined</th>
            {isOwner && <th></th>}
          </tr>
        </thead>
        <tbody>
          {members.map((member) => (
            <tr key={member.id}>
              <td>{member.email}</td>
              <td>{member.role}</td>
              <td>{new Date(member.joinedAt).toLocaleDateString()}</td>
              {isOwner && (
                <td>
                  {member.role !== "owner" && (
                    <button
                      className="btn small danger"
                      onClick={() => void handleRemoveMember(member.id)}
                    >
                      Remove
                    </button>
                  )}
                </td>
              )}
            </tr>
          ))}
        </tbody>
      </table>
    </Layout>
  );
}
