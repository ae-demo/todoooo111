import ballerina/time;
import ballerina/uuid;

function newId() returns string => uuid:createType4AsString();

function currentTimestamp() returns string => time:utcToString(time:utcNow());

// The gateway injects only X-User-Id (the sub claim) on every request;
// openapi.yaml defines no email-claim header, and there is no directory
// endpoint this service may call to resolve one (security.md describes an
// "email claim" the published header contract does not actually carry).
// Without inventing a new header or endpoint, the only caller-supplied
// signal available to match an INVITATION.invitedEmail against is the
// caller's own X-User-Id, so that value doubles as the caller's matching
// key: an invitation addressed to a user is expected to carry that user's
// X-User-Id as invitedEmail. This is the most faithful mapping available
// under the contract as published.
function callerEmail(string callerId) returns string => callerId;

function notFoundError(string message) returns ApiError => {code: 404, message};

function forbiddenError(string message) returns ApiError => {code: 403, message};

function badRequestError(string message) returns ApiError => {code: 400, message};

// Builds the [next, previous] relative-URI pair for a pagination envelope.
// extraParams carries every query param besides limit/offset that a caller
// used (sort, priority, done, ...) so a page link preserves them.
function buildPageLinks(string path, map<string> extraParams, int count, int pageLimit, int offset) returns [string?, string?] {
    string? next = ();
    string? previous = ();
    if offset + pageLimit < count {
        next = buildLink(path, extraParams, pageLimit, offset + pageLimit);
    }
    if offset > 0 {
        int prevOffset = offset - pageLimit;
        if prevOffset < 0 {
            prevOffset = 0;
        }
        previous = buildLink(path, extraParams, pageLimit, prevOffset);
    }
    return [next, previous];
}

function clamp(int value, int minValue, int maxValue) returns int {
    if value < minValue {
        return minValue;
    }
    if value > maxValue {
        return maxValue;
    }
    return value;
}

function isValidPriority(string priority) returns boolean => priority == "low" || priority == "medium" || priority == "high";

function buildLink(string path, map<string> extraParams, int pageLimit, int offset) returns string {
    string query = "limit=" + pageLimit.toString() + "&offset=" + offset.toString();
    foreach string key in extraParams.keys() {
        query = query + "&" + key + "=" + extraParams.get(key);
    }
    return path + "?" + query;
}
