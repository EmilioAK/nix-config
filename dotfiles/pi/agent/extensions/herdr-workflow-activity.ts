// Bridge pi-dynamic-workflows background runs into Herdr's Pi integration.
//
// pi-dynamic-workflows 3.4.1 continues background work after Pi's foreground
// agent settles. Pi's agent_start/agent_end events therefore cannot represent
// that work by themselves. The workflow package does not currently publish a
// shared lifecycle event, so this companion extension watches its authoritative
// persisted run state and publishes keyed, owner-scoped activity snapshots.

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { createHash } from "node:crypto";
import { promises as fs } from "node:fs";
import { homedir } from "node:os";
import { basename, join, resolve } from "node:path";

const ACTIVITY_CHANNEL = "herdr:activity";
const ACTIVITY_VERSION = 1;
const ACTIVITY_SOURCE = "@quintinshaw/pi-dynamic-workflows";
const RUNTIME_KEY = Symbol.for("nix-config:herdr-workflow-activity-runtime:v1");
const pollMs = parseDurationEnv("HERDR_PI_WORKFLOW_POLL_MS", 500);

type ActivityRecord = {
  id: string;
  hold: "working" | "blocked";
  label?: string;
};

type PersistedRun = {
  runId?: unknown;
  workflowName?: unknown;
  sessionId?: unknown;
  status?: unknown;
  pauseReason?: unknown;
  updatedAt?: unknown;
};

type CachedRun = {
  mtimeMs: number;
  size: number;
  ino: number;
  run: PersistedRun;
};

type BridgeRuntime = {
  bus?: ExtensionAPI["events"];
  sessionId?: string;
  activities: ActivityRecord[];
  fingerprint: string;
};

const globalRoot = globalThis as typeof globalThis & {
  [RUNTIME_KEY]?: BridgeRuntime;
};
const runtime: BridgeRuntime =
  globalRoot[RUNTIME_KEY] ??
  (globalRoot[RUNTIME_KEY] = {
    activities: [],
    fingerprint: "[]",
  });

function parseDurationEnv(name: string, fallback: number): number {
  const raw = process.env[name];
  if (!raw) return fallback;
  const parsed = Number.parseInt(raw, 10);
  return Number.isFinite(parsed) && parsed >= 100 ? parsed : fallback;
}

function projectRunsDirs(cwd: string): string[] {
  const projectPath = resolve(cwd);
  const slug =
    basename(projectPath)
      .toLowerCase()
      .replace(/[^a-z0-9._-]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 48) || "project";
  const hash = createHash("sha256").update(projectPath).digest("hex").slice(0, 12);
  return [
    join(homedir(), ".pi", "workflows", "projects", `${slug}-${hash}`, "runs"),
    resolve(projectPath, ".pi", "workflows", "runs"),
  ];
}

function currentSessionId(ctx: ExtensionContext): string | undefined {
  try {
    const id = ctx.sessionManager?.getSessionId?.();
    return typeof id === "string" && id.length > 0 ? id : undefined;
  } catch {
    return undefined;
  }
}

function emitSync(): void {
  runtime.bus?.emit(ACTIVITY_CHANNEL, {
    version: ACTIVITY_VERSION,
    op: "sync",
    source: ACTIVITY_SOURCE,
    activities: runtime.activities,
  });
}

function activityFingerprint(activities: ActivityRecord[]): string {
  return JSON.stringify(
    [...activities].sort((left, right) => left.id.localeCompare(right.id)),
  );
}

function setActivities(activities: ActivityRecord[], force = false): void {
  const fingerprint = activityFingerprint(activities);
  runtime.activities = activities;
  if (!force && fingerprint === runtime.fingerprint) return;
  runtime.fingerprint = fingerprint;
  emitSync();
}

async function listRunFiles(dir: string): Promise<string[]> {
  try {
    const names = await fs.readdir(dir);
    return names.filter((name) => name.endsWith(".json")).map((name) => join(dir, name));
  } catch {
    return [];
  }
}

async function readRun(path: string, cache: Map<string, CachedRun>): Promise<PersistedRun | undefined> {
  try {
    const previous = cache.get(path);
    // Completed and aborted runs cannot resume. Their filenames are still
    // checked by readdir for deletion, but their immutable contents do not
    // need another stat on every poll.
    if (previous?.run.status === "completed" || previous?.run.status === "aborted") {
      return previous.run;
    }
    const stat = await fs.stat(path);
    if (
      previous &&
      previous.mtimeMs === stat.mtimeMs &&
      previous.size === stat.size &&
      previous.ino === stat.ino
    ) {
      return previous.run;
    }
    const parsed = JSON.parse(await fs.readFile(path, "utf8")) as PersistedRun;
    cache.set(path, {
      mtimeMs: stat.mtimeMs,
      size: stat.size,
      ino: stat.ino,
      run: parsed,
    });
    return parsed;
  } catch {
    // Atomic workflow writes normally keep the primary JSON valid. If a scan
    // catches a transient replacement window, retain the last known state and
    // let the next poll reconcile it rather than flashing Idle.
    return cache.get(path)?.run;
  }
}

function newerRun(left: PersistedRun | undefined, right: PersistedRun): PersistedRun {
  if (!left) return right;
  const leftUpdated = typeof left.updatedAt === "string" ? Date.parse(left.updatedAt) : 0;
  const rightUpdated = typeof right.updatedAt === "string" ? Date.parse(right.updatedAt) : 0;
  return rightUpdated >= leftUpdated ? right : left;
}

function activitiesFromRuns(runs: Iterable<PersistedRun>, sessionId: string | undefined): ActivityRecord[] {
  if (!sessionId) return [];
  const activities: ActivityRecord[] = [];
  for (const run of runs) {
    if (run.sessionId !== sessionId || typeof run.runId !== "string") continue;
    const label = typeof run.workflowName === "string" ? run.workflowName : "workflow";
    if (run.status === "running") {
      activities.push({ id: run.runId, hold: "working", label });
    } else if (run.status === "paused" && run.pauseReason === "usage_limit") {
      activities.push({ id: run.runId, hold: "blocked", label: `${label}: usage limit` });
    }
  }
  return activities;
}

export default function herdrWorkflowActivity(pi: ExtensionAPI): void {
  runtime.bus = pi.events;

  let runDirs: string[] = [];
  let activeSessionId: string | undefined;
  let timer: ReturnType<typeof setInterval> | undefined;
  let scanning = false;
  let scanAgain = false;
  let disposed = false;
  const cache = new Map<string, CachedRun>();

  async function scan(force = false): Promise<void> {
    if (disposed || runDirs.length === 0) return;
    if (scanning) {
      scanAgain = scanAgain || force;
      return;
    }
    scanning = true;
    const scanSessionId = activeSessionId;
    const scanDirs = [...runDirs];
    try {
      const paths = (await Promise.all(scanDirs.map(listRunFiles))).flat();
      const seen = new Set(paths);
      for (const path of cache.keys()) {
        if (!seen.has(path)) cache.delete(path);
      }

      const byRunId = new Map<string, PersistedRun>();
      const runs = await Promise.all(paths.map((path) => readRun(path, cache)));
      for (const run of runs) {
        if (!run || typeof run.runId !== "string") continue;
        byRunId.set(run.runId, newerRun(byRunId.get(run.runId), run));
      }
      if (!disposed && scanSessionId === activeSessionId && scanSessionId === runtime.sessionId) {
        setActivities(activitiesFromRuns(byRunId.values(), scanSessionId), force);
      }
    } finally {
      scanning = false;
      if (!disposed && scanAgain) {
        const forceNext = scanAgain;
        scanAgain = false;
        void scan(forceNext);
      }
    }
  }

  const unsubscribe = pi.events.on(ACTIVITY_CHANNEL, (payload) => {
    if (!payload || typeof payload !== "object") return;
    const event = payload as Record<string, unknown>;
    if (event.version !== ACTIVITY_VERSION || event.op !== "sync-request") return;
    // Answer immediately from the last authoritative scan. During /reload this
    // handler is installed before session_start, so do not launch an empty-dir
    // scan that could erase the retained snapshot before paths are rebound.
    emitSync();
    if (runDirs.length > 0) void scan();
  });

  pi.on("session_start", async (_event, ctx) => {
    disposed = false;
    const nextSessionId = currentSessionId(ctx);
    const sessionChanged = runtime.sessionId !== nextSessionId;
    runtime.sessionId = nextSessionId;
    activeSessionId = nextSessionId;
    runDirs = projectRunsDirs(ctx.cwd);
    if (sessionChanged) setActivities([], true);
    await scan(true);
    if (timer) clearInterval(timer);
    timer = setInterval(() => void scan(), pollMs);
    timer.unref?.();
  });

  pi.on("session_shutdown", () => {
    disposed = true;
    if (timer) clearInterval(timer);
    timer = undefined;
    unsubscribe();
  });
}
