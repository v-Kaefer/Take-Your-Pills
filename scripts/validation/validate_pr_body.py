#!/usr/bin/env python3
import argparse
import os
import re
import sys


REQUIRED_SECTIONS = [
    "linked issue",
    "phase",
    "summary",
    "how to test",
    "evidence",
    "known risks",
    "dod checklist",
]


def read_body(args):
    if args.file:
        with open(args.file, "r", encoding="utf-8") as f:
            return f.read()
    if os.environ.get("PR_BODY"):
        return os.environ["PR_BODY"]
    if not sys.stdin.isatty():
        return sys.stdin.read()
    return ""


def normalize_header(header):
    return " ".join(header.strip().lower().split())


def sections_from_body(body):
    sections = {}
    current = None
    for line in body.splitlines():
        match = re.match(r"^##\s+(.+?)\s*$", line)
        if match:
            current = normalize_header(match.group(1))
            sections.setdefault(current, [])
            continue
        if current:
            sections[current].append(line)
    return sections


def meaningful_lines(lines):
    values = []
    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue
        if stripped in {"-", "*", "_", "TODO", "TBD"}:
            continue
        values.append(stripped)
    return values


def fail(message):
    print(message, file=sys.stderr)
    return 1


def validate(body):
    if not body.strip():
        return fail("PR body is required")

    sections = sections_from_body(body)
    for section in REQUIRED_SECTIONS:
        if section not in sections:
            return fail(f"Missing section: {section.title()}")
        if not meaningful_lines(sections[section]):
            return fail(f"Section must not be empty or placeholder-only: {section.title()}")

    linked_issue = "\n".join(sections["linked issue"])
    if not re.search(r"\b(closes|fixes|resolves)\s+#\d+\b", linked_issue, re.IGNORECASE):
        return fail("Linked Issue section must contain: Closes/Fixes/Resolves #123")

    phase = "\n".join(sections["phase"])
    if not re.search(r"\bphase:\s*\d+\b", phase, re.IGNORECASE):
        return fail("Phase section must contain a phase label such as phase:0")

    how_to_test = "\n".join(sections["how to test"])
    if not re.search(r"test type:\s*(automated|smoke|manual)\b", how_to_test, re.IGNORECASE):
        return fail("How to test section must contain: Test type: automated | smoke | manual")

    steps_match = re.search(r"steps:\s*(.*)", how_to_test, re.IGNORECASE)
    if steps_match and not steps_match.group(1).strip():
        lines_after_steps = False
        seen_steps = False
        for line in sections["how to test"]:
            if re.search(r"steps:\s*$", line, re.IGNORECASE):
                seen_steps = True
                continue
            if seen_steps and meaningful_lines([line]):
                lines_after_steps = True
                break
        if not lines_after_steps:
            return fail("How to test section must describe test steps")

    return 0


def main():
    parser = argparse.ArgumentParser(description="Validate repository PR body metadata")
    parser.add_argument("--file", help="Read PR body from a file")
    args = parser.parse_args()
    return validate(read_body(args))


if __name__ == "__main__":
    raise SystemExit(main())
