import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;

final postgresql:Client dbClient = check new (
    host = dbHost,
    port = dbPort,
    database = dbName,
    username = dbUser,
    password = dbPassword
);

// Schema per the ER model in specs/design/design.md: LIST, LIST_MEMBER,
// INVITATION, TASK. Timestamp/date columns are TEXT holding canonical
// ISO-8601 strings the application itself produces (see util.bal), which
// keeps read rows binding directly onto the API response records.
function init() returns error? {
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS todo_list (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            owner_id TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
    `);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS list_member (
            id TEXT PRIMARY KEY,
            list_id TEXT NOT NULL REFERENCES todo_list(id) ON DELETE CASCADE,
            user_id TEXT NOT NULL,
            email TEXT NOT NULL,
            role TEXT NOT NULL,
            joined_at TEXT NOT NULL,
            UNIQUE (list_id, user_id)
        )
    `);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS invitation (
            id TEXT PRIMARY KEY,
            list_id TEXT NOT NULL REFERENCES todo_list(id) ON DELETE CASCADE,
            invited_email TEXT NOT NULL,
            invited_by TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
    `);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS task (
            id TEXT PRIMARY KEY,
            list_id TEXT NOT NULL REFERENCES todo_list(id) ON DELETE CASCADE,
            title TEXT NOT NULL,
            due_date TEXT,
            priority TEXT NOT NULL,
            done BOOLEAN NOT NULL DEFAULT FALSE,
            created_by TEXT NOT NULL,
            completed_by TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )
    `);
}
