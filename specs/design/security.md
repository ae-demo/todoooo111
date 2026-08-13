# Security design

## Roles → permissions

Ownership and membership are per-list, not global roles: the same user is
owner on lists they created and a plain member on lists they were invited
onto. `todo-api` derives which rows apply from the caller's identity on every
request — there is no separate admin surface.

## Authentication (Thunder)

- Shared dependency name: **`user-auth`**, declared identically on
`todo-webapp` (the SPA) and `todo-api` (the only protected backend) — this
shared name ties the browser's OIDC sign-in to the bearer token `todo-api`
validates.
- Scopes: `openid profile email` (default).
- `todo-webapp` performs OIDC + PKCE sign-in in the browser and attaches the
resulting access token to every `todo-api` call. `todo-api` validates the
token on every request; it issues no tokens itself.
- No component is intentionally unauthenticated — the app has no public,
signed-out surface beyond the sign-in screen itself.

## Role resolution

`todo-api` resolves the caller's user id from the validated token's `sub`
claim (surfaced by the gateway as the caller identity header) and email from
the `email` claim. Per request it then computes the effective role in
context:

- **Owner** — the caller's user id equals the target list's `ownerId`.
- **Member** — a `LIST_MEMBER` row exists for the caller's user id and the
target list.
- **Neither** — the list is not visible to the caller (404, never a bare 403
that would leak existence) except for the invitation-lookup endpoints, which
match on the caller's email regardless of membership.

An unmapped or invalid token is rejected (401) before any list/task logic
runs — deny by default.