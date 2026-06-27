---
name: ynab-api
description: Use the YNAB API for personal budget data tasks involving You Need A Budget plans, accounts, categories, payees, months, transactions, scheduled transactions, money movements, imports, or OAuth/PAT setup. Trigger when the user asks Codex to read, analyze, reconcile, report on, or safely update YNAB data through the API.
---

# YNAB API

## Core Workflow

Use this skill for YNAB API work. Treat all YNAB responses as private financial data.

1. Read `references/api.md` before making YNAB API calls or advising on setup.
2. Prefer read-only API calls and concise summaries. Do not print full raw financial exports unless the user asks.
3. Use `scripts/ynab_request.py` for direct API calls when possible; it handles auth headers, JSON payloads, and error output.
4. Use `YNAB_API_TOKEN` from the environment or the user's local private token file at `~/.config/secrets/ynab.zsh`. The bundled helper loads that file automatically. Do not ask the user to paste an access token into chat or commit a token to disk.
5. Resolve the plan first with `GET /plans` unless the user provides a plan id, `YNAB_PLAN_ID` is set, or `last-used`/`default` is appropriate.
6. Before any `POST`, `PATCH`, `PUT`, or `DELETE`, show the intended endpoint and concise JSON payload/effect, then get explicit user confirmation.

## Quick Commands

List available plans:

```bash
python3 /Users/emilio/.config/nix-darwin/dotfiles/codex/skills/ynab-api/scripts/ynab_request.py GET /plans
```

Get accounts for the last-used plan:

```bash
python3 /Users/emilio/.config/nix-darwin/dotfiles/codex/skills/ynab-api/scripts/ynab_request.py GET /plans/last-used/accounts
```

Get transactions with query parameters:

```bash
python3 /Users/emilio/.config/nix-darwin/dotfiles/codex/skills/ynab-api/scripts/ynab_request.py GET /plans/last-used/transactions --query since_date=2026-06-01
```

Run a confirmed write:

```bash
python3 /Users/emilio/.config/nix-darwin/dotfiles/codex/skills/ynab-api/scripts/ynab_request.py PATCH /plans/last-used/transactions --json-file payload.json --allow-write
```

## Practical Rules

- Use current `/plans/{plan_id}` paths. Users may say "budget"; map that to YNAB's current "plan" API terminology.
- Treat `~/.config/secrets/ynab.zsh` as the expected local secret source. It may contain `export YNAB_API_TOKEN=...`; never print or summarize its contents.
- Prefer specific endpoints over full exports, especially for balances, category details, and transaction searches.
- Use delta requests with `last_knowledge_of_server` for repeated sync-style reads.
- Use the official docs at `https://api.ynab.com/` and the OpenAPI spec at `https://api.ynab.com/papi/open_api_spec.yaml` when endpoint schemas are needed.
