// Typed read of the platform-mounted runtime config. Values arrive at
// request time in window._env_ (populated by /env-config.js), never at
// build time — see react-webapp skill.
type Env = {
  TODO_API_URL: string;
  USER_AUTH_CLIENT_ID: string;
  USER_AUTH_ISSUER: string;
  USER_AUTH_JWKS_URL: string;
  USER_AUTH_SCOPES: string;
};

declare global {
  interface Window {
    _env_: Env;
  }
}

if (!window._env_) {
  throw new Error(
    "window._env_ not set — /env-config.js failed to load. " +
      "The platform mounts this file; if you see this locally, host " +
      "/env-config.js from your dev server.",
  );
}

function required(key: keyof Env): string {
  const value = window._env_[key];
  if (!value) {
    throw new Error(`window._env_.${key} is not set`);
  }
  return value;
}

export const env: Env = {
  TODO_API_URL: required("TODO_API_URL"),
  USER_AUTH_CLIENT_ID: required("USER_AUTH_CLIENT_ID"),
  USER_AUTH_ISSUER: required("USER_AUTH_ISSUER"),
  USER_AUTH_JWKS_URL: required("USER_AUTH_JWKS_URL"),
  USER_AUTH_SCOPES: required("USER_AUTH_SCOPES"),
};
