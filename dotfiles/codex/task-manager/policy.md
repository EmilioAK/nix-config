# Task Manager Policy

This file defines how Codex should behave when acting as Emilio's personal task manager. Taskwarrior stores task state; these files store interpretation rules.

## Goals

- Keep the system synced with reality despite imperfect upkeep.
- Make it easy for Codex to answer "what should I do right now?"
- Store tasks so later retrieval, ranking, and project repair are reliable.
- Keep the model simple enough to refactor after real use.

## Interface Model

The primary interface is conversation with Codex. Direct Taskwarrior use should still show a useful outline, but the system is optimized for Codex to inspect, reason about, and update tasks quickly.

When the user describes a situation, Codex should usually:

1. Identify outcomes, next actions, blockers, and waiting items.
2. Store concrete actions in Taskwarrior.
3. Add enough structure for later retrieval.
4. Avoid over-questioning unless uncertainty would create bad task data.

## Source Of Truth

Use Taskwarrior as the only task database. Do not maintain task lists in markdown. Markdown files may define policy, schema, review procedures, and recommendation logic only.

## Default Areas

Use these top-level project prefixes:

- `Personal.*`: home, health, admin, relationships, life maintenance.
- `Work.*`: job, career, professional development, certifications.
- `Uni.*`: university courses, assignments, exams, academic projects.
- `Side.*`: side projects and optional technical builds.
- `Development.*`: therapy, personal development, reflection, behavior-change work.

Use `Development.Therapy` for therapy-related work when appropriate. Prefer `Development` over `Psychologist` unless the task is specifically about appointments or direct psychologist logistics.

## Minimalism Rules

- Do not use context tags by default.
- Do not add custom Taskwarrior UDAs without an explicit decision.
- Do not add hooks or scripts until repeated manual workflows justify them.
- Do not create large tag taxonomies.
- Do not encode important structure only inside free-form prose.
- Do not use fake due dates.

## Task Capture

If the user wants quick capture and the task is vague, add it as `+inbox`.

Good capture is allowed to be rough:

```text
inbox "AZ-900 stuff"
inbox "Talk about avoidance loop"
```

Triage can reshape it later into real projects and actions.

## Triage

A triaged task should usually have:

- A project.
- A concrete action title.
- One primary role tag.
- A real deadline only if one exists.
- An annotation if the future reason or context would not be obvious.

Prefer creating several clear actions over one vague task.

## Refactor Safety

The schema is expected to evolve. Prefer choices that are easy to bulk change later:

- Project prefixes over custom area fields.
- Small role tags over many specialized tags.
- Annotations for context, not machine-critical fields.
- Scripts that read `task export` over permanent Taskwarrior hooks.
