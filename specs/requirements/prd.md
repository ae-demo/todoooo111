# todoooo111 — PRD

## Problem Statement

People who share responsibilities — a household, a small team, a couple
planning a trip — end up tracking shared tasks across scattered channels
(chat threads, sticky notes, memory) with no single place that shows who
added what, who's done it, and what's still open. Nothing keeps the list of
things-to-do in sync between the people who share the work, so tasks get
duplicated, forgotten, or done twice.

## Solution

A collaborative to-do list app: any signed-in user can create a list, invite
others onto it by email, and everyone on the list adds, edits, prioritizes,
and checks off shared tasks together. Each task carries a due date and
priority so the group can see what's urgent, and every list keeps a simple
one-flat-list shape — no nested boards or multiple lists to manage.

## Actors

- **User** — a signed-in individual who creates or joins shared to-do lists,
adds and manages tasks on lists they belong to, and manages membership on
lists they own (inviting or removing collaborators, or leaving a list they
joined).

## User Stories

1. As a User, I want to sign in via single sign-on, so that my lists and
 tasks are tied to my account.
2. As a User, I want to create a to-do list, so that I have a shared place to
 track tasks with others.
3. As a User, I want to invite someone to my list by email, so that we can
 collaborate on the same tasks.
4. As a User, I want to accept an invitation to join a list, so that I start
 seeing and contributing to its tasks.
5. As a User, I want to add a task with a title, due date, and priority, so
 that the group can plan and see what's urgent.
6. As a User, I want to mark a task done or not-done, so that everyone on the
 list can see progress.
7. As a User, I want to edit or delete a task, so that the list stays
 accurate as plans change.
8. As a User, I want to see who added and who completed each task, so that I
 know who's doing what on a shared list.
9. As a User, I want to sort and filter tasks by due date or priority, so
 that I can focus on what matters most right now.
10. As a User, I want to remove a member from a list I own, so that I can
 control who has access to it.
11. As a User, I want to leave a list I no longer want to be part of, so that
 I stop seeing tasks that aren't mine.

## Product Decisions

- Sign-in is via single sign-on through the platform identity provider
(Thunder). *(org default)*
- Lists are collaborative and flat: a list has no sub-lists or nested
categories, and tasks live directly on the list.
- Each user's tasks live on lists — there is no separate "personal, unshared"
list concept; a single-member list is just a list nobody else has joined
yet.
- Membership is by email invitation; the list owner can invite and remove
members, and any member may leave voluntarily.
- Tasks carry a title, a due date, and a priority level (e.g. low / medium /
high); the list can be sorted or filtered by either.
- No reminder notifications are sent for upcoming or overdue tasks — users
check the app themselves. *(assumed)*

## Phasing

- **Phase 1 — Shared to-do lists with collaborators**: deliver sign-in,
list creation and invitation-based membership, and full task management
(add, edit, delete, complete, sort/filter by due date or priority) with
visibility into who added and completed each task. Stories: 1, 2, 3, 4, 5,
6, 7, 8, 9, 10, 11.

## Out of Scope

- Multiple named lists per user (e.g. "Work" vs "Home") — each list is
standalone; organizing many lists is not in this phase.
- Reminder or notification emails/push for due or overdue tasks.
- Recurring or repeating tasks.
- Task comments, attachments, or sub-tasks.
- Real-time push updates between collaborators — members see changes when
they load or refresh the list, not instantly as they happen.
- Native mobile apps.

## Open Questions

1. Is there a cap on how many members can join a single shared list? —
 deferred, does not block design.

## Further Notes

None.