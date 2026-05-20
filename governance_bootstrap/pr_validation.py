from __future__ import annotations

from dataclasses import dataclass
import re

from .comments import find_marked_comment, upsert_marked_comment
from .github import GitHubClient


VALIDATION_MARKER = "<!-- governance-pr-validation -->"
BRANCH_PATTERN = re.compile(r"^(feat|fix|docs|refactor|test|hotfix|phase|task)\/[a-z0-9._/-]+$")

REQUIRED_SECTIONS = [
    ("linked issue", "Linked Issue"),
    ("milestone", "Milestone"),
    ("summary", "Summary"),
    ("how to test", "How to test"),
    ("evidence", "Evidence"),
    ("known risks", "Known risks"),
    ("dod checklist", "DoD checklist"),
]

PLACEHOLDER_PATTERNS = [
    re.compile(r"^\s*[-*_]\s*$"),
    re.compile(r"\b(todo|tbd|placeholder|example|describe|replace me|fill in)\b", re.IGNORECASE),
    re.compile(r"<[^>]+>"),
]


@dataclass(frozen=True)
class ValidationFinding:
    section: str
    problem: str
    fix: str


def normalize_header(header: str) -> str:
    return " ".join(header.strip().lower().split())


def sections_from_body(body: str) -> dict[str, list[str]]:
    sections: dict[str, list[str]] = {}
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


def line_is_placeholder(line: str) -> bool:
    stripped = line.strip()
    if not stripped:
        return True
    return any(pattern.search(stripped) for pattern in PLACEHOLDER_PATTERNS)


def meaningful_lines(lines: list[str]) -> list[str]:
    values = []
    for line in lines:
        if line_is_placeholder(line):
            continue
        values.append(line.strip())
    return values


def validate_branch_name(branch: str | None) -> list[ValidationFinding]:
    if not branch or not branch.strip():
        return [
            ValidationFinding(
                section="Branch name",
                problem="Branch name is missing.",
                fix="Use an approved prefix such as `feat/...`, `fix/...`, `docs/...`, `refactor/...`, `test/...`, `hotfix/...`, `phase/...`, or `task/...`.",
            )
        ]

    branch = branch.strip()
    if BRANCH_PATTERN.fullmatch(branch):
        return []

    return [
        ValidationFinding(
            section="Branch name",
            problem=f"Invalid branch name `{branch}`.",
            fix="Rename it to the repository pattern, for example `feat/repo-governance-bootstrap` or `task/phase-1/player-base`.",
        )
    ]


def has_concrete_steps(lines: list[str]) -> bool:
    saw_steps = False
    for line in lines:
        match = re.match(r"^\s*steps:\s*(.*?)\s*$", line, re.IGNORECASE)
        if match:
            saw_steps = True
            remainder = match.group(1).strip()
            if remainder and not line_is_placeholder(remainder):
                return True
            continue
        if saw_steps and not line_is_placeholder(line):
            return True
    return False


def validate_pr_body(body: str | None) -> list[ValidationFinding]:
    body = body or ""
    if not body.strip():
        return [
            ValidationFinding(
                section="PR body",
                problem="The PR body is blank.",
                fix="Start from `.github/pull_request_template.md` and fill all required sections: Linked Issue, Milestone, Summary, How to test, Evidence, Known risks, and DoD checklist.",
            )
        ]

    sections = sections_from_body(body)
    findings: list[ValidationFinding] = []

    for key, label in REQUIRED_SECTIONS:
        lines = sections.get(key)
        if lines is None:
            findings.append(
                ValidationFinding(
                    section=label,
                    problem="Section is missing.",
                    fix=f"Add a `## {label}` section and fill it with concrete content.",
                )
            )
            continue
        if not meaningful_lines(lines):
            findings.append(
                ValidationFinding(
                    section=label,
                    problem="Section is empty or still a placeholder.",
                    fix=f"Replace the placeholder text in `## {label}` with the real information for this PR.",
                )
            )

    linked_issue = "\n".join(sections.get("linked issue", []))
    if linked_issue and not re.search(r"\b(closes|fixes|resolves)\s+#\d+\b", linked_issue, re.IGNORECASE):
        findings.append(
            ValidationFinding(
                section="Linked Issue",
                problem="The section does not contain a linked issue reference.",
                fix="Write `Closes #123`, `Fixes #123`, or `Resolves #123` inside `## Linked Issue`.",
            )
        )

    milestone = "\n".join(sections.get("milestone", []))
    if milestone and not re.search(r"\bMS[0-6]\b", milestone, re.IGNORECASE):
        findings.append(
            ValidationFinding(
                section="Milestone",
                problem="The milestone is missing or invalid.",
                fix="Use a milestone like `MS0`, `MS1`, or the milestone assigned to this delivery.",
            )
        )

    how_to_test_lines = sections.get("how to test", [])
    how_to_test = "\n".join(how_to_test_lines)
    if how_to_test_lines:
        if not re.search(r"test type:\s*(automated|smoke|manual)\b", how_to_test, re.IGNORECASE):
            findings.append(
                ValidationFinding(
                    section="How to test",
                    problem="The test type is missing or invalid.",
                    fix="Add `Test type: automated`, `Test type: smoke`, or `Test type: manual`.",
                )
            )
        if not has_concrete_steps(how_to_test_lines):
            findings.append(
                ValidationFinding(
                    section="How to test",
                    problem="The test steps are missing or still placeholder text.",
                    fix="Describe the exact commands, manual flow, or verification steps under `Steps:`.",
                )
            )

    return findings


def validate_pull_request(branch: str | None, body: str | None) -> list[ValidationFinding]:
    return validate_branch_name(branch) + validate_pr_body(body)


def render_failure_comment(findings: list[ValidationFinding]) -> str:
    lines = [
        VALIDATION_MARKER,
        "## PR validation failed",
        "",
        "The PR still misses repository requirements. Fix the items below and push a new commit.",
        "",
    ]

    for finding in findings:
        lines.append(f"### {finding.section}")
        lines.append(f"- Problem: {finding.problem}")
        lines.append(f"- Fix: {finding.fix}")
        lines.append("")

    lines.extend(
        [
            "## Required PR structure",
            "",
            "```md",
            "## Linked Issue",
            "- Closes #123",
            "",
            "## Milestone",
            "- MS0",
            "",
            "## Summary",
            "- What changed and why.",
            "",
            "## How to test",
            "- Test type: automated | smoke | manual",
            "- Steps: describe the commands or manual flow you ran.",
            "",
            "## Evidence",
            "- Attach screenshots, logs, or manual checklist results when applicable.",
            "",
            "## Known risks",
            "- List any known limitations or write `None` if there are none.",
            "",
            "## DoD checklist",
            "- [ ] Scope implemented as defined",
            "- [ ] Tests executed and documented",
            "- [ ] Evidence attached",
            "- [ ] No known critical breakage introduced",
            "```",
        ]
    )
    return "\n".join(lines)


def find_validation_comment(client: GitHubClient, repo: str, pr_number: int) -> dict | None:
    return find_marked_comment(client, repo, pr_number, VALIDATION_MARKER)


def upsert_validation_comment(client: GitHubClient, repo: str, pr_number: int, findings: list[ValidationFinding]) -> str | None:
    body = render_failure_comment(findings) if findings else ""
    return upsert_marked_comment(client, repo, pr_number, VALIDATION_MARKER, body)
