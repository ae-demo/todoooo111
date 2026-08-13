import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { Layout } from "../components/Layout";
import { createTask, fetchList, type Priority } from "../api";

export default function NewTask() {
  const { listId } = useParams<{ listId: string }>();
  const navigate = useNavigate();
  const [listName, setListName] = useState("");
  const [title, setTitle] = useState("");
  const [dueDate, setDueDate] = useState("");
  const [priority, setPriority] = useState<Priority>("medium");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!listId) return;
    fetchList(listId)
      .then((list) => setListName(list.name))
      .catch(() => setListName(""));
  }, [listId]);

  async function handleAdd() {
    if (!listId) return;
    if (!title.trim()) {
      setError("Title is required");
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      await createTask(listId, {
        title: title.trim(),
        dueDate: dueDate || null,
        priority,
      });
      navigate(`/lists/${listId}`);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to add task");
      setSubmitting(false);
    }
  }

  if (!listId) {
    return (
      <Layout>
        <p className="error">Missing list</p>
      </Layout>
    );
  }

  return (
    <Layout>
      <p className="breadcrumb">My Lists / {listName} / New task</p>
      <h1>New Task</h1>
      <input
        className="input"
        placeholder="Title — e.g. Take out recycling"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
      />
      <div className="row">
        <input
          className="input"
          type="date"
          value={dueDate}
          onChange={(e) => setDueDate(e.target.value)}
        />
        <select
          className="select"
          value={priority}
          onChange={(e) => setPriority(e.target.value as Priority)}
        >
          <option value="low">Priority: Low</option>
          <option value="medium">Priority: Medium</option>
          <option value="high">Priority: High</option>
        </select>
      </div>
      {error && <p className="error">{error}</p>}
      <div className="row">
        <div className="spacer" />
        <button className="btn" onClick={() => navigate(`/lists/${listId}`)}>
          Cancel
        </button>
        <button className="btn primary" disabled={submitting} onClick={() => void handleAdd()}>
          Add task
        </button>
      </div>
    </Layout>
  );
}
