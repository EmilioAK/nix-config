---
name: capisoft-investigate-jira-issue
description: >-
  Perform read-only, evidence-backed investigations of Capisoft Jira issues. Use
  when Emilio gives a terse issue-key request such as "Task: LP-360", "Task
  LP-360", or a Capisoft Jira key by itself; asks whether a Jira bug still
  exists; or asks what repository behavior, deployed runtime, or root cause an
  issue refers to. Inspect Jira, the matching repository, the current source and
  deployed revision, and AWS or Rancher/Kubernetes when relevant, without
  claiming, transitioning, commenting on, editing, or fixing the issue.
---

# Capisoft Jira Issue Investigation

Interpret `Task: <KEY-N>` as a complete request to diagnose that exact issue.
Treat the explicit key as confirmation of which issue to inspect. Do not ask the
user to confirm it again.

## Keep the investigation read-only

- Do not create, edit, assign, claim, comment on, link, or transition any Jira
  issue. In particular, do not move the issue to `In Progress`.
- Do not edit source or configuration, create branches or worktrees, commit,
  push, open pull requests, deploy, restart, scale, or otherwise change a
  repository or runtime.
- Do not invoke write-capable endpoints, jobs, queues, webhooks, or product
  actions merely to reproduce the report.
- Do not expose secrets, tokens, customer data, personal data, or unredacted
  sensitive log content. Never read Kubernetes Secret payloads.
- Allow isolated local tests only when they cannot touch shared services or
  persistent data. Disposable scratch files and clones under `/tmp` are
  permitted; never place them in the repository, and remove them when done.
- Treat this shortcut as investigation, not implementation. If the user later
  asks for a fix, handle that as a separate request with the normal claim and
  change workflow.

Read-only access does not make every command safe. Reject AWS, Rancher, or
Kubernetes operations with mutation semantics. Never use commands such as
`apply`, `create`, `delete`, `edit`, `patch`, `replace`, `set`, `scale`,
`rollout restart`, `cordon`, or `drain` during this workflow.

## 1. Load the issue and related Jira evidence

1. Read all applicable `AGENTS.md` files before investigating the repository.
2. Fetch only selected fields from the exact issue. Start with the key, summary,
   description, status, resolution, priority, labels, components, environment,
   links, attachment metadata, and created/updated dates. Never request `*all`.
   Fetch comments, changelog, attachment contents, assignee, or reporter only
   when that evidence can affect the diagnosis.
3. Inspect only relevant attachments. Treat screenshots and user reports as
   evidence of observed behavior, not proof of the current implementation.
4. Search the same Jira project for duplicates, closely related reports, and
   completed issues that may contain a prior fix or explanation. Request only
   key, summary, status, resolution, and updated date for a bounded result set,
   then expand individual issues only when relevant. Obey project-local
   exclusions and do not broaden into unrelated Jira projects.
5. Report the named issue key and title early. A terse `Task: KEY-N` prompt
   already identifies the work; do not pause for another confirmation.

Prefer connected Atlassian read tools. If they do not cover a required read,
first inspect the filenames and variable names under `~/.agents/secrets/`, then
source `jira.env` only for the command that needs it. Use the scoped token via
`JIRA_API_BASE_URL`, not the direct site URL, and never print authentication
material. If required Jira authentication is missing, expired, or rejected,
stop and ask the user to re-authenticate.

Extract the needed facts from tool responses. Do not echo raw Jira payloads or
unnecessary personal metadata into commentary, logs, or the final report.

## 2. Map the issue to repository behavior

1. Use the issue's project, components, links, description, and local
   instructions to identify the matching repository. Do not assume that the
   current directory is relevant merely because it is open.
2. For `LP-*`, read [references/legalpal.md](references/legalpal.md) before
   continuing.
3. Inspect every implicated layer: frontend request construction, backend
   routing and business logic, prompts/templates, persistence, background jobs,
   deployment manifests, and infrastructure configuration as applicable.
4. Preserve dirty worktrees. Record `git status --short --branch`, the checked
   out commit, and the relevant local branch or tag without changing them.
5. Establish current remote truth with read-only commands such as
   `git ls-remote`. Do not call a stale local tracking ref "current" unless its
   hash matches the remote. If an unseen remote commit must be inspected, use a
   disposable clone under `/tmp` rather than fetching into the user's worktree,
   then remove it when the investigation ends.
6. Trace the concrete execution path with focused search and file reads. Use
   tests, `git log`, `git show`, and `git blame` to distinguish the introducing
   change from later symptoms. Cite exact files, lines, commits, and values that
   support the conclusion.

Avoid broad keyword searches as the final explanation. Follow the user action
or event from its entry point to the code that produces the reported outcome.

## 3. Decide whether it is still an issue

Evaluate each evidence layer separately:

1. **Jira state:** record status and resolution, but never treat them as proof
   that the behavior exists or is fixed.
2. **Current source:** determine whether the responsible path is still present
   on the relevant current remote branch.
3. **Safe reproduction:** prefer a focused unit test, an unsaved in-memory
   object, deterministic prompt/config assembly, or another isolated check.
   Never create production or shared staging data for a reproduction.
4. **Deployed state:** when source and runtime could differ, identify the live
   image, tag, digest, commit, configuration, and rollout state through
   read-only AWS or Rancher checks.
5. **Observed runtime:** inspect narrowly scoped metrics, events, and logs only
   when they can distinguish competing causes. Use an explicit time window and
   redact sensitive content.

Use one of these verdicts:

- `confirmed current`: current source or a safe live observation confirms it;
- `present in current source; live not verified`;
- `fixed in source; deployment not verified`;
- `not reproduced with current evidence`;
- `inconclusive`: required evidence is unavailable or conflicting.

State exactly which environment and revision each verdict covers.

## 4. Check AWS and Rancher only when relevant

Use cloud evidence when the issue can depend on deployed versions, environment
configuration, queues, storage, databases, networking, scaling, runtime errors,
or source-versus-production drift. Skip cloud access for a fully established
source-only defect, and say why it was unnecessary.

Before using credentials, inspect which files exist in
`~/.agents/secrets/` and which variable names they define. Follow the exact AWS
profile, region, kubeconfig, namespace, and authentication instructions from
the repository and its `AGENTS.md` files.

For AWS:

- Verify identity with the explicitly configured project profile before other
  calls.
- Limit calls to relevant read operations such as `list-*`, `get-*`,
  `describe-*`, `head-*`, CloudWatch metric reads, and scoped log reads.
- Do not retrieve secret values or invoke application functions for testing.
- If the explicit identity check fails, stop and request re-authentication. Do
  not substitute another profile or account.

For Rancher/Kubernetes:

- Use `get`, `describe`, `logs`, `top`, `events`, `api-resources`, `auth can-i`,
  and read-only rollout status checks as needed.
- Inspect workload images, replica readiness, non-secret environment values,
  ConfigMap data when safe, pod events, and a narrow log window.
- Never request Secret data. Seeing that a Secret or key name exists is enough.
- Use `exec` only as a last resort when the exact remote command is demonstrably
  non-mutating. Force database sessions into read-only mode, bound every query,
  and avoid commands that can write files, caches, queues, or external APIs.
- If Rancher authentication is required and unavailable, stop and ask the user
  to refresh it rather than bypassing the proxy or switching clusters.

## 5. Identify the cause

Separate four things explicitly:

1. the user-visible symptom;
2. the current code or runtime mechanism producing it;
3. the change or configuration that introduced that mechanism, when history
   establishes it;
4. contributing conditions that make it visible but are not the root cause.

Label inferences as inferences. Prefer `high`, `medium`, or `low` confidence and
say what evidence would raise the confidence. Do not invent missing production
facts or imply that a likely cause was live-verified.

## Report the result

Lead with the outcome in this shape:

```text
KEY-N — Issue title
Verdict: <current-state verdict, environment, and revision>
Cause: <one concise evidence-backed explanation>
Confidence: <high | medium | low>
```

Then provide:

- the decisive Jira, source, history, test, deployment, AWS, and Rancher
  evidence, with file/line links, commits, resource names, and timestamps;
- related or duplicate issue keys and why they matter;
- checks that were unnecessary, unavailable, or blocked;
- the smallest remaining experiment needed when the result is inconclusive.

Do not implement a fix or alter the ticket. Mention a corrective direction only
when it helps explain the cause, and keep it separate from confirmed findings.
