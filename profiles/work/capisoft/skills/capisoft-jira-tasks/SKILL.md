---
name: capisoft-jira-tasks
description: Manage Emilio's Capisoft Jira task system across the personal board "Emilio's Tasks" (board 887), project work assigned to Emilio, and private non-project work in EMILIO. Use when Codex needs to capture, create, inspect, organize, transition, or verify Capisoft work or private Jira tasks; decide whether work belongs in its real project or EMILIO; or troubleshoot this board, filter, authentication, or privacy setup.
---

# Capisoft Jira Tasks

Keep all of Emilio's Capisoft work visible on one personal board without moving
project work out of its real project or exposing private tasks.

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
