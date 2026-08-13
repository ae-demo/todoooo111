import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { handleCallback } from "../auth";

export default function Callback() {
  const navigate = useNavigate();

  useEffect(() => {
    handleCallback()
      .then(() => navigate("/", { replace: true }))
      .catch(() => navigate("/", { replace: true }));
  }, [navigate]);

  return <p className="center-message">Signing you in…</p>;
}
