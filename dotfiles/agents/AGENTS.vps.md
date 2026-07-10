# Global Instructions

- Follow project-local instructions when present.

## Secrets and authentication

- Secrets are stored as env files under `~/.agents/secrets/`.
- `~/.pi/secrets/` is a compatibility symlink to `~/.agents/secrets/`.
- For tasks that might need credentials, API keys, tokens, cloud access, deploys, integrations, or external services, first check which files exist in `~/.agents/secrets/` and decide which env file may be relevant.
- Do not print or expose secret values. Prefer inspecting filenames/variable names, and source relevant env files only for the commands that need them.
- If any needed authentication is missing, expired, or invalid, stop and ask the user to re-authenticate instead of continuing with workarounds.

## AWS

- AWS access may be available when needed.
- Before using AWS, check authentication/identity with `aws sts get-caller-identity` or an equivalent safe check.
- If AWS is not authenticated or credentials are expired/invalid, stop and ask the user to re-authenticate.

## Headless VPS environment

- For web servers, previews, dashboards, callbacks, or anything that needs browser access, provide an SSH local port-forwarding command the user can run locally.
- The SSH command should only forward the port, e.g. `ssh -N -L <local_port>:127.0.0.1:<remote_port> <user>@<vps_host>`.
- Prefer binding dev servers to `127.0.0.1` unless public remote access is explicitly needed.
