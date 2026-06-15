# Review Workflows

Use reviews to repair drift. The system assumes task data will become messy and should make recovery cheap.

## Daily Attention Check

Purpose: decide what deserves attention soon.

Look for:

- Overdue and due-today tasks.
- Pending `+next` tasks.
- Pending `+soon` tasks that have reached their scheduled attention date or are becoming stale.
- `+inbox` tasks that may hide obligations.
- `+waiting` tasks whose wait date has passed.
- Stale but relevant tasks.
- Projects with obvious momentum.

Output should be short: one recommendation, one backup, and any urgent cleanup.

## Inbox Triage

Purpose: turn rough capture into usable task state.

For each `+inbox` task, decide whether it should become:

- A concrete `+next` action.
- A `+soon` action with an optional scheduled attention date.
- A `+waiting` item.
- A `+blocked` item needing clarification.
- A `+someday` item.
- Multiple tasks under one project.
- Deleted/cancelled, if it is not real anymore.

Ask for confirmation before deleting or cancelling unless the user explicitly requested it.

## Weekly Reality Sync

Purpose: reduce desync from reality.

Look for:

- Projects with no `+next` task.
- Stale `+next` tasks.
- `+soon` tasks that should either become `+next`, be rescheduled, or move to `+someday`.
- Old `+inbox` tasks.
- `+blocked` tasks that need a decision or decomposition.
- `+waiting` tasks that should be followed up.
- Tasks that appear obsolete.
- Areas that are overloaded or invisible.

Summarize findings as proposed repairs, not as a giant raw list.

## Project Repair

Use when one project is messy, stale, or too vague.

Process:

1. Inspect all tasks under the project.
2. Identify the desired outcome.
3. Find the next concrete action.
4. Mark obsolete tasks for confirmation.
5. Convert vague tasks into actions, blockers, waiting items, or someday items.
6. Add annotations where future context is needed.

## Hygiene Checks

Useful recurring checks:

- Pending tasks with no project.
- Pending tasks with no role tag.
- Projects with pending tasks but no `+next`.
- Tasks with due dates that may be fake.
- Long-lived `+blocked` or `+waiting` tasks.

These checks can later become scripts if they prove useful.

## Tasksh Review

Use `tasksh` for interactive review sessions. Tasksh uses the `reviewed` UDA and `_reviewed` report in `.taskrc` to avoid reviewing the same task more than weekly.

Inside tasksh, run:

```text
review
```

or review a fixed number of tasks:

```text
review 12
```
