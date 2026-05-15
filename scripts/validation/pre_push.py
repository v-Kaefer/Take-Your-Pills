#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

try:
    import tomllib
except ImportError:  # pragma: no cover - Python < 3.11 fallback
    tomllib = None

try:
    import yaml
except ImportError:  # pragma: no cover - optional dependency
    yaml = None

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from governance_bootstrap.release import parse_name_status_lines, render_change_summary_report, summarize_change_items


ZERO_SHA = "0000000000000000000000000000000000000000"


@dataclass(frozen=True)
class RefUpdate:
    local_ref: str
    local_sha: str
    remote_ref: str
    remote_sha: str


def indent(text: str, prefix: str = "  ") -> str:
    return "\n".join(f"{prefix}{line}" if line else "" for line in text.splitlines())


def read_ref_updates(stdin: str) -> list[RefUpdate]:
    updates: list[RefUpdate] = []
    for raw_line in stdin.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        parts = line.split()
        if len(parts) != 4:
            continue
        updates.append(RefUpdate(*parts))
    return updates


def git_diff_name_status(base_sha: str, head_sha: str) -> list[str]:
    result = subprocess.run(
        ["git", "diff", "--name-status", base_sha, head_sha],
        check=True,
        capture_output=True,
        text=True,
    )
    return [line for line in result.stdout.splitlines() if line.strip()]


def collect_changes(updates: list[RefUpdate]) -> list[tuple[RefUpdate, list[str]]]:
    empty_tree = subprocess.run(
        ["git", "hash-object", "-t", "tree", "/dev/null"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()
    per_ref: list[tuple[RefUpdate, list[str]]] = []
    for update in updates:
        if update.local_sha == ZERO_SHA:
            per_ref.append((update, []))
            continue
        base_sha = update.remote_sha if update.remote_sha != ZERO_SHA else empty_tree
        diff_lines = git_diff_name_status(base_sha, update.local_sha)
        per_ref.append((update, diff_lines))
    return per_ref


def lint_python_file(path: str) -> list[str]:
    import py_compile

    try:
        py_compile.compile(path, doraise=True)
    except py_compile.PyCompileError as exc:
        return [f"{path}: {exc.msg}"]
    return []


def lint_shell_file(path: str) -> list[str]:
    result = subprocess.run(["bash", "-n", path], capture_output=True, text=True)
    if result.returncode == 0:
        return []
    message = result.stderr.strip() or result.stdout.strip() or "shell syntax check failed"
    return [f"{path}: {message}"]


def lint_json_file(path: str) -> list[str]:
    try:
        with open(path, "r", encoding="utf-8") as f:
            json.load(f)
    except Exception as exc:  # noqa: BLE001
        return [f"{path}: {exc}"]
    return []


def lint_yaml_file(path: str) -> list[str]:
    if yaml is None:
        return [f"{path}: PyYAML is not available in this environment"]
    try:
        with open(path, "r", encoding="utf-8") as f:
            yaml.safe_load(f)
    except Exception as exc:  # noqa: BLE001
        return [f"{path}: {exc}"]
    return []


def lint_toml_file(path: str) -> list[str]:
    if tomllib is None:
        return [f"{path}: TOML validation is unavailable in this Python version"]
    try:
        with open(path, "rb") as f:
            tomllib.load(f)
    except Exception as exc:  # noqa: BLE001
        return [f"{path}: {exc}"]
    return []


def lint_paths(paths: list[str]) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    checked: list[str] = []
    for path in sorted({path for path in paths if Path(path).exists()}):
        checked.append(path)
        if path.endswith(".py"):
            errors.extend(lint_python_file(path))
        elif path.endswith(".sh"):
            errors.extend(lint_shell_file(path))
        elif path.endswith((".yml", ".yaml")):
            errors.extend(lint_yaml_file(path))
        elif path.endswith(".json"):
            errors.extend(lint_json_file(path))
        elif path.endswith(".toml"):
            errors.extend(lint_toml_file(path))
    return checked, errors


def format_lint_summary(checked: list[str], errors: list[str]) -> str:
    if errors:
        lines = ["Lint checks failed."]
        for error in errors:
            lines.append(f"- {error}")
        return "\n".join(lines)

    if not checked:
        return "Lint checks: no lintable files detected."

    return f"Lint checks passed for {len(checked)} changed file(s)."


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Pre-push audit and targeted lint checks")
    parser.add_argument("--remote-name", default="")
    parser.add_argument("--remote-url", default="")
    args = parser.parse_args(argv)

    ref_updates = read_ref_updates(sys.stdin.read())
    print(f"pre-push audit for {args.remote_name or 'remote'}")
    print(f"remote: {args.remote_url or 'unknown'}")

    if not ref_updates:
        print("No refs were queued for push.")
        return 0

    per_ref = collect_changes(ref_updates)
    all_paths: list[str] = []

    for update, diff_lines in per_ref:
        print(f"ref: {update.local_ref} -> {update.remote_ref}")
        if update.local_sha == ZERO_SHA:
            print("  deletion detected; no file summary available.")
            continue
        if not diff_lines:
            print("  no file changes detected.")
            continue
        items = parse_name_status_lines("\n".join(diff_lines))
        summary = summarize_change_items(items)
        print(indent(render_change_summary_report(summary, title=f"{update.local_ref} -> {update.remote_ref}")))
        print()
        all_paths.extend(item.path for item in items)

    checked, lint_errors = lint_paths(all_paths)
    print("lint checks")
    print(indent(format_lint_summary(checked, lint_errors)))

    if lint_errors:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
