# Recommendation Logic

Use this when the user asks what to do now, what matters today, what to prioritize, or whether a project is a good opportunity.

## Inputs

Inspect Taskwarrior with `task export` for broad reasoning. If the user provides time, energy, mood, or constraints, use them. If not, make a useful recommendation with stated assumptions instead of forcing a questionnaire.

Useful optional questions:

- "How much time do you have?"
- "Is your energy low, medium, or high?"

Ask only if the answer would materially change the recommendation.

## Ranking Signals

Prefer a reasoned recommendation over raw Taskwarrior priority. Consider:

- Real deadline pressure: overdue, due today, due soon.
- Available `+next` tasks, while treating `+next` as the deliberately small focus list.
- `+asap` tasks whose scheduled attention date has arrived or whose project needs momentum.
- Stale `+next` tasks that remain relevant.
- Projects with momentum or a short path to meaningful completion.
- Important projects with no clear available action, or where the current focus list should be reconsidered.
- Inbox items that hide obligations.
- Blocked tasks where one clarification would unlock progress.
- Waiting tasks whose `wait` date has passed or which seem neglected.
- Clusters of similar tasks that can be batched.
- User-provided time and energy.

Age matters, but old low-value tasks should not automatically beat newer high-value tasks.

## Project Opportunity

When evaluating a project, look for:

- Multiple related tasks under the same project.
- Clear available actions, whether or not they are tagged `+next`.
- Low friction to restart.
- Career, university, health, or personal-development value.
- Staleness or repeated postponement.
- Whether progress would reduce future stress.

Example reasoning:

```text
Work.AzureCert looks like a good opportunity because it is unblocked, stale, career-relevant, and has a clear next action.
```

## Answer Shape

For "what should I do now?", give a small set of options:

```text
Best move: ...
Why: ...

Backup: ...
Avoid for now: ...
```

Prefer one clear recommendation plus one backup over a long menu. Mention assumptions when relevant.

## Do Not

- Do not recommend from due dates alone.
- Do not treat all old tasks as urgent.
- Do not ignore stale projects just because they lack deadlines.
- Do not make the user manually inspect a long task list unless they asked for it.
