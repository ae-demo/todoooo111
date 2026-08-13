// Record types mirror the OpenAPI schemas exactly. Timestamp/date columns
// are stored as canonical ISO-8601 text (see util.bal), so a row read back
// from the database already has the exact shape the API returns — the same
// records double as SQL row-mapping targets.

public type List record {|
    string id;
    string name;
    string ownerId;
    string createdAt;
|};

public type ListMember record {|
    string id;
    string listId;
    string userId;
    string email;
    string role;
    string joinedAt;
|};

public type Invitation record {|
    string id;
    string listId;
    string invitedEmail;
    string invitedBy;
    string status;
    string createdAt;
|};

public type Task record {|
    string id;
    string listId;
    string title;
    string? dueDate;
    string priority;
    boolean done;
    string createdBy;
    string? completedBy;
    string createdAt;
    string updatedAt;
|};

// Request payloads.

public type ListCreateRequest record {|
    string name;
|};

public type InvitationCreateRequest record {|
    string invitedEmail;
|};

public type TaskCreateRequest record {|
    string title;
    string? dueDate?;
    string priority;
|};

public type TaskUpdateRequest record {|
    string title?;
    string? dueDate?;
    string priority?;
    boolean done?;
|};

// Paginated response envelopes — one per collection resource, per the
// pagination envelope in openapi.yaml.

public type ListsPage record {|
    int count;
    string? next;
    string? previous;
    List[] data;
|};

public type MembersPage record {|
    int count;
    string? next;
    string? previous;
    ListMember[] data;
|};

public type InvitationsPage record {|
    int count;
    string? next;
    string? previous;
    Invitation[] data;
|};

public type TasksPage record {|
    int count;
    string? next;
    string? previous;
    Task[] data;
|};

// Shared error body — every 4xx/5xx response uses this shape.
public type ApiError record {|
    int code;
    string message;
    string description?;
    string moreInfo?;
|};

// Effective role the caller has on a list, resolved per request.
public type Role "owner"|"member"|"none";
