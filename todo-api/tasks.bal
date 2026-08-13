import ballerina/sql;

function taskFilterClause(string listId, string? priorityFilter, boolean? doneFilter) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery whereClause = `WHERE list_id = ${listId}`;
    if priorityFilter is string {
        whereClause = sql:queryConcat(whereClause, ` AND priority = ${priorityFilter}`);
    }
    if doneFilter is boolean {
        whereClause = sql:queryConcat(whereClause, ` AND done = ${doneFilter}`);
    }
    return whereClause;
}

function taskOrderClause(string? sort) returns sql:ParameterizedQuery {
    if sort == "priority" {
        return ` ORDER BY CASE priority WHEN 'high' THEN 1 WHEN 'medium' THEN 2 WHEN 'low' THEN 3 ELSE 4 END ASC, created_at ASC`;
    }
    if sort == "dueDate" {
        return ` ORDER BY due_date ASC NULLS LAST, created_at ASC`;
    }
    return ` ORDER BY created_at ASC`;
}

function countTasks(string listId, string? priorityFilter, boolean? doneFilter) returns int|error {
    sql:ParameterizedQuery whereClause = taskFilterClause(listId, priorityFilter, doneFilter);
    sql:ParameterizedQuery query = sql:queryConcat(`SELECT COUNT(*) AS total FROM task `, whereClause);
    record {|int total;|} result = check dbClient->queryRow(query);
    return result.total;
}

function queryTasks(string listId, string? priorityFilter, boolean? doneFilter, string? sort, int pageLimit, int offset) returns Task[]|error {
    sql:ParameterizedQuery selectClause = `SELECT id, list_id AS "listId", title, due_date AS "dueDate", priority, done,
               created_by AS "createdBy", completed_by AS "completedBy", created_at AS "createdAt", updated_at AS "updatedAt"
        FROM task `;
    sql:ParameterizedQuery whereClause = taskFilterClause(listId, priorityFilter, doneFilter);
    sql:ParameterizedQuery orderClause = taskOrderClause(sort);
    sql:ParameterizedQuery pagingClause = ` LIMIT ${pageLimit} OFFSET ${offset}`;
    sql:ParameterizedQuery fullQuery = sql:queryConcat(selectClause, whereClause, orderClause, pagingClause);
    stream<Task, sql:Error?> resultStream = dbClient->query(fullQuery);
    Task[] tasks = [];
    check from Task t in resultStream
        do {
            tasks.push(t);
        };
    return tasks;
}

function createTaskRow(string listId, string createdBy, TaskCreateRequest payload) returns Task|error {
    string id = newId();
    string title = payload.title;
    string priority = payload.priority;
    string? dueDate = payload?.dueDate;
    string createdAt = currentTimestamp();
    _ = check dbClient->execute(`
        INSERT INTO task (id, list_id, title, due_date, priority, done, created_by, completed_by, created_at, updated_at)
        VALUES (${id}, ${listId}, ${title}, ${dueDate}, ${priority}, FALSE, ${createdBy}, NULL, ${createdAt}, ${createdAt})
    `);
    return {id, listId, title, dueDate, priority, done: false, createdBy, completedBy: (), createdAt, updatedAt: createdAt};
}

function getTaskById(string taskId) returns Task?|error {
    Task|sql:Error result = dbClient->queryRow(`
        SELECT id, list_id AS "listId", title, due_date AS "dueDate", priority, done,
               created_by AS "createdBy", completed_by AS "completedBy", created_at AS "createdAt", updated_at AS "updatedAt"
        FROM task WHERE id = ${taskId}
    `);
    if result is sql:NoRowsError {
        return ();
    }
    if result is sql:Error {
        return result;
    }
    return result;
}

// PATCH semantics: a field absent from the payload leaves the column
// unchanged; `done` flipping to true stamps completedBy with the caller,
// flipping back to false clears it.
function updateTaskRow(Task current, TaskUpdateRequest payload, string callerId) returns Task|error {
    string title = payload?.title ?: current.title;
    string priority = payload?.priority ?: current.priority;
    string? dueDate = current.dueDate;
    if payload.hasKey("dueDate") {
        dueDate = payload?.dueDate;
    }
    boolean done = current.done;
    string? completedBy = current.completedBy;
    boolean? doneValue = payload?.done;
    if doneValue is boolean {
        if doneValue && !current.done {
            completedBy = callerId;
        } else if !doneValue {
            completedBy = ();
        }
        done = doneValue;
    }
    string updatedAt = currentTimestamp();
    _ = check dbClient->execute(`
        UPDATE task SET title = ${title}, due_date = ${dueDate}, priority = ${priority},
               done = ${done}, completed_by = ${completedBy}, updated_at = ${updatedAt}
        WHERE id = ${current.id}
    `);
    return {
        id: current.id,
        listId: current.listId,
        title,
        dueDate,
        priority,
        done,
        createdBy: current.createdBy,
        completedBy,
        createdAt: current.createdAt,
        updatedAt
    };
}

function deleteTaskRow(string taskId) returns error? {
    _ = check dbClient->execute(`DELETE FROM task WHERE id = ${taskId}`);
}
