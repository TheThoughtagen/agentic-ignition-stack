/**
 * Gateway API helper — calls WebDev endpoints from Playwright tests.
 *
 * Uses the testing/tags endpoint for read/write (test-only),
 * and GatewayAPI endpoints for health checks and queries.
 */

// Allow self-signed certs — the local gateway uses a self-signed TLS cert.
// Playwright's `request` fixture handles this via `ignoreHTTPSErrors: true`,
// but raw Node `fetch` calls in this module need the env var.
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

const BASE =
  process.env.IGNITION_URL || "https://localhost:9043";
const WEBDEV = `${BASE}/system/webdev/example-project`;

async function post(path: string, body: unknown): Promise<unknown> {
  const res = await fetch(`${WEBDEV}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
    // @ts-expect-error -- Node 18+ fetch supports this for self-signed certs
    dispatcher: undefined,
  });
  if (!res.ok) {
    throw new Error(`${path} returned ${res.status}: ${await res.text()}`);
  }
  return res.json();
}

async function get(path: string): Promise<unknown> {
  const res = await fetch(`${WEBDEV}${path}`, {
    // @ts-expect-error
    dispatcher: undefined,
  });
  if (!res.ok) {
    throw new Error(`${path} returned ${res.status}: ${await res.text()}`);
  }
  return res.json();
}

// ── Tag operations (via testing/tags endpoint) ──

export interface TagValue {
  value: unknown;
  quality: string;
  good: boolean;
}

export interface WriteResult {
  path: string;
  success: boolean;
  quality: string;
}

/** Read tag values from the gateway. */
export async function readTags(
  paths: string[]
): Promise<Record<string, TagValue>> {
  const data = (await post("/testing/tags", { reads: paths })) as {
    values: Record<string, TagValue>;
  };
  return data.values;
}

/** Write tag values to the gateway. */
export async function writeTags(
  writes: Array<{ path: string; value: unknown }>
): Promise<WriteResult[]> {
  const data = (await post("/testing/tags", { writes })) as {
    results: WriteResult[];
  };
  return data.results;
}

/** Read a single tag and return its value (or null if bad quality). */
export async function readTag(path: string): Promise<unknown> {
  const values = await readTags([path]);
  const tag = values[path];
  return tag?.good ? tag.value : null;
}

/** Write a single tag value. */
export async function writeTag(
  path: string,
  value: unknown
): Promise<boolean> {
  const results = await writeTags([{ path, value }]);
  return results[0]?.success ?? false;
}

// ── Tag mirroring (OPC → memory copies for testing without PLC) ──
// To enable mirrorTags(), implement convert_to_memory_tags() in your gateway
// script library, then uncomment the mirror block in the testing/tags endpoint.

/** Delete a tag tree (cleanup after tests). */
export async function deleteMirror(path: string): Promise<boolean> {
  const data = (await post("/testing/tags", { deleteTags: path })) as {
    deleteTags: { success: boolean };
  };
  return data.deleteTags?.success ?? false;
}

// ── Gateway script invocation (call real Jython scripts from tests) ──

export interface ScriptResult {
  success: boolean;
  result?: unknown;
  error?: string;
}

/**
 * Call a gateway script function by its dotted path.
 * Executes the real Jython code on the gateway — no mocking.
 *
 * @example callScript("my.project.scripts.validate", [arg1, arg2])
 */
export async function callScript(
  path: string,
  args: unknown[] = [],
  kwargs: Record<string, unknown> = {}
): Promise<ScriptResult> {
  const data = (await post("/testing/tags", {
    script: { path, args, kwargs },
  })) as { script: ScriptResult };
  return data.script;
}

// ── Health checks ──

/** Quick connectivity check — returns true if gateway responds. */
export async function isGatewayReachable(): Promise<boolean> {
  try {
    const res = await fetch(`${BASE}/StatusPing`, {
      signal: AbortSignal.timeout(5_000),
      // @ts-expect-error
      dispatcher: undefined,
    });
    return res.ok;
  } catch {
    return false;
  }
}