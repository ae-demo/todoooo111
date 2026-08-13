import type { ReactNode } from "react";
import { NavLink } from "react-router-dom";

export function Layout({ children }: { children: ReactNode }) {
  return (
    <div className="shell">
      <header className="navbar">
        <span className="brand">TodoTogether</span>
      </header>
      <div className="body">
        <nav className="sidebar">
          <NavLink to="/" end className={({ isActive }) => (isActive ? "nav-item active" : "nav-item")}>
            My Lists
          </NavLink>
          <NavLink
            to="/invitations"
            className={({ isActive }) => (isActive ? "nav-item active" : "nav-item")}
          >
            Invitations
          </NavLink>
        </nav>
        <main className="content">{children}</main>
      </div>
    </div>
  );
}
