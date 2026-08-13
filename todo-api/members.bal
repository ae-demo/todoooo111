import ballerina/sql;

// list_member rows are always plain members — the owner is never stored as
// a row here. It is derived on the fly from LIST.ownerId wherever a member
// listing needs to surface it (see membersPage in service.bal), which keeps
// removeMember/leaveList operating purely on real membership rows: an
// owner's row simply does not exist to match against those operations.

function getMembershipByUser(string listId, string userId) returns ListMember?|error {
    ListMember|sql:Error result = dbClient->queryRow(`
        SELECT id, list_id AS "listId", user_id AS "userId", email, role, joined_at AS "joinedAt"
        FROM list_member WHERE list_id = ${listId} AND user_id = ${userId}
    `);
    if result is sql:NoRowsError {
        return ();
    }
    if result is sql:Error {
        return result;
    }
    return result;
}

function getMemberById(string listId, string memberId) returns ListMember?|error {
    ListMember|sql:Error result = dbClient->queryRow(`
        SELECT id, list_id AS "listId", user_id AS "userId", email, role, joined_at AS "joinedAt"
        FROM list_member WHERE list_id = ${listId} AND id = ${memberId}
    `);
    if result is sql:NoRowsError {
        return ();
    }
    if result is sql:Error {
        return result;
    }
    return result;
}

function countListMembers(string listId) returns int|error {
    record {|int total;|} result = check dbClient->queryRow(`
        SELECT COUNT(*) AS total FROM list_member WHERE list_id = ${listId}
    `);
    return result.total;
}

function queryListMembers(string listId, int pageLimit, int offset) returns ListMember[]|error {
    stream<ListMember, sql:Error?> resultStream = dbClient->query(`
        SELECT id, list_id AS "listId", user_id AS "userId", email, role, joined_at AS "joinedAt"
        FROM list_member WHERE list_id = ${listId}
        ORDER BY joined_at ASC
        LIMIT ${pageLimit} OFFSET ${offset}
    `);
    ListMember[] members = [];
    check from ListMember m in resultStream
        do {
            members.push(m);
        };
    return members;
}

function insertMember(string listId, string userId, string email) returns ListMember|error {
    string id = newId();
    string joinedAt = currentTimestamp();
    _ = check dbClient->execute(`
        INSERT INTO list_member (id, list_id, user_id, email, role, joined_at)
        VALUES (${id}, ${listId}, ${userId}, ${email}, 'member', ${joinedAt})
    `);
    return {id, listId, userId, email, role: "member", joinedAt};
}

function deleteMemberById(string listId, string memberId) returns int|error {
    sql:ExecutionResult result = check dbClient->execute(`
        DELETE FROM list_member WHERE list_id = ${listId} AND id = ${memberId}
    `);
    int? affected = result.affectedRowCount;
    return affected ?: 0;
}

function deleteMembershipByUser(string listId, string userId) returns int|error {
    sql:ExecutionResult result = check dbClient->execute(`
        DELETE FROM list_member WHERE list_id = ${listId} AND user_id = ${userId}
    `);
    int? affected = result.affectedRowCount;
    return affected ?: 0;
}

// The owner has no row in list_member (see note above) so a members page is
// assembled by prepending a synthetic owner entry to the real member rows,
// then paginating over the combined set.
function buildMembersPage(List listRow, int pageLimit, int offset) returns MembersPage|error {
    int memberCount = check countListMembers(listRow.id);
    int total = memberCount + 1;
    [string?, string?] links = buildPageLinks("/lists/" + listRow.id + "/members", {}, total, pageLimit, offset);

    ListMember[] page = [];
    if pageLimit > 0 {
        if offset == 0 {
            ListMember ownerMember = {
                id: "owner-" + listRow.id,
                listId: listRow.id,
                userId: listRow.ownerId,
                email: callerEmail(listRow.ownerId),
                role: "owner",
                joinedAt: listRow.createdAt
            };
            page.push(ownerMember);
            int remaining = pageLimit - 1;
            if remaining > 0 {
                ListMember[] memberRows = check queryListMembers(listRow.id, remaining, 0);
                foreach ListMember m in memberRows {
                    page.push(m);
                }
            }
        } else {
            int adjustedOffset = offset - 1;
            ListMember[] memberRows = check queryListMembers(listRow.id, pageLimit, adjustedOffset);
            foreach ListMember m in memberRows {
                page.push(m);
            }
        }
    }
    return {count: total, next: links[0], previous: links[1], data: page};
}
