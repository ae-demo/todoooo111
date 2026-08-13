import ballerina/http;

// Listener bound to all interfaces — a config-bound host would answer only
// from inside the container and be unreachable once deployed.
listener http:Listener httpListener = new (9090);

// Endpoints with no declared pagination params in openapi.yaml (the two
// invitation "listing" endpoints) return every matching row as one page.
const int UNPAGINATED_LIMIT = 100000;

function requireCallerId(string? headerValue) returns string|http:Unauthorized {
    if headerValue is string && headerValue.trim().length() > 0 {
        return headerValue;
    }
    ApiError err = {code: 401, message: "missing or invalid caller identity"};
    return {body: err};
}

function isValidEmail(string value) returns boolean {
    string trimmed = value.trim();
    if trimmed.length() == 0 {
        return false;
    }
    int? atIndex = trimmed.indexOf("@");
    return atIndex is int;
}

service / on httpListener {

    // -- Lists ---------------------------------------------------------

    resource function get lists(@http:Header string? x\-user\-id, int 'limit = 20, int offset = 0)
            returns ListsPage|http:Unauthorized|http:InternalServerError {
        string|http:Unauthorized callerResult = requireCallerId(x\-user\-id);
        if callerResult is http:Unauthorized {
            return callerResult;
        }
        string callerId = callerResult;
        int pageLimit = clamp('limit, 0, 100);
        int pageOffset = offset < 0 ? 0 : offset;

        int|error count = countCallerLists(callerId);
        if count is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load lists"}};
        }
        List[]|error data = queryCallerLists(callerId, pageLimit, pageOffset);
        if data is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load lists"}};
        }
        [string?, string?] links = buildPageLinks("/lists", {}, count, pageLimit, pageOffset);
        return {count, next: links[0], previous: links[1], data};
    }

    resource function post lists(@http:Header string? x\-user\-id, ListCreateRequest payload)
            returns http:Created|http:BadRequest|http:Unauthorized|http:InternalServerError {
        string|http:Unauthorized callerResult = requireCallerId(x\-user\-id);
        if callerResult is http:Unauthorized {
            return callerResult;
        }
        string callerId = callerResult;
        if payload.name.trim().length() == 0 {
            return <http:BadRequest>{body: badRequestError("name is required")};
        }
        List|error created = createListRow(callerId, payload.name);
        if created is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to create list"}};
        }
        return <http:Created>{body: created};
    }

    resource function get lists/[string listId](@http:Header string? x\-user\-id)
            returns List|http:Unauthorized|http:NotFound|http:InternalServerError {
        string|http:Unauthorized callerResult = requireCallerId(x\-user\-id);
        if callerResult is http:Unauthorized {
            return callerResult;
        }
        string callerId = callerResult;
        List?|error listResult = getListById(listId);
        if listResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load list"}};
        }
        List? listRow = listResult;
        if listRow is () {
            return <http:NotFound>{body: notFoundError("list not found")};
        }
        Role|error roleResult = resolveRole(listRow, callerId);
        if roleResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to resolve role"}};
        }
        if roleResult == "none" {
            return <http:NotFound>{body: notFoundError("list not found")};
        }
        return listRow;
    }

    resource function delete lists/[string listId](@http:Header string? x\-user\-id)
            returns http:NoContent|http:Unauthorized|http:Forbidden|http:NotFound|http:InternalServerError {
        string|http:Unauthorized callerResult = requireCallerId(x\-user\-id);
        if callerResult is http:Unauthorized {
            return callerResult;
        }
        string callerId = callerResult;
        List?|error listResult = getListById(listId);
        if listResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load list"}};
        }
        List? listRow = listResult;
        if listRow is () {
            return <http:NotFound>{body: notFoundError("list not found")};
        }
        Role|error roleResult = resolveRole(listRow, callerId);
        if roleResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to resolve role"}};
        }
        if roleResult == "none" {
            return <http:NotFound>{body: notFoundError("list not found")};
        }
        if roleResult == "member" {
            return <http:Forbidden>{body: forbiddenError("only the owner may delete this list")};
        }
        error? deleteResult = deleteListRow(listId);
        if deleteResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to delete list"}};
        }
        return http:NO_CONTENT;
    }

    // -- Membership ------------------------------------------------------

    resource function get lists/[string listId]/members(@http:Header string? x\-user\-id, int 'limit = 20, int offset = 0)
            returns MembersPage|http:Unauthorized|http:NotFound|http:InternalServerError {
        string|http:Unauthorized callerResult = requireCallerId(x\-user\-id);
        if callerResult is http:Unauthorized {
            return callerResult;
        }
        string callerId = callerResult;
        List?|error listResult = getListById(listId);
        if listResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load list"}};
        }
        List? listRow = listResult;
        if listRow is () {
            return <http:NotFound>{body: notFoundError("list not found")};
        }
        Role|error roleResult = resolveRole(listRow, callerId);
        if roleResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to resolve role"}};
        }
        if roleResult == "none" {
            return <http:NotFound>{body: notFoundError("list not found")};
        }
        int pageLimit = clamp('limit, 0, 100);
        int pageOffset = offset < 0 ? 0 : offset;
        MembersPage|error page = buildMembersPage(listRow, pageLimit, pageOffset);
        if page is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load members"}};
        }
        return page;
    }

    resource function delete lists/[string listId]/members/[string memberId](@http:Header string? x\-user\-id)
            returns http:NoContent|http:Unauthorized|http:Forbidden|http:NotFound|http:InternalServerError {
        string|http:Unauthorized callerResult = requireCallerId(x\-user\-id);
        if callerResult is http:Unauthorized {
            return callerResult;
        }
        string callerId = callerResult;
        List?|error listResult = getListById(listId);
        if listResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load list"}};
        }
        List? listRow = listResult;
        if listRow is () {
            return <http:NotFound>{body: notFoundError("list not found")};
        }
        Role|error roleResult = resolveRole(listRow, callerId);
        if roleResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to resolve role"}};
        }
        if roleResult == "none" {
            return <http:NotFound>{body: notFoundError("list not found")};
        }
        if roleResult == "member" {
            return <http:Forbidden>{body: forbiddenError("only the owner may remove members")};
        }
        int|error affected = deleteMemberById(listId, memberId);
        if affected is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to remove member"}};
        }
        if affected == 0 {
            return <http:NotFound>{body: notFoundError("member not found")};
        }
        return http:NO_CONTENT;
    }

    resource function post lists/[string listId]/leave(@http:Header string? x\-user\-id)
            returns http:NoContent|http:Unauthorized|http:NotFound|http:InternalServerError {
        string|http:Unauthorized callerResult = requireCallerId(x\-user\-id);
        if callerResult is http:Unauthorized {
            return callerResult;
        }
        string callerId = callerResult;
        List?|error listResult = getListById(listId);
        if listResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load list"}};
        }
        List? listRow = listResult;
        if listRow is () {
            return <http:NotFound>{body: notFoundError("list not found")};
        }
        Role|error roleResult = resolveRole(listRow, callerId);
        if roleResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to resolve role"}};
        }
        // Only a plain member has a membership row to leave; the owner has
        // none (see members.bal), and openapi.yaml declares no 403 for this
        // operation, so both "no relation" and "is the owner" report 404.
        if roleResult != "member" {
            return <http:NotFound>{body: notFoundError("list not found")};
        }
        int|error affected = deleteMembershipByUser(listId, callerId);
        if affected is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to leave list"}};
        }
        if affected == 0 {
            return <http:NotFound>{body: notFoundError("list not found")};
        }
        return http:NO_CONTENT;
    }

    // -- Invitations -------------------------------------------------------

    resource function get lists/[string listId]/invitations(@http:Header string? x\-user\-id)
            returns InvitationsPage|http:Unauthorized|http:Forbidden|http:NotFound|http:InternalServerError {
        string|http:Unauthorized callerResult = requireCallerId(x\-user\-id);
        if callerResult is http:Unauthorized {
            return callerResult;
        }
        string callerId = callerResult;
        List?|error listResult = getListById(listId);
        if listResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load list"}};
        }
        List? listRow = listResult;
        if listRow is () {
            return <http:NotFound>{body: notFoundError("list not found")};
        }
        Role|error roleResult = resolveRole(listRow, callerId);
        if roleResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to resolve role"}};
        }
        // security.md: a caller with no relation to the list never learns it
        // exists (404); a member who isn't the owner is refused the action
        // (403). openapi.yaml omits 404 for this operation, but the security
        // design's no-bare-403-for-strangers rule is the acceptance bar.
        if roleResult == "none" {
            return <http:NotFound>{body: notFoundError("list not found")};
        }
        if roleResult == "member" {
            return <http:Forbidden>{body: forbiddenError("only the owner may view invitations")};
        }
        int|error count = countPendingListInvitations(listId);
        if count is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load invitations"}};
        }
        Invitation[]|error data = queryPendingListInvitations(listId, UNPAGINATED_LIMIT, 0);
        if data is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load invitations"}};
        }
        return {count, next: (), previous: (), data};
    }

    resource function post lists/[string listId]/invitations(@http:Header string? x\-user\-id, InvitationCreateRequest payload)
            returns http:Created|http:BadRequest|http:Unauthorized|http:Forbidden|http:NotFound|http:InternalServerError {
        string|http:Unauthorized callerResult = requireCallerId(x\-user\-id);
        if callerResult is http:Unauthorized {
            return callerResult;
        }
        string callerId = callerResult;
        List?|error listResult = getListById(listId);
        if listResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load list"}};
        }
        List? listRow = listResult;
        if listRow is () {
            return <http:NotFound>{body: notFoundError("list not found")};
        }
        Role|error roleResult = resolveRole(listRow, callerId);
        if roleResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to resolve role"}};
        }
        if roleResult == "none" {
            return <http:NotFound>{body: notFoundError("list not found")};
        }
        if roleResult == "member" {
            return <http:Forbidden>{body: forbiddenError("only the owner may invite members")};
        }
        if !isValidEmail(payload.invitedEmail) {
            return <http:BadRequest>{body: badRequestError("invitedEmail must be a valid email address")};
        }
        Invitation|error created = createInvitationRow(listId, payload.invitedEmail, callerId);
        if created is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to create invitation"}};
        }
        return <http:Created>{body: created};
    }

    resource function get invitations(@http:Header string? x\-user\-id)
            returns InvitationsPage|http:Unauthorized|http:InternalServerError {
        string|http:Unauthorized callerResult = requireCallerId(x\-user\-id);
        if callerResult is http:Unauthorized {
            return callerResult;
        }
        string callerId = callerResult;
        string email = callerEmail(callerId);
        int|error count = countPendingMyInvitations(email);
        if count is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load invitations"}};
        }
        Invitation[]|error data = queryPendingMyInvitations(email, UNPAGINATED_LIMIT, 0);
        if data is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load invitations"}};
        }
        return {count, next: (), previous: (), data};
    }

    resource function post invitations/[string invitationId]/accept(@http:Header string? x\-user\-id)
            returns http:Ok|http:Unauthorized|http:Forbidden|http:NotFound|http:InternalServerError {
        string|http:Unauthorized callerResult = requireCallerId(x\-user\-id);
        if callerResult is http:Unauthorized {
            return callerResult;
        }
        string callerId = callerResult;
        Invitation?|error invitationResult = getInvitationById(invitationId);
        if invitationResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load invitation"}};
        }
        Invitation? invitation = invitationResult;
        if invitation is () || invitation.status != "pending" {
            return <http:NotFound>{body: notFoundError("invitation not found")};
        }
        if invitation.invitedEmail != callerEmail(callerId) {
            return <http:Forbidden>{body: forbiddenError("this invitation is not addressed to you")};
        }
        ListMember|error member = insertMember(invitation.listId, callerId, invitation.invitedEmail);
        if member is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to accept invitation"}};
        }
        error? statusResult = updateInvitationStatus(invitationId, "accepted");
        if statusResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to accept invitation"}};
        }
        return <http:Ok>{body: member};
    }

    resource function post invitations/[string invitationId]/decline(@http:Header string? x\-user\-id)
            returns http:NoContent|http:Unauthorized|http:Forbidden|http:NotFound|http:InternalServerError {
        string|http:Unauthorized callerResult = requireCallerId(x\-user\-id);
        if callerResult is http:Unauthorized {
            return callerResult;
        }
        string callerId = callerResult;
        Invitation?|error invitationResult = getInvitationById(invitationId);
        if invitationResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load invitation"}};
        }
        Invitation? invitation = invitationResult;
        if invitation is () || invitation.status != "pending" {
            return <http:NotFound>{body: notFoundError("invitation not found")};
        }
        if invitation.invitedEmail != callerEmail(callerId) {
            return <http:Forbidden>{body: forbiddenError("this invitation is not addressed to you")};
        }
        error? statusResult = updateInvitationStatus(invitationId, "declined");
        if statusResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to decline invitation"}};
        }
        return http:NO_CONTENT;
    }

    // -- Tasks -----------------------------------------------------------

    resource function get lists/[string listId]/tasks(@http:Header string? x\-user\-id, int 'limit = 20, int offset = 0,
            string? sort = (), string? priority = (), boolean? done = ())
            returns TasksPage|http:Unauthorized|http:NotFound|http:InternalServerError {
        string|http:Unauthorized callerResult = requireCallerId(x\-user\-id);
        if callerResult is http:Unauthorized {
            return callerResult;
        }
        string callerId = callerResult;
        List?|error listResult = getListById(listId);
        if listResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load list"}};
        }
        List? listRow = listResult;
        if listRow is () {
            return <http:NotFound>{body: notFoundError("list not found")};
        }
        Role|error roleResult = resolveRole(listRow, callerId);
        if roleResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to resolve role"}};
        }
        if roleResult == "none" {
            return <http:NotFound>{body: notFoundError("list not found")};
        }
        int pageLimit = clamp('limit, 0, 100);
        int pageOffset = offset < 0 ? 0 : offset;
        int|error count = countTasks(listId, priority, done);
        if count is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load tasks"}};
        }
        Task[]|error data = queryTasks(listId, priority, done, sort, pageLimit, pageOffset);
        if data is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load tasks"}};
        }
        map<string> extraParams = {};
        if sort is string {
            extraParams["sort"] = sort;
        }
        if priority is string {
            extraParams["priority"] = priority;
        }
        if done is boolean {
            extraParams["done"] = done.toString();
        }
        [string?, string?] links = buildPageLinks("/lists/" + listId + "/tasks", extraParams, count, pageLimit, pageOffset);
        return {count, next: links[0], previous: links[1], data};
    }

    resource function post lists/[string listId]/tasks(@http:Header string? x\-user\-id, TaskCreateRequest payload)
            returns http:Created|http:BadRequest|http:Unauthorized|http:NotFound|http:InternalServerError {
        string|http:Unauthorized callerResult = requireCallerId(x\-user\-id);
        if callerResult is http:Unauthorized {
            return callerResult;
        }
        string callerId = callerResult;
        List?|error listResult = getListById(listId);
        if listResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load list"}};
        }
        List? listRow = listResult;
        if listRow is () {
            return <http:NotFound>{body: notFoundError("list not found")};
        }
        Role|error roleResult = resolveRole(listRow, callerId);
        if roleResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to resolve role"}};
        }
        if roleResult == "none" {
            return <http:NotFound>{body: notFoundError("list not found")};
        }
        if payload.title.trim().length() == 0 {
            return <http:BadRequest>{body: badRequestError("title is required")};
        }
        if !isValidPriority(payload.priority) {
            return <http:BadRequest>{body: badRequestError("priority must be one of low, medium, high")};
        }
        Task|error created = createTaskRow(listId, callerId, payload);
        if created is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to create task"}};
        }
        return <http:Created>{body: created};
    }

    resource function patch tasks/[string taskId](@http:Header string? x\-user\-id, TaskUpdateRequest payload)
            returns Task|http:BadRequest|http:Unauthorized|http:NotFound|http:InternalServerError {
        string|http:Unauthorized callerResult = requireCallerId(x\-user\-id);
        if callerResult is http:Unauthorized {
            return callerResult;
        }
        string callerId = callerResult;
        Task?|error taskResult = getTaskById(taskId);
        if taskResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load task"}};
        }
        Task? task = taskResult;
        if task is () {
            return <http:NotFound>{body: notFoundError("task not found")};
        }
        List?|error listResult = getListById(task.listId);
        if listResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load list"}};
        }
        List? listRow = listResult;
        if listRow is () {
            return <http:NotFound>{body: notFoundError("task not found")};
        }
        Role|error roleResult = resolveRole(listRow, callerId);
        if roleResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to resolve role"}};
        }
        if roleResult == "none" {
            return <http:NotFound>{body: notFoundError("task not found")};
        }
        string? titleValue = payload?.title;
        if titleValue is string && titleValue.trim().length() == 0 {
            return <http:BadRequest>{body: badRequestError("title must not be empty")};
        }
        string? priorityValue = payload?.priority;
        if priorityValue is string && !isValidPriority(priorityValue) {
            return <http:BadRequest>{body: badRequestError("priority must be one of low, medium, high")};
        }
        Task|error updated = updateTaskRow(task, payload, callerId);
        if updated is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to update task"}};
        }
        return updated;
    }

    resource function delete tasks/[string taskId](@http:Header string? x\-user\-id)
            returns http:NoContent|http:Unauthorized|http:NotFound|http:InternalServerError {
        string|http:Unauthorized callerResult = requireCallerId(x\-user\-id);
        if callerResult is http:Unauthorized {
            return callerResult;
        }
        string callerId = callerResult;
        Task?|error taskResult = getTaskById(taskId);
        if taskResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load task"}};
        }
        Task? task = taskResult;
        if task is () {
            return <http:NotFound>{body: notFoundError("task not found")};
        }
        List?|error listResult = getListById(task.listId);
        if listResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to load list"}};
        }
        List? listRow = listResult;
        if listRow is () {
            return <http:NotFound>{body: notFoundError("task not found")};
        }
        Role|error roleResult = resolveRole(listRow, callerId);
        if roleResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to resolve role"}};
        }
        if roleResult == "none" {
            return <http:NotFound>{body: notFoundError("task not found")};
        }
        error? deleteResult = deleteTaskRow(taskId);
        if deleteResult is error {
            return <http:InternalServerError>{body: {code: 500, message: "failed to delete task"}};
        }
        return http:NO_CONTENT;
    }
}
