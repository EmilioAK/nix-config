---
name: capisoft-jira-tasks
description: >-
  Manage Emilio's Capisoft Jira task system across the personal board "Emilio's
  Tasks" (board 887), project work assigned to Emilio, and private non-project
  work in EMILIO. Use when Codex needs to capture, create, inspect, organize,
  claim, transition, or verify Capisoft work or private Jira tasks; prevent
  multiple agents from picking up the same issue; decide whether work belongs
  in its real project or EMILIO; or troubleshoot this board, filter,
  authentication, or privacy setup. Do not use this skill for a terse
  "Task: KEY-N" root-cause investigation; use
  `capisoft-investigate-jira-issue` for that read-only workflow.
---

# Capisoft Jira Tasks

Keep all of Emilio's Capisoft work visible on one personal board without moving
project work out of its real project or exposing private tasks.

A terse prompt such as `Task: LP-360` means a read-only root-cause
investigation. Defer it to `capisoft-investigate-jira-issue`; do not claim or
transition the issue under this task-management workflow.

## Use the canonical setup

- Jira site: `https://capi-soft.atlassian.net`
- Personal board: `Emilio's Tasks`, board `887`
- Saved filter: `Emilio - All Work Filter`, filter `11150`
- Filter JQL:
  `(assignee = currentUser() OR project = EMILIO) ORDER BY Rank ASC`
- Private task project: `EMILIO` (`Emilio's Tasks`)

Treat the board as a view, not as the owner of the work. The saved filter is
private and owned by Emilio. The EMILIO team-managed business space is set to
Private access; Emilio is its only explicit human member and Administrator.

Verify team-managed space privacy on **Space settings -> Access**. Do not infer
it from the generic project REST field `isPrivate`: Jira returned `false` for
EMILIO even while the authoritative Access page showed **Private access**.

## Choose where a task belongs

1. Keep work tied to a product, client, repository, or existing initiative in
   that work's real Jira project. Assign it to Emilio for it to appear on board
   887.
2. Put private, personal, administrative, or otherwise projectless work in
   EMILIO. Prefer assigning it to Emilio to make ownership explicit, although
   every EMILIO item appears on board 887 even when unassigned.
3. Never duplicate a project issue into EMILIO merely to make it visible on the
   personal board.
4. Infer the destination from context. Ask only when choosing between a shared
   project and EMILIO would materially change visibility or ownership.

Examples:

- Keep an Exact Online implementation task in `LP` and assign it to Emilio.
- Keep a Check project defect in `CHEC` and assign it to Emilio.
- Put private planning, sensitive follow-ups, or projectless Capisoft admin in
  `EMILIO`.

## Create a task

1. Create a `Task` in the selected project. Use `Sub-task` only when a real
   parent issue exists.
2. Write an action-oriented summary and enough description to preserve the
   desired outcome and relevant context.
3. Set priority, due date, labels, and links only when the user supplied or
   requested them. Do not invent metadata.
4. Assign shared-project work to Emilio. Assign EMILIO work to Emilio by
   default unless the user asks to leave it unassigned.
5. Fetch the created issue and confirm its key appears on board 887.

Create or modify Jira work only when the user requested the write. Status,
review, audit, and explanation requests are read-only.

## Claim a task before working

Treat moving an issue to the exact project status `In Progress` as the visible
claim that substantive agent work has started. Except for the terse
`Task: KEY-N` read-only workflow delegated above, a request to implement,
investigate, or otherwise work on an existing Jira issue authorizes this claim.
A request only to inspect, explain, plan, triage, or report does not.

1. Fetch the issue immediately before claiming it and inspect its exact status.
2. Proceed only when that exact status is claimable for the project. Do not use
   `statusCategory` to decide: for example, LP's unstarted `TO DO Urgent` status
   is currently mapped to Jira's `In Progress` category.
3. Query the issue's available transitions and transition it to the exact
   project status `In Progress` before changing code, running a substantive
   investigation, or making other task-specific mutations.
4. Record a claim marker in a dedicated agent-claim field when one exists;
   otherwise add a concise Jira comment. Include the agent surface, a stable
   task/thread or session identifier when available, and the claim time. Keep
   the human Jira assignee unchanged unless the user asked to reassign the
   issue; assignee identifies human responsibility, not which agent currently
   owns the work.
5. Re-fetch the issue and begin work only after confirming the exact status and
   claim marker. If the issue is already claimed, in review, or done, stop and
   do not duplicate the work.

Use exact claimable statuses per workflow. Known examples are `BACKLOG` and
`TO DO Urgent` in LP and `To Do` in SAE; revalidate live transitions rather
than treating this list as permanent. Do not treat `REQUESTS`, review states,
or any similarly named custom state as claimable without explicit confirmation.

A Jira transition is coordination state, not an atomic mutex. When one
orchestrator dispatches multiple agents, serialize the claim sequence there.
Without serialized dispatch, re-read after claiming and stop if another claim
appeared concurrently; never assume that two near-simultaneous transitions
could not both succeed.

When work finishes, move the issue to the appropriate review or Done state. If
work is abandoned or handed off, leave a concise handoff with the repository
and branch or worktree state, clear the agent-claim field or add a matching
claim-released comment, and return the issue to the appropriate claimable state
when safe. Never steal a stale-looking claim; inspect its owner and activity
and ask before taking it over.

EMILIO currently has no `In Progress` status. Until its workflow is expanded,
do not use independent agent pickup there. Directly assigned agent work must be
serialized by one orchestrator and use a claim marker, or remain unstarted.

## Update and complete tasks

- Fetch the issue before editing it.
- Query available transitions before changing status; workflows differ across
  the projects aggregated by the board.
- Transition completed work to the project's Done status instead of deleting
  it.
- Keep sensitive descriptions, comments, and attachments inside EMILIO rather
  than a shared project.
- Remember that EMILIO currently has only `To Do` and `Done` statuses for Task
  and Sub-task. Do not promise an `In Progress` transition unless that workflow
  is expanded.

## Authenticate correctly

First inspect `~/.agents/secrets/` and use `jira.env`. Never print secret
values. The Jira token is scoped and must use the Atlassian cloud gateway in
`JIRA_API_BASE_URL`; direct API requests to `JIRA_BASE_URL` return `401` for
this token.

Use Basic authentication with the Jira email and token:

```sh
set -a
source "$HOME/.agents/secrets/jira.env"
set +a
auth="$JIRA_EMAIL:$JIRA_TOKEN"
api="${JIRA_API_BASE_URL%/}"
curl --fail --silent --show-error -u "$auth" "$api/rest/api/3/myself"
```

Use connected Atlassian tools for normal issue reads and writes when they cover
the operation. Use the REST API for Agile board configuration and exact
coverage checks. If authentication is rejected, stop and ask the user to
refresh the credential.

## Verify the setup

Use read-only checks whenever board coverage or configuration is in doubt:

- Fetch `/rest/agile/1.0/board/887/configuration` and confirm filter `11150`.
- Fetch `/rest/api/3/filter/11150` and confirm the canonical JQL above.
- Compare keys returned by board 887 with
  `assignee = currentUser() OR project = EMILIO`.
- Specifically confirm no unresolved issue assigned to Emilio is missing.
- After creating an EMILIO issue, confirm it appears on board 887 regardless of
  assignment.
- Confirm privacy through the EMILIO Access page and its explicit members.

Report live counts as a dated observation only; never encode them as durable
configuration facts.
