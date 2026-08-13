// Collaborative to-do app — 5 screens

screen MyLists "Signed-in user sees every list they own or belong to, plus pending invites"
  navbar "TodoTogether"
  sidebar "My Lists -> MyLists | Invitations -> Invitations"
  row
    heading "My Lists"
    right
    button "New list" primary -> NewList
  row
    card "Lists | 4 | you own or belong to"
    card "Pending invitations | 2 | waiting on you"
  table "List | Role | Members | Open tasks" -> ListDetail
    row "Family Errands | Owner | 3 | 5"
    row "Trip to Kandy | Owner | 2 | 8"
    row "Apartment Chores | Member | 4 | 3"
    row "Book Club | Member | 5 | 1"

screen NewList "Owner creates a new shared to-do list"
  navbar "TodoTogether"
  sidebar "My Lists -> MyLists | Invitations -> Invitations"
  breadcrumb "My Lists / New list"
  heading "New List"
  input "List name — e.g. Apartment Chores"
  row
    right
    button "Cancel" -> MyLists
    button "Create list" primary -> ListDetail

screen ListDetail "Owner or member manages tasks and membership on one shared list"
  navbar "TodoTogether"
  sidebar "My Lists -> MyLists | Invitations -> Invitations"
  breadcrumb "My Lists / Apartment Chores"
  row
    heading "Apartment Chores"
    badge "Owner" info
  row
    tabs "All (8) | Open (5) | Done (3)"
    right
    select "Sort: Due date"
    button "Add task" primary -> NewTask
  table "Task | Due | Priority | Added by | Status" -> NewTask
    row "Take out recycling | Fri | Medium | A. Perera | Open"
    row "Clean fridge | Mon | High | J. Silva | Open"
    row "Pay internet bill | Tue | High | A. Perera | Open"
    row "Restock detergent | — | Low | J. Silva | Done"
  row
    heading "Members"
    right
    button "Invite by email" primary -> ListDetail
  table "Member | Role | Joined"
    row "A. Perera | Owner | Jan 2026"
    row "J. Silva | Member | Feb 2026"
    row "M. Fernando | Member | Mar 2026"

screen NewTask "Member adds a task with a due date and priority"
  navbar "TodoTogether"
  sidebar "My Lists -> MyLists | Invitations -> Invitations"
  breadcrumb "My Lists / Apartment Chores / New task"
  heading "New Task"
  input "Title — e.g. Take out recycling"
  row
    input "Due date — e.g. 2026-08-21"
    select "Priority: Medium"
  row
    right
    button "Cancel" -> ListDetail
    button "Add task" primary -> ListDetail

screen Invitations "User reviews and accepts or declines invitations sent to their email"
  navbar "TodoTogether"
  sidebar "My Lists -> MyLists | Invitations -> Invitations"
  heading "Invitations"
  text "Invitations sent to your account email appear here automatically."
  table "List | Invited by | Sent"
    row "Book Club | M. Fernando | 2d ago"
    row "Trip to Kandy | A. Perera | 5d ago"
  row
    button "Decline"
    button "Accept" primary -> MyLists
