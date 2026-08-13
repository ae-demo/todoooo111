import createClient from "openapi-fetch";
import type { components, paths } from "./generated/todo-api";
import { env } from "./env";
import { getAccessToken, getCurrentUserId, signIn } from "./auth";

const BASE_URL = env.TODO_API_URL;

export const todoApi = createClient<paths>({ baseUrl: BASE_URL });

todoApi.use({
  async onRequest({ request }) {
    const token = await getAccessToken();
    if (token) {
      request.headers.set("Authorization", `Bearer ${token}`);
    }
    return request;
  },
  async onResponse({ response }) {
    // An expired/invalid token: currentUser() already renews silently, so a
    // 401 here means there truly is no usable session — restart sign-in.
    if (response.status === 401) {
      await signIn();
    }
    return response;
  },
});

// todo-api's contract marks X-User-Id required on every operation ("caller
// identity injected by the gateway from the validated token"): the gateway
// derives and overwrites this header itself when it forwards the request,
// so the value supplied here is a type-satisfying placeholder only — never
// the value todo-api actually authorizes on.
export async function userIdHeader(): Promise<{ "X-User-Id": string }> {
  const userId = await getCurrentUserId();
  if (!userId) {
    throw new Error("Not signed in");
  }
  return { "X-User-Id": userId };
}

export type List = components["schemas"]["List"];
export type ListMember = components["schemas"]["ListMember"];
export type Invitation = components["schemas"]["Invitation"];
export type Task = components["schemas"]["Task"];
export type Priority = Task["priority"];

function unwrap<T>(result: { data?: T; error?: unknown }, action: string): T {
  if (result.error) {
    const err = result.error as { message?: string } | undefined;
    throw new Error(err?.message ?? `${action} failed`);
  }
  if (result.data === undefined) {
    throw new Error(`${action} returned no data`);
  }
  return result.data;
}

export async function fetchLists(): Promise<{ count: number; data: List[] }> {
  const res = await todoApi.GET("/lists", {
    params: { header: await userIdHeader(), query: { limit: 100 } },
  });
  return unwrap(res, "list lists");
}

export async function createList(name: string): Promise<List> {
  const res = await todoApi.POST("/lists", {
    params: { header: await userIdHeader() },
    body: { name },
  });
  return unwrap(res, "create list");
}

export async function fetchList(listId: string): Promise<List> {
  const res = await todoApi.GET("/lists/{listId}", {
    params: { header: await userIdHeader(), path: { listId } },
  });
  return unwrap(res, "get list");
}

export async function leaveList(listId: string): Promise<void> {
  const res = await todoApi.POST("/lists/{listId}/leave", {
    params: { header: await userIdHeader(), path: { listId } },
  });
  if (res.error) {
    throw new Error("leave list failed");
  }
}

export async function fetchMembers(
  listId: string,
): Promise<{ count: number; data: ListMember[] }> {
  const res = await todoApi.GET("/lists/{listId}/members", {
    params: { header: await userIdHeader(), path: { listId }, query: { limit: 100 } },
  });
  return unwrap(res, "list members");
}

export async function removeMember(listId: string, memberId: string): Promise<void> {
  const res = await todoApi.DELETE("/lists/{listId}/members/{memberId}", {
    params: { header: await userIdHeader(), path: { listId, memberId } },
  });
  if (res.error) {
    throw new Error("remove member failed");
  }
}

export async function inviteByEmail(listId: string, invitedEmail: string): Promise<Invitation> {
  const res = await todoApi.POST("/lists/{listId}/invitations", {
    params: { header: await userIdHeader(), path: { listId } },
    body: { invitedEmail },
  });
  return unwrap(res, "create invitation");
}

export async function fetchMyInvitations(): Promise<{ count: number; data: Invitation[] }> {
  const res = await todoApi.GET("/invitations", {
    params: { header: await userIdHeader() },
  });
  return unwrap(res, "list my invitations");
}

export async function acceptInvitation(invitationId: string): Promise<ListMember> {
  const res = await todoApi.POST("/invitations/{invitationId}/accept", {
    params: { header: await userIdHeader(), path: { invitationId } },
  });
  return unwrap(res, "accept invitation");
}

export async function declineInvitation(invitationId: string): Promise<void> {
  const res = await todoApi.POST("/invitations/{invitationId}/decline", {
    params: { header: await userIdHeader(), path: { invitationId } },
  });
  if (res.error) {
    throw new Error("decline invitation failed");
  }
}

export type TaskSort = "dueDate" | "priority";

export async function fetchTasks(
  listId: string,
  filters: { sort?: TaskSort; priority?: Priority; done?: boolean } = {},
): Promise<{ count: number; data: Task[] }> {
  const res = await todoApi.GET("/lists/{listId}/tasks", {
    params: {
      header: await userIdHeader(),
      path: { listId },
      query: { limit: 100, sort: filters.sort, priority: filters.priority, done: filters.done },
    },
  });
  return unwrap(res, "list tasks");
}

export async function createTask(
  listId: string,
  task: { title: string; dueDate?: string | null; priority: Priority },
): Promise<Task> {
  const res = await todoApi.POST("/lists/{listId}/tasks", {
    params: { header: await userIdHeader(), path: { listId } },
    body: task,
  });
  return unwrap(res, "create task");
}

export async function updateTask(
  taskId: string,
  update: { title?: string; dueDate?: string | null; priority?: Priority; done?: boolean },
): Promise<Task> {
  const res = await todoApi.PATCH("/tasks/{taskId}", {
    params: { header: await userIdHeader(), path: { taskId } },
    body: update,
  });
  return unwrap(res, "update task");
}

export async function deleteTask(taskId: string): Promise<void> {
  const res = await todoApi.DELETE("/tasks/{taskId}", {
    params: { header: await userIdHeader(), path: { taskId } },
  });
  if (res.error) {
    throw new Error("delete task failed");
  }
}
