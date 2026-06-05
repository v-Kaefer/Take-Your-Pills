from __future__ import annotations

from dataclasses import dataclass
import json
import re

from .comments import upsert_marked_comment
from .github import GitHubClient
from .issue_milestones import parent_issue_number_from_body
from .issues import task_title
from .project import list_repo_issues, milestone_from_issue


AUTOFILL_MARKER = "<!-- governance-pr-autofill -->"
BRANCH_STORY_PATTERN = re.compile(r"(?i)(?:^|[^A-Z0-9])US-(\d+)(?=$|[^A-Z0-9])")
SECTION_HEADING_PATTERN = re.compile(r"^##\s+(.+?)\s*$")
TARGET_SECTIONS = ("Linked Issue", "Milestone")


@dataclass(frozen=True)
class ResolvedTaskIssue:
    title: str
    number: int


@dataclass(frozen=True)
class AutofillOutcome:
    branch: str
    story_key: str | None
    story_title: str | None
    story_issue_number: int | None
    milestone: str | None
    milestone_source: str | None
    body_updated: bool
    found_tasks: list[ResolvedTaskIssue]
    missing_tasks: list[str]
    notes: list[str]


def load_event(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def load_backlog(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    if "phases" not in data:
        raise ValueError("backlog manifest must contain phases")
    return data


def normalize_text(value: str) -> str:
    return " ".join(value.strip().split()).casefold()


def branch_story_number(branch: str) -> int | None:
    match = BRANCH_STORY_PATTERN.search(branch or "")
    return int(match.group(1)) if match else None


def story_number_from_id(story_id: str | None) -> int | None:
    if not story_id:
        return None
    match = re.search(r"\d+", story_id)
    return int(match.group(0)) if match else None


def find_story_definition(backlog: dict, story_number: int) -> tuple[dict, dict] | None:
    for phase in backlog.get("phases", []):
        for story in phase.get("stories", []):
            if story_number_from_id(story.get("storyId")) == story_number:
                return phase, story
    return None


def build_issue_index(issues: list[dict]) -> dict[str, list[dict]]:
    index: dict[str, list[dict]] = {}
    for issue in issues:
        title = normalize_text(issue.get("title", ""))
        if not title:
            continue
        index.setdefault(title, []).append(issue)
    return index


def find_issue_by_title(issue_index: dict[str, list[dict]], title: str) -> tuple[dict | None, str | None]:
    key = normalize_text(title)
    matches = issue_index.get(key, [])
    if not matches:
        return None, f"No issue named `{title}` was found."

    open_matches = [issue for issue in matches if issue.get("state") == "open"]
    if len(open_matches) == 1:
        return open_matches[0], None
    if len(open_matches) > 1:
        return None, f"Found {len(open_matches)} open issues named `{title}`."

    if len(matches) == 1:
        return matches[0], None
    return None, f"Found {len(matches)} issues named `{title}`."


def split_body(body: str) -> tuple[list[str], list[tuple[str, list[str]]]]:
    preamble: list[str] = []
    sections: list[tuple[str, list[str]]] = []
    current_name: str | None = None
    current_lines: list[str] = []

    for line in (body or "").splitlines():
        heading = SECTION_HEADING_PATTERN.match(line)
        if heading:
            if current_name is None:
                preamble = preamble or []
            else:
                sections.append((current_name, current_lines))
            current_name = heading.group(1)
            current_lines = []
            continue

        if current_name is None:
            preamble.append(line)
        else:
            current_lines.append(line)

    if current_name is not None:
        sections.append((current_name, current_lines))

    return preamble, sections


def render_body(preamble: list[str], sections: list[tuple[str, list[str]]]) -> str:
    parts: list[str] = []
    if preamble:
        parts.append("\n".join(preamble).rstrip())

    for name, lines in sections:
        section = f"## {name}"
        content = "\n".join(lines).rstrip()
        if content:
            section += f"\n{content}"
        parts.append(section)

    if not parts:
        return ""
    return "\n\n".join(parts).rstrip() + "\n"


def linked_issue_section(issue_number: int) -> list[str]:
    return [
        f"- Closes #{issue_number}",
        f"- Troque `#{issue_number}` pela issue que esta PR resolve.",
    ]


def milestone_section(milestone: str) -> list[str]:
    return [
        f"- {milestone}",
        "- Use o milestone correto da entrega.",
    ]


def rewrite_pr_body(body: str, issue_number: int, milestone: str) -> tuple[str, bool]:
    preamble, sections = split_body(body)
    section_map = {normalize_text(name): (name, lines) for name, lines in sections}
    rewritten_sections: list[tuple[str, list[str]]] = []

    for target_name in TARGET_SECTIONS:
        if target_name == "Linked Issue":
            content = linked_issue_section(issue_number)
        else:
            content = milestone_section(milestone)
        existing = section_map.get(normalize_text(target_name))
        if existing:
            rewritten_sections.append((existing[0], content))
        else:
            rewritten_sections.append((target_name, content))

    for name, lines in sections:
        if normalize_text(name) in {normalize_text(target) for target in TARGET_SECTIONS}:
            continue
        rewritten_sections.append((name, lines))

    rendered = render_body(preamble, rewritten_sections)
    return rendered, rendered != (body or "")


def resolve_related_tasks(
    issue_index: dict[str, list[dict]],
    story_number: int | None,
    task_defs: list[str | dict],
) -> tuple[list[ResolvedTaskIssue], list[str], list[str]]:
    found: list[ResolvedTaskIssue] = []
    missing: list[str] = []
    notes: list[str] = []

    for task_def in task_defs:
        title = task_title(task_def)
        issue, note = find_issue_by_title(issue_index, title)
        if not issue:
            missing.append(title)
            if note:
                notes.append(note)
            continue

        parent_number = parent_issue_number_from_body(issue.get("body") or "")
        if story_number is not None and parent_number is not None and parent_number != story_number:
            notes.append(
                f"Issue `{title}` (#{issue['number']}) points to parent #{parent_number}, not #{story_number}."
            )
            continue

        if story_number is not None and parent_number is None:
            notes.append(f"Issue `{title}` (#{issue['number']}) has no parent story reference in the body.")

        found.append(ResolvedTaskIssue(title=title, number=int(issue["number"])))

    return found, missing, notes


def render_comment(outcome: AutofillOutcome) -> str:
    lines = [
        AUTOFILL_MARKER,
        "## PR metadata autofill",
        "",
        f"- Branch: `{outcome.branch}`",
    ]

    if outcome.story_key and outcome.story_title and outcome.story_issue_number is not None:
        lines.append(f"- Story: `{outcome.story_key}` -> `{outcome.story_title}` (#{outcome.story_issue_number})")
    elif outcome.story_key and outcome.story_title:
        lines.append(f"- Story: `{outcome.story_key}` -> `{outcome.story_title}`")
    elif outcome.story_key:
        lines.append(f"- Story: `{outcome.story_key}`")
    else:
        lines.append("- Story: not found in branch name")

    if outcome.milestone:
        source = f" from {outcome.milestone_source}" if outcome.milestone_source else ""
        lines.append(f"- Milestone: `{outcome.milestone}`{source}")
    else:
        lines.append("- Milestone: not resolved")

    if outcome.body_updated:
        lines.append("- PR body: updated Linked Issue and Milestone")
    else:
        lines.append("- PR body: unchanged")

    if outcome.found_tasks:
        lines.append("- Related issues found:")
        for task in outcome.found_tasks:
            lines.append(f"  - `{task.title}` (#{task.number})")
    else:
        lines.append("- Related issues found: none")

    if outcome.missing_tasks:
        lines.append("- Missing related issues:")
        for title in outcome.missing_tasks:
            lines.append(f"  - `{title}`")

    if outcome.notes:
        lines.append("- Notes:")
        for note in outcome.notes:
            lines.append(f"  - {note}")

    return "\n".join(lines)


def apply_pr_autofill(
    client: GitHubClient,
    repo: str,
    event: dict,
    backlog_file: str,
    dry_run: bool = False,
) -> int:
    pr = event.get("pull_request")
    if not pr:
        raise RuntimeError("Unsupported event payload: expected pull_request")

    branch = pr.get("head", {}).get("ref", "") or ""
    story_num = branch_story_number(branch)
    notes: list[str] = []
    story_key: str | None = None
    story_title: str | None = None
    story_issue_number: int | None = None
    milestone: str | None = None
    milestone_source: str | None = None
    body_updated = False
    found_tasks: list[ResolvedTaskIssue] = []
    missing_tasks: list[str] = []

    if story_num is None:
        notes.append("No `US-<number>` token was found in the branch name.")
        outcome = AutofillOutcome(
            branch=branch,
            story_key=None,
            story_title=None,
            story_issue_number=None,
            milestone=None,
            milestone_source=None,
            body_updated=False,
            found_tasks=[],
            missing_tasks=[],
            notes=notes,
        )
        if dry_run:
            print(render_comment(outcome))
        else:
            upsert_marked_comment(client, repo, int(pr["number"]), AUTOFILL_MARKER, render_comment(outcome))
        return 0

    backlog = load_backlog(backlog_file)
    story_match = find_story_definition(backlog, story_num)
    if not story_match:
        notes.append(f"No backlog story matches `US-{story_num:02d}`.")
        outcome = AutofillOutcome(
            branch=branch,
            story_key=f"US-{story_num:02d}",
            story_title=None,
            story_issue_number=None,
            milestone=None,
            milestone_source=None,
            body_updated=False,
            found_tasks=[],
            missing_tasks=[],
            notes=notes,
        )
        if dry_run:
            print(render_comment(outcome))
        else:
            upsert_marked_comment(client, repo, int(pr["number"]), AUTOFILL_MARKER, render_comment(outcome))
        return 0

    phase, story = story_match
    story_key = story["storyId"]
    story_title = story["title"]
    phase_milestone = phase.get("milestone")

    issues = list_repo_issues(client, repo, state="all")
    issue_index = build_issue_index(issues)

    story_issue, story_note = find_issue_by_title(issue_index, story_title)
    if story_note:
        notes.append(story_note)
    if story_issue:
        story_issue_number = int(story_issue["number"])

    if story_issue:
        issue_milestone = milestone_from_issue(story_issue)
        if issue_milestone:
            milestone = issue_milestone
            milestone_source = "issue"
            if phase_milestone and issue_milestone != phase_milestone:
                notes.append(
                    f"Story issue milestone `{issue_milestone}` differs from backlog manifest milestone `{phase_milestone}`; using the issue value."
                )
        elif phase_milestone:
            milestone = phase_milestone
            milestone_source = "manifest"
            notes.append(f"Story issue milestone is missing; using backlog manifest milestone `{phase_milestone}`.")
        else:
            notes.append("Neither the story issue nor the backlog manifest define a milestone.")
    elif phase_milestone:
        milestone = phase_milestone
        milestone_source = "manifest"

    found_tasks, missing_tasks, task_notes = resolve_related_tasks(issue_index, story_issue_number, story.get("tasks", []))
    notes.extend(task_notes)

    current_body = pr.get("body") or ""
    if story_issue_number is not None and milestone:
        updated_body, changed = rewrite_pr_body(current_body, story_issue_number, milestone)
        body_updated = changed
        if changed:
            if dry_run:
                print("[DRY-RUN] Would update PR body with Linked Issue and Milestone.")
            else:
                client.update_issue_body(repo, int(pr["number"]), updated_body)
        else:
            notes.append("PR body already matched the resolved story and milestone.")
    else:
        if story_issue_number is None:
            notes.append("Could not resolve a story issue number for the PR body.")
        if not milestone:
            notes.append("Could not resolve a milestone for the PR body.")

    outcome = AutofillOutcome(
        branch=branch,
        story_key=story_key,
        story_title=story_title,
        story_issue_number=story_issue_number,
        milestone=milestone,
        milestone_source=milestone_source,
        body_updated=body_updated,
        found_tasks=found_tasks,
        missing_tasks=missing_tasks,
        notes=notes,
    )

    comment = render_comment(outcome)
    if dry_run:
        print(comment)
    else:
        upsert_marked_comment(client, repo, int(pr["number"]), AUTOFILL_MARKER, comment)
    return 0


def apply_pr_autofill_from_path(
    client: GitHubClient,
    repo: str,
    event_path: str,
    backlog_file: str,
    dry_run: bool = False,
) -> int:
    return apply_pr_autofill(client, repo, load_event(event_path), backlog_file, dry_run=dry_run)
