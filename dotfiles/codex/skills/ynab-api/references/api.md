# YNAB API Reference

Last verified: 2026-06-22 against the official docs at `https://api.ynab.com/` and OpenAPI spec `https://api.ynab.com/papi/open_api_spec.yaml` version `1.85.0`.

## Authentication

- Use personal access tokens for the user's own YNAB account. The token is created in the YNAB web app under Account Settings -> Developer Settings -> Personal Access Tokens.
- Use OAuth only when building an app for other YNAB users. Prefer OAuth `scope=read-only` when writes are not required.
- Send the token as HTTP Bearer auth: `Authorization: Bearer <token>`.
- Read token values only from environment variables, preferably `YNAB_API_TOKEN`. `YNAB_ACCESS_TOKEN` is accepted by the bundled helper as a fallback.
- If the token is not already in the environment, use the user's local private token file at `~/.config/secrets/ynab.zsh`. The bundled helper parses simple `export YNAB_API_TOKEN=...` or `YNAB_API_TOKEN=...` assignments from that file without executing it.
- Never ask the user to paste a token into chat. Never write tokens into repo files, shell history examples, logs, or final answers.

## Base URL and Terminology

- Current base URL: `https://api.ynab.com/v1`.
- The older `https://api.youneedabudget.com/v1` domain still works for existing applications, but new work should use `api.ynab.com`.
- Current docs use `plan` terminology and `/plans/{plan_id}` paths. Older `/budgets/{budget_id}` paths are compatibility aliases and are no longer documented.
- User wording like "budget", "YNAB budget", or "my budget" usually means a YNAB plan.
- `plan_id` may be an actual UUID, `last-used`, or `default` when OAuth default plan selection is enabled.

## Response and Error Shape

- Successful responses are wrapped in a top-level `data` object.
- Error responses use a top-level `error` object with `id`, `name`, and `detail`.
- HTTP errors to handle: `400 bad_request`, `401 not_authorized`, `403` variants, `404.1 not_found`, `404.2 resource_not_found`, `409 conflict`, `429 too_many_requests`, `500 internal_server_error`, and `503 service_unavailable`.
- Empty response fields may be explicit `null`; do not assume omitted fields.

## Data Formats

- Dates use ISO `YYYY-MM-DD` format and UTC.
- Currency values may appear in legacy integer milliunits. `1000` milliunits equals one currency unit.
- Since v1.82.0, many responses include `..._formatted` and `..._currency` fields for account, category, transaction, scheduled transaction, month, and money movement data. Prefer those for reporting when present.
- For write payloads, use the schema's required fields and milliunit amounts unless the endpoint explicitly supports another format.

## Rate Limits and Efficiency

- Access tokens are limited to 200 requests per rolling hour.
- Prefer the most specific endpoint that answers the question.
- Cache or reuse responses inside the current task instead of re-fetching the same large resources.
- For repeated sync-style reads, use delta requests. Endpoints that support `last_knowledge_of_server` return a `server_knowledge` value in `data`.

Delta-enabled reads:

- `GET /plans/{plan_id}`
- `GET /plans/{plan_id}/accounts`
- `GET /plans/{plan_id}/categories`
- `GET /plans/{plan_id}/money_movements`
- `GET /plans/{plan_id}/money_movement_groups`
- `GET /plans/{plan_id}/months`
- `GET /plans/{plan_id}/payees`
- `GET /plans/{plan_id}/scheduled_transactions`
- `GET /plans/{plan_id}/transactions`

## Common Endpoint Map

Use the OpenAPI spec for exact schemas. Current v1.85.0 endpoint summaries:

```text
GET    /user                                                   Get user
GET    /plans                                                  Get all plans
GET    /plans/{plan_id}                                        Get a plan
GET    /plans/{plan_id}/settings                               Get plan settings
GET    /plans/{plan_id}/accounts                               Get all accounts
POST   /plans/{plan_id}/accounts                               Create an account
GET    /plans/{plan_id}/accounts/{account_id}                  Get an account
GET    /plans/{plan_id}/categories                             Get all categories
POST   /plans/{plan_id}/categories                             Create a category
GET    /plans/{plan_id}/categories/{category_id}               Get a category
PATCH  /plans/{plan_id}/categories/{category_id}               Update a category
GET    /plans/{plan_id}/months/{month}/categories/{category_id} Get a category for a specific plan month
PATCH  /plans/{plan_id}/months/{month}/categories/{category_id} Update a category for a specific month
POST   /plans/{plan_id}/category_groups                        Create a category group
PATCH  /plans/{plan_id}/category_groups/{category_group_id}    Update a category group
GET    /plans/{plan_id}/payees                                 Get all payees
POST   /plans/{plan_id}/payees                                 Create a payee
GET    /plans/{plan_id}/payees/{payee_id}                      Get a payee
PATCH  /plans/{plan_id}/payees/{payee_id}                      Update a payee
GET    /plans/{plan_id}/payee_locations                        Get all payee locations
GET    /plans/{plan_id}/payee_locations/{payee_location_id}    Get a payee location
GET    /plans/{plan_id}/payees/{payee_id}/payee_locations      Get all locations for a payee
GET    /plans/{plan_id}/months                                 Get all plan months
GET    /plans/{plan_id}/months/{month}                         Get a plan month
GET    /plans/{plan_id}/money_movements                        Get all money movements
GET    /plans/{plan_id}/months/{month}/money_movements         Get money movements for a plan month
GET    /plans/{plan_id}/money_movement_groups                  Get all money movement groups
GET    /plans/{plan_id}/months/{month}/money_movement_groups   Get money movement groups for a plan month
GET    /plans/{plan_id}/transactions                           Get transactions
POST   /plans/{plan_id}/transactions                           Create a single transaction or multiple transactions
PATCH  /plans/{plan_id}/transactions                           Update multiple transactions
POST   /plans/{plan_id}/transactions/import                    Import transactions
GET    /plans/{plan_id}/transactions/{transaction_id}          Get a transaction
PUT    /plans/{plan_id}/transactions/{transaction_id}          Update a transaction
DELETE /plans/{plan_id}/transactions/{transaction_id}          Delete a transaction
GET    /plans/{plan_id}/accounts/{account_id}/transactions     Get account transactions
GET    /plans/{plan_id}/categories/{category_id}/transactions  Get category transactions
GET    /plans/{plan_id}/payees/{payee_id}/transactions         Get payee transactions
GET    /plans/{plan_id}/months/{month}/transactions            Get plan month transactions
GET    /plans/{plan_id}/scheduled_transactions                 Get all scheduled transactions
POST   /plans/{plan_id}/scheduled_transactions                 Create a scheduled transaction
GET    /plans/{plan_id}/scheduled_transactions/{scheduled_transaction_id} Get a scheduled transaction
PUT    /plans/{plan_id}/scheduled_transactions/{scheduled_transaction_id} Update a scheduled transaction
DELETE /plans/{plan_id}/scheduled_transactions/{scheduled_transaction_id} Delete a scheduled transaction
```

## Write Safety

- Confirm before any non-GET request, even if the user previously asked for an update.
- Show the method, endpoint, and concise payload or effect. Redact sensitive memo/details if they are not relevant.
- Use idempotency where available. For imported transactions, provide stable `import_id` values to prevent duplicates.
- After a write, prefer a narrow verification read rather than a full plan export.
