# Task Schema

Use native Taskwarrior data wherever possible.

## Projects And Areas

Areas are top-level project prefixes:

```text
Personal.*
Work.*
Uni.*
Side.*
Development.*
```

Big outcomes are projects. Concrete actions are tasks.

Example:

```text
project:Work.AzureCert
"Review current AZ-900 exam outline" +next
"Complete Microsoft Learn identity module" +asap
"Do one AZ-900 practice test" +asap +deep
"Book AZ-900 exam" +blocked
```

Avoid project names with spaces. Prefer compact names like `Work.AzureCert`, `Uni.Stats`, `Personal.Admin`, `Development.Therapy`.

## Role Tags

Each active non-inbox task should usually have one primary role tag:

- `+inbox`: captured but not shaped.
- `+next`: deliberately selected as a candidate for the next work block. It is not a synonym for concrete, available, overdue, or important.
- `+asap`: should stay visible or resurface soon, but is not selected for the current focus list.
- `+waiting`: blocked on another person, event, or external response.
- `+blocked`: blocked by unclear scope, missing decision, or internal structure.
- `+someday`: real but intentionally inactive.

Role tags are the main anti-drift mechanism. They let Codex distinguish actionable work from parked, blocked, or messy work.

Keep `+next` small enough to answer "what should I do now?". Routine triage should not add `+next` automatically. Use `+asap` plus `scheduled` for soft resurfacing when a task matters soon but should not compete as an immediate next action.

## Optional Shape Tags

Use only when the tag helps recommendation:

- `+quick`: small task, usually under about 15 minutes.
- `+deep`: requires focused cognitive effort.
- `+admin`: logistical or low-cognitive-overhead work.
- `+conversation`: requires talking, messaging, or emailing another person.

Do not add location/context tags by default.

## Dates

- `due`: real external deadline only.
- `wait`: hide until a task can matter again or a waiting item should be checked.
- `scheduled`: optional explicit attention date; do not require it on every task.

Tasks without deadlines should resurface through age, role, project health, and review logic. Do not create fake deadlines for urgency.

For waiting items, use `+waiting` for the semantic state and add `wait` only when there is a useful check-back date.

## Annotations

Use annotations for context that future Codex may need:

- Why the task exists.
- What decision or conversation produced it.
- What is blocking it.
- What "done" means if the title alone is not enough.

Keep annotations short and factual.

## Dependencies

Use dependencies sparingly. Prefer project grouping plus role tags unless one task truly cannot start before another finishes.

## Good Task Titles

Prefer visible concrete actions:

```text
Email professor with specific question about stats assignment part 2
Draft 5 bullet points for thesis topic options
Review current AZ-900 exam outline
Ask therapist whether avoidance loop belongs in next session
```

Avoid vague task titles after triage:

```text
Think about thesis
AZ-900 stuff
Stats
Fix life admin
```
