# todoooo111 — Design

Collaborative to-do lists: a single-page React app (`todo-webapp`) talking to
one Ballerina API (`todo-api`), which persists lists, membership, invitations,
and tasks in its own Postgres database and sits behind Thunder for sign-in.
There is no separate notification channel — invitations surface in-app to
whichever signed-in user's account email matches the invite.

## Context (C1)

```mermaid
graph LR
  user["User"]
  webapp["todo-webapp"]
  api["todo-api"]
  auth["Thunder Auth"]
  db[("Todo Database")]

  user -->|uses| webapp
  webapp -->|REST + token| api
  webapp -->|OIDC sign-in| auth
  api -->|validate token| auth
  api -->|reads/writes| db
```

## Domain model (ER)

```mermaid
erDiagram
  LIST {
    string id
    string name
    string ownerId
    datetime createdAt
  }
  LIST_MEMBER {
    string id
    string listId
    string userId
    string email
    string role
    datetime joinedAt
  }
  INVITATION {
    string id
    string listId
    string invitedEmail
    string invitedBy
    string status
    datetime createdAt
  }
  TASK {
    string id
    string listId
    string title
    date dueDate
    string priority
    boolean done
    string createdBy
    string completedBy
    datetime createdAt
    datetime updatedAt
  }

  LIST ||--o{ LIST_MEMBER : has
  LIST ||--o{ INVITATION : has
  LIST ||--o{ TASK : contains
```

`LIST_MEMBER.role` is `owner` or `member`. `INVITATION.status` is `pending`,
`accepted`, or `declined`. `TASK.priority` is `low`, `medium`, or `high`.
`TASK.createdBy`/`completedBy` are the acting user's id, surfaced in the UI so
collaborators see who added and who completed each task.

## Key flows

### Invite and join a shared list

```mermaid
sequenceDiagram
  actor Owner
  participant W as todo-webapp
  participant A as todo-api
  actor Invitee

  Owner->>W: Enter invitee email
  W->>A: POST /lists/{id}/invitations
  A->>A: Create invitation (status: pending)
  Invitee->>W: Sign in
  W->>A: GET /invitations (mine)
  A-->>W: Pending invitations matching my email
  Invitee->>W: Accept invitation
  W->>A: POST /invitations/{id}/accept
  A->>A: Add LIST_MEMBER, mark invitation accepted
  A-->>W: List now visible to Invitee
```

### Add and complete a task

```mermaid
sequenceDiagram
  actor Member
  participant W as todo-webapp
  participant A as todo-api

  Member->>W: Add task (title, due date, priority)
  W->>A: POST /lists/{id}/tasks
  A-->>W: Task created (createdBy: Member)
  Member->>W: Mark task done
  W->>A: PATCH /tasks/{id} {done: true}
  A-->>W: Task updated (completedBy: Member)
  W->>W: Re-sort/filter by due date or priority
```