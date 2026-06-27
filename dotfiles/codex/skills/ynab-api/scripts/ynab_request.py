#!/usr/bin/env python3
"""Small stdlib client for YNAB API requests."""

from __future__ import annotations

import argparse
import json
import os
import shlex
import sys
import urllib.error
import urllib.parse
import urllib.request


WRITE_METHODS = {"POST", "PATCH", "PUT", "DELETE"}
DEFAULT_BASE_URL = "https://api.ynab.com/v1"
DEFAULT_TOKEN_FILE = "~/.config/secrets/ynab.zsh"
TOKEN_NAMES = ("YNAB_API_TOKEN", "YNAB_ACCESS_TOKEN")


def parse_query(values: list[str]) -> dict[str, str]:
    query: dict[str, str] = {}
    for value in values:
        if "=" not in value:
            raise SystemExit(f"Invalid --query value {value!r}; expected key=value")
        key, item = value.split("=", 1)
        if not key:
            raise SystemExit("Invalid --query value with empty key")
        query[key] = item
    return query


def load_body(args: argparse.Namespace) -> bytes | None:
    if args.data and args.json_file:
        raise SystemExit("Use either --data or --json-file, not both")
    raw = None
    if args.data:
        raw = args.data
    elif args.json_file:
        with open(args.json_file, "r", encoding="utf-8") as handle:
            raw = handle.read()
    if raw is None:
        return None
    try:
        parsed = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Request body is not valid JSON: {exc}") from exc
    return json.dumps(parsed, separators=(",", ":")).encode("utf-8")


def build_url(base_url: str, path: str, query: dict[str, str]) -> str:
    if not path.startswith("/"):
        raise SystemExit("Path must start with '/', for example /plans")
    base = base_url.rstrip("/")
    url = f"{base}{path}"
    if query:
        url = f"{url}?{urllib.parse.urlencode(query)}"
    return url


def print_json(raw: bytes, stream) -> None:
    text = raw.decode("utf-8", errors="replace")
    try:
        parsed = json.loads(text)
    except json.JSONDecodeError:
        print(text, file=stream)
        return
    print(json.dumps(parsed, indent=2, sort_keys=True), file=stream)


def load_token_from_file(token_file: str) -> str | None:
    path = os.path.expanduser(token_file)
    if not path or not os.path.exists(path):
        return None

    try:
        with open(path, "r", encoding="utf-8") as handle:
            lines = handle.readlines()
    except OSError as exc:
        raise SystemExit(f"Could not read token file {token_file}: {exc}") from exc

    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        try:
            parts = shlex.split(stripped, comments=True, posix=True)
        except ValueError:
            continue
        if parts and parts[0] == "export":
            parts = parts[1:]
        for part in parts:
            if "=" not in part:
                continue
            key, value = part.split("=", 1)
            if key in TOKEN_NAMES and value:
                return value
    return None


def load_token(args: argparse.Namespace) -> str | None:
    token = os.environ.get("YNAB_API_TOKEN") or os.environ.get("YNAB_ACCESS_TOKEN")
    if token:
        return token
    if args.no_token_file:
        return None
    return load_token_from_file(args.token_file)


def main() -> int:
    parser = argparse.ArgumentParser(description="Make an authenticated YNAB API request.")
    parser.add_argument("method", choices=["GET", "POST", "PATCH", "PUT", "DELETE"])
    parser.add_argument("path", help="API path such as /plans or /plans/last-used/accounts")
    parser.add_argument("--query", action="append", default=[], help="Query parameter as key=value; repeatable")
    parser.add_argument("--data", help="JSON request body as a string")
    parser.add_argument("--json-file", help="Path to a JSON request body file")
    parser.add_argument("--allow-write", action="store_true", help="Required for POST, PATCH, PUT, DELETE")
    parser.add_argument("--base-url", default=os.environ.get("YNAB_BASE_URL", DEFAULT_BASE_URL))
    parser.add_argument(
        "--token-file",
        default=os.environ.get("YNAB_TOKEN_FILE", DEFAULT_TOKEN_FILE),
        help="Shell-style file containing YNAB_API_TOKEN; default: ~/.config/secrets/ynab.zsh",
    )
    parser.add_argument("--no-token-file", action="store_true", help="Only read token from environment")
    args = parser.parse_args()

    token = load_token(args)
    if not token:
        raise SystemExit(
            "Set YNAB_API_TOKEN in the environment or in ~/.config/secrets/ynab.zsh before calling the API"
        )

    method = args.method.upper()
    if method in WRITE_METHODS and not args.allow_write:
        raise SystemExit("Refusing non-GET request without --allow-write")

    body = load_body(args)
    query = parse_query(args.query)
    url = build_url(args.base_url, args.path, query)
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
        "User-Agent": "codex-ynab-api-skill",
    }
    if body is not None:
        headers["Content-Type"] = "application/json"

    request = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            print_json(response.read(), sys.stdout)
            return 0
    except urllib.error.HTTPError as exc:
        print(f"YNAB API returned HTTP {exc.code}", file=sys.stderr)
        print_json(exc.read(), sys.stderr)
        return 1
    except urllib.error.URLError as exc:
        print(f"YNAB API request failed: {exc.reason}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
