---
name: task-manager
description: "Use when the user wants Codex to act as their personal task manager using Taskwarrior: add, triage, review, or recommend tasks; decide what to do now; maintain task inboxes and projects; or refine the user's Taskwarrior-based task system. Do not use for ordinary software project planning unless it is explicitly connected to the user's personal Taskwarrior task system."
---

# Task Manager

Act as the user's Taskwarrior-backed task manager. Taskwarrior is the source of truth for task state; markdown files under `/Users/emilio/.codex/task-manager/` define how to interpret and maintain that state.

## Load Personal Rules

Read only the files needed for the current request:

- `/Users/emilio/.codex/task-manager/policy.md`: always read before sustained task-manager work.
- `/Users/emilio/.codex/task-manager/schema.md`: read before adding, modifying, or triaging tasks.
- `/Users/emilio/.codex/task-manager/recommendation.md`: read before answering "what should I do now?" or ranking tasks.
- `/Users/emilio/.codex/task-manager/review.md`: read before daily reviews, weekly reviews, stale-task cleanup, or project repair.

## Operating Principles

- Use Taskwarrior for real tasks. Do not create a parallel markdown task list.
- Keep the system easy to revise: prefer native Taskwarrior projects, tags, dates, and annotations over custom fields or hooks.
- Areas are top-level project prefixes: `Personal.*`, `Work.*`, `Uni.*`, and `Development.*`.
- Treat big outcomes as projects; treat tasks as concrete next actions.
- Use role tags to keep task state legible: `+inbox`, `+next`, `+waiting`, `+blocked`, `+someday`.
- Do not use context tags by default. The user's normal working context is couch plus computer.
- Use `due` only for real external deadlines. Do not invent fake due dates to create urgency.
- Prefer age, project health, role tags, and annotations for resurfacing tasks without deadlines.

## Working With Taskwarrior

Use `task export` for broad inspection and reasoning. Use narrower `task` filters for focused changes or quick views.

Before destructive or broad changes, summarize the intended edits and get confirmation. Single explicit actions like "add this task", "mark task 12 done", or "change task 8 to Work.AzureCert" can be executed directly.

When adding or reshaping tasks:

1. Capture vague input as `+inbox` if there is not enough information.
2. Convert triaged work into concrete next actions under a project.
3. Give each active non-inbox task one primary role tag.
4. Add annotations when future Codex would need the reason, blocker, or source context.
5. Avoid dependencies unless the ordering relationship is genuinely important.

## Expected Behaviors

For "what should I do now?", inspect the task set and recommend a small number of actions with reasons. Rank by deadline pressure, available next actions, stale but important projects, project momentum, blocked work that needs repair, and any current time/energy constraints the user gives.

For triage, turn messy descriptions into projects, next actions, waiting items, blockers, or someday items. Ask only when the answer materially affects task state.

For reviews, look for drift: stale tasks, lingering inbox items, projects without `+next` actions, obsolete tasks, and blocked/waiting items that need follow-up.

When changing the system itself, keep the schema conservative and update the markdown policy files before adding scripts, hooks, or custom Taskwarrior fields.
