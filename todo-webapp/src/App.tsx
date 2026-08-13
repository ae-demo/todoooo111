import { useEffect, useState, type ReactNode } from "react";
import { Navigate, Route, Routes, useLocation } from "react-router-dom";
import { currentUser, signIn } from "./auth";
import Callback from "./pages/Callback";
import MyLists from "./pages/MyLists";
import NewList from "./pages/NewList";
import ListDetail from "./pages/ListDetail";
import NewTask from "./pages/NewTask";
import Invitations from "./pages/Invitations";

type AuthStatus = "loading" | "authed" | "anon";

// Gates every route but /callback: a signed-out visitor is redirected to
// sign-in rather than shown any list/task data.
function RequireAuth({ children }: { children: ReactNode }) {
  const [status, setStatus] = useState<AuthStatus>("loading");

  useEffect(() => {
    let cancelled = false;
    currentUser().then((user) => {
      if (cancelled) return;
      if (user) {
        setStatus("authed");
      } else {
        setStatus("anon");
        void signIn();
      }
    });
    return () => {
      cancelled = true;
    };
  }, []);

  if (status === "loading") {
    return <p className="center-message">Loading…</p>;
  }
  if (status === "anon") {
    return <p className="center-message">Redirecting to sign-in…</p>;
  }
  return <>{children}</>;
}

export default function App() {
  const location = useLocation();

  // The OIDC redirect_uri — never gated behind RequireAuth, since the user
  // isn't fully signed in yet when it loads.
  if (location.pathname === "/callback") {
    return <Callback />;
  }

  return (
    <RequireAuth>
      <Routes>
        <Route path="/" element={<MyLists />} />
        <Route path="/lists/new" element={<NewList />} />
        <Route path="/lists/:listId" element={<ListDetail />} />
        <Route path="/lists/:listId/tasks/new" element={<NewTask />} />
        <Route path="/invitations" element={<Invitations />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </RequireAuth>
  );
}
