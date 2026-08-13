import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Layout } from "../components/Layout";
import { createList } from "../api";

export default function NewList() {
  const navigate = useNavigate();
  const [name, setName] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleCreate() {
    if (!name.trim()) {
      setError("List name is required");
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      const list = await createList(name.trim());
      navigate(`/lists/${list.id}`);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to create list");
      setSubmitting(false);
    }
  }

  return (
    <Layout>
      <p className="breadcrumb">My Lists / New list</p>
      <h1>New List</h1>
      <input
        className="input"
        placeholder="List name — e.g. Apartment Chores"
        value={name}
        onChange={(e) => setName(e.target.value)}
      />
      {error && <p className="error">{error}</p>}
      <div className="row">
        <div className="spacer" />
        <button className="btn" onClick={() => navigate("/")}>
          Cancel
        </button>
        <button className="btn primary" disabled={submitting} onClick={() => void handleCreate()}>
          Create list
        </button>
      </div>
    </Layout>
  );
}
