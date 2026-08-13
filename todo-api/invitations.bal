import ballerina/sql;

function createInvitationRow(string listId, string invitedEmail, string invitedBy) returns Invitation|error {
    string id = newId();
    string createdAt = currentTimestamp();
    _ = check dbClient->execute(`
        INSERT INTO invitation (id, list_id, invited_email, invited_by, status, created_at)
        VALUES (${id}, ${listId}, ${invitedEmail}, ${invitedBy}, 'pending', ${createdAt})
    `);
    return {id, listId, invitedEmail, invitedBy, status: "pending", createdAt};
}

function getInvitationById(string invitationId) returns Invitation?|error {
    Invitation|sql:Error result = dbClient->queryRow(`
        SELECT id, list_id AS "listId", invited_email AS "invitedEmail", invited_by AS "invitedBy",
               status, created_at AS "createdAt"
        FROM invitation WHERE id = ${invitationId}
    `);
    if result is sql:NoRowsError {
        return ();
    }
    if result is sql:Error {
        return result;
    }
    return result;
}

function countPendingListInvitations(string listId) returns int|error {
    record {|int total;|} result = check dbClient->queryRow(`
        SELECT COUNT(*) AS total FROM invitation WHERE list_id = ${listId} AND status = 'pending'
    `);
    return result.total;
}

function queryPendingListInvitations(string listId, int pageLimit, int offset) returns Invitation[]|error {
    stream<Invitation, sql:Error?> resultStream = dbClient->query(`
        SELECT id, list_id AS "listId", invited_email AS "invitedEmail", invited_by AS "invitedBy",
               status, created_at AS "createdAt"
        FROM invitation WHERE list_id = ${listId} AND status = 'pending'
        ORDER BY created_at DESC
        LIMIT ${pageLimit} OFFSET ${offset}
    `);
    Invitation[] invitations = [];
    check from Invitation i in resultStream
        do {
            invitations.push(i);
        };
    return invitations;
}

function countPendingMyInvitations(string email) returns int|error {
    record {|int total;|} result = check dbClient->queryRow(`
        SELECT COUNT(*) AS total FROM invitation WHERE invited_email = ${email} AND status = 'pending'
    `);
    return result.total;
}

function queryPendingMyInvitations(string email, int pageLimit, int offset) returns Invitation[]|error {
    stream<Invitation, sql:Error?> resultStream = dbClient->query(`
        SELECT id, list_id AS "listId", invited_email AS "invitedEmail", invited_by AS "invitedBy",
               status, created_at AS "createdAt"
        FROM invitation WHERE invited_email = ${email} AND status = 'pending'
        ORDER BY created_at DESC
        LIMIT ${pageLimit} OFFSET ${offset}
    `);
    Invitation[] invitations = [];
    check from Invitation i in resultStream
        do {
            invitations.push(i);
        };
    return invitations;
}

function updateInvitationStatus(string invitationId, string status) returns error? {
    _ = check dbClient->execute(`UPDATE invitation SET status = ${status} WHERE id = ${invitationId}`);
}
