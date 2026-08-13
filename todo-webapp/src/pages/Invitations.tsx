import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Layout } from "../components/Layout";
import { acceptInvitation, declineInvitation, fetchMyInvitations, type Invitation } from "../api";

export default function Invitations() {
  const navigate = useNavigate();
  const [invitations, setInvitations] = useState<Invitation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const res = await fetchMyInvitations();
      setInvitations(res.data);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load invitations");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
  }, []);

  async function handleAccept(invitation: Invitation) {
    setBusyId(invitation.id);
    setError(null);
    try {
      await acceptInvitation(invitation.id);
      navigate("/");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to accept invitation");
      setBusyId(null);
    }
  }

  async function handleDecline(invitation: Invitation) {
    setBusyId(invitation.id);
    setError(null);
    try {
      await declineInvitation(invitation.id);
      setInvitations((prev) => prev.filter((i) => i.id !== invitation.id));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to decline invitation");
    } finally {
      setBusyId(null);
    }
  }

  return (
    <Layout>
      <h1>Invitations</h1>
      <p className="hint">Invitations sent to your account email appear here automatically.</p>
      {error && <p className="error">{error}</p>}
      {loading ? (
        <p>Loading…</p>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>List</th>
              <th>Invited by</th>
              <th>Sent</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {invitations.map((invitation) => (
              <tr key={invitation.id}>
                {/* No accessible lookup for a list the caller isn't a member of
                    yet, or for the inviting user — surfaced as-is, per the
                    createdBy/completedBy convention on tasks. */}
                <td>{invitation.listId}</td>
                <td>{invitation.invitedBy}</td>
                <td>{new Date(invitation.createdAt).toLocaleDateString()}</td>
                <td>
                  <div className="row">
                    <button
                      className="btn"
                      disabled={busyId === invitation.id}
                      onClick={() => void handleDecline(invitation)}
                    >
                      Decline
                    </button>
                    <button
                      className="btn primary"
                      disabled={busyId === invitation.id}
                      onClick={() => void handleAccept(invitation)}
                    >
                      Accept
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {invitations.length === 0 && (
              <tr>
                <td colSpan={4}>No pending invitations.</td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </Layout>
  );
}
