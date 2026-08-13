// Single place every other module reads DB configuration through. Every
// value has a sensible local default so the service starts with no
// required environment variables; the platform overrides them at deploy
// time via the todo-db dependency's envBindings.
import ballerina/os;

configurable string dbHostEnv = os:getEnv("TODO_DB_HOST");
configurable string dbPortEnv = os:getEnv("TODO_DB_PORT");
configurable string dbUserEnv = os:getEnv("TODO_DB_USER");
configurable string dbPasswordEnv = os:getEnv("TODO_DB_PASSWORD");
configurable string dbNameEnv = os:getEnv("TODO_DB_DBNAME");

final string dbHost = dbHostEnv.length() > 0 ? dbHostEnv : "localhost";
final int dbPort = parsePort(dbPortEnv, 5432);
final string dbUser = dbUserEnv.length() > 0 ? dbUserEnv : "todo";
final string dbPassword = dbPasswordEnv.length() > 0 ? dbPasswordEnv : "todo";
final string dbName = dbNameEnv.length() > 0 ? dbNameEnv : "todo";

function parsePort(string portStr, int fallback) returns int {
    int|error parsed = int:fromString(portStr);
    if parsed is int {
        return parsed;
    }
    return fallback;
}
