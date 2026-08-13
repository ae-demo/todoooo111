import ballerina/sql;

function createListRow(string ownerId, string name) returns List|error {
    string id = newId();
    string createdAt = currentTimestamp();
    _ = check dbClient->execute(`
        INSERT INTO todo_list (id, name, owner_id, created_at)
        VALUES (${id}, ${name}, ${ownerId}, ${createdAt})
    `);
    return {id, name, ownerId, createdAt};
}

function getListById(string listId) returns List?|error {
    List|sql:Error result = dbClient->queryRow(`
        SELECT id, name, owner_id AS "ownerId", created_at AS "createdAt"
        FROM todo_list WHERE id = ${listId}
    `);
    if result is sql:NoRowsError {
        return ();
    }
    if result is sql:Error {
        return result;
    }
    return result;
}

function deleteListRow(string listId) returns error? {
    _ = check dbClient->execute(`DELETE FROM todo_list WHERE id = ${listId}`);
}

function countCallerLists(string callerId) returns int|error {
    record {|int total;|} result = check dbClient->queryRow(`
        SELECT COUNT(*) AS total FROM todo_list
        WHERE owner_id = ${callerId}
           OR id IN (SELECT list_id FROM list_member WHERE user_id = ${callerId})
    `);
    return result.total;
}

function queryCallerLists(string callerId, int pageLimit, int offset) returns List[]|error {
    stream<List, sql:Error?> resultStream = dbClient->query(`
        SELECT id, name, owner_id AS "ownerId", created_at AS "createdAt"
        FROM todo_list
        WHERE owner_id = ${callerId}
           OR id IN (SELECT list_id FROM list_member WHERE user_id = ${callerId})
        ORDER BY created_at DESC
        LIMIT ${pageLimit} OFFSET ${offset}
    `);
    List[] lists = [];
    check from List l in resultStream
        do {
            lists.push(l);
        };
    return lists;
}

// Owner = caller's X-User-Id equals the list's ownerId; member = a
// LIST_MEMBER row exists; neither is reported as "none" so callers can turn
// that into a 404 (security.md: never a bare 403 for plain visibility).
function resolveRole(List listRow, string callerId) returns Role|error {
    if listRow.ownerId == callerId {
        return "owner";
    }
    ListMember? membership = check getMembershipByUser(listRow.id, callerId);
    if membership is ListMember {
        return "member";
    }
    return "none";
}
