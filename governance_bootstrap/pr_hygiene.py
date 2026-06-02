from __future__ import annotations

from dataclasses import dataclass
import json
import os
import re

from .comments import upsert_marked_comment
from .github import GitHubClient, GitHubRequestError, split_repo
from .project import (
    add_issue_to_project,
    add_sub_issue,
    find_project,
    issue_node_id,
    list_project_fields,
    list_project_items,
    option_id,
    parent_issue_number_from_body,
    update_single_select,
)


HYGIENE_MARKER = "<!-- governance-pr-hygiene -->"
LINKED_TASK_PATTERN = re.compile(r"\b(?:closes|fixes|resolves)\s*:?\s+#(\d+)\b", re.IGNORECASE)
SYNC_LABEL_PREFIXES = ("type:", "priority:", "test:")


@dataclass(frozen=True)
class PullRequestContext:
    number: int
    action: str
    body: str
    base_ref: str
    head_ref: str
    author: str
    draft: bool
    merged: bool


def load_event(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def context_from_event(event: dict) -> PullRequestContext:
    pr = event.get("pull_request")
    if not pr:
        raise RuntimeError("Unsupported event payload: expected pull_request")
    return PullRequestContext(
        number=int(pr["number"]),
        action=event.get("action", ""),
        body=pr.get("body") or "",
        base_ref=pr.get("base", {}).get("ref", ""),
        head_ref=pr.get("head", {}).get("ref", ""),
        author=pr.get("user", {}).get("login", ""),
        draft=bool(pr.get("draft")),
        merged=bool(pr.get("merged")),
    )


def linked_task_number(body: str) -> int | None:
    match = LINKED_TASK_PATTERN.search(body or "")
    return int(match.group(1)) if match else None


def is_release_pr(ctx: PullRequestContext) -> bool:
    return ctx.base_ref == "main" and ctx.head_ref == "develop"


def is_hotfix_pr(ctx: PullRequestContext) -> bool:
    return bool(re.fullmatch(r"hotfix/[a-z0-9._/-]+", ctx.head_ref or ""))


def label_names(item: dict) -> set[str]:
    return {label["name"] for label in item.get("labels", [])}


def assignee_logins(item: dict) -> list[str]:
    return [assignee["login"] for assignee in item.get("assignees", []) if assignee.get("login")]


def milestone_number(item: dict) -> int | None:
    milestone = item.get("milestone")
    if milestone and milestone.get("number") is not None:
        return int(milestone["number"])
    return None


def project_status_for_event(ctx: PullRequestContext) -> str:
    if ctx.action == "closed":
        return "Done" if ctx.merged else "In progress"
    if ctx.action == "converted_to_draft" or ctx.draft:
        return "In progress"
    return "In review"


def normalized_option(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", value.lower())


def status_option_id(field: dict, desired: str) -> str | None:
    desired_norm = normalized_option(desired)
    for option in field.get("options", []):
        if normalized_option(option["name"]) == desired_norm:
            return option["id"]
    return option_id(field, desired)


def render_failure_comment(message: str) -> str:
    return "\n".join(
        [
            HYGIENE_MARKER,
            "## PR hygiene needs attention",
            "",
            message,
            "",
            "Link the implementation task in the PR body with `Closes #123`, `Fixes #123`, or `Resolves #123`.",
        ]
    )


def render_success_comment(ctx: PullRequestContext, task_number: int, status: str) -> str:
    return "\n".join(
        [
            HYGIENE_MARKER,
            "## PR hygiene",
            "",
            f"- Linked task: #{task_number}",
            f"- Project status: `{status}`",
            f"- PR: #{ctx.number}",
        ]
    )


def sync_pr_metadata(client: GitHubClient, repo: str, ctx: PullRequestContext, task: dict, pr_issue: dict, dry_run: bool = False) -> None:
    task_labels = sorted(label for label in label_names(task) if label.startswith(SYNC_LABEL_PREFIXES))
    current_pr_labels = label_names(pr_issue)
    labels_to_add = [label for label in task_labels if label not in current_pr_labels]
    if labels_to_add:
        if dry_run:
            print(f"[DRY-RUN] Would add labels to PR #{ctx.number}: {', '.join(labels_to_add)}")
        else:
            client.add_issue_labels(repo, ctx.number, labels_to_add)

    task_milestone = milestone_number(task)
    pr_milestone = milestone_number(pr_issue)
    if task_milestone is not None and task_milestone != pr_milestone:
        if dry_run:
            print(f"[DRY-RUN] Would set PR #{ctx.number} milestone to {task_milestone}")
        else:
            client.update_issue_milestone(repo, ctx.number, task_milestone)

    task_assignees = assignee_logins(task)
    if not task_assignees and ctx.author:
        task_assignees = [ctx.author]
        if dry_run:
            print(f"[DRY-RUN] Would assign task #{task['number']} to {ctx.author}")
        else:
            client.add_issue_assignees(repo, task["number"], [ctx.author])

    current_pr_assignees = set(assignee_logins(pr_issue))
    pr_assignees_to_add = [assignee for assignee in task_assignees if assignee not in current_pr_assignees]
    if pr_assignees_to_add:
        if dry_run:
            print(f"[DRY-RUN] Would assign PR #{ctx.number} to {', '.join(pr_assignees_to_add)}")
        else:
            client.add_issue_assignees(repo, ctx.number, pr_assignees_to_add)


def sync_task_project_status(
    client: GitHubClient,
    repo: str,
    project_number: int,
    task: dict,
    status: str,
    owner: str | None = None,
    dry_run: bool = False,
) -> None:
    project_owner = owner or split_repo(repo)[0]
    project, _owner_type = find_project(client, project_owner, project_number)
    fields = {field["name"]: field for field in list_project_fields(client, project["id"]) if field and field.get("name")}
    status_field = fields.get("Status")
    if not status_field:
        raise RuntimeError("Project field `Status` was not found")
    oid = status_option_id(status_field, status)
    if not oid:
        options = ", ".join(option["name"] for option in status_field.get("options", []))
        raise RuntimeError(f"Project Status option `{status}` was not found. Available options: {options}")

    task_node_id = task.get("node_id") or issue_node_id(client, repo, task["number"])
    current_items = list_project_items(client, project["id"])
    item_id = current_items.get(task_node_id)
    if not item_id:
        if dry_run:
            print(f"[DRY-RUN] Would add task #{task['number']} to project")
            item_id = f"dry-run-item-{task['number']}"
        else:
            item_id = add_issue_to_project(client, project["id"], task_node_id)
            print(f"Added task #{task['number']} to project")

    if dry_run:
        print(f"[DRY-RUN] Would set task #{task['number']} project Status to {status}")
    else:
        update_single_select(client, project["id"], item_id, status_field["id"], oid)


def sync_parent_relationship(client: GitHubClient, repo: str, task: dict, dry_run: bool = False) -> None:
    parent_number = parent_issue_number_from_body(task.get("body", "") or "")
    if parent_number is None:
        return
    if dry_run:
        print(f"[DRY-RUN] Would link task #{task['number']} as sub-issue of #{parent_number}")
        return
    parent_id = issue_node_id(client, repo, parent_number)
    try:
        add_sub_issue(client, parent_id, task.get("node_id") or issue_node_id(client, repo, task["number"]))
    except RuntimeError as exc:
        error_text = str(exc).lower()
        if "already" in error_text or "exists" in error_text or "duplicate sub-issues" in error_text or "may only have one parent" in error_text:
            print(f"Sub-issue link already exists: #{task['number']} -> #{parent_number}")
            return
        raise


def apply_pr_hygiene(
    client: GitHubClient,
    repo: str,
    event: dict,
    project_number: int,
    owner: str | None = None,
    dry_run: bool = False,
) -> int:
    ctx = context_from_event(event)
    if is_release_pr(ctx):
        print("Skipping PR hygiene for develop -> main release PR.")
        return 0
    if is_hotfix_pr(ctx):
        print("Skipping PR hygiene for hotfix PR.")
        return 0

    task_number = linked_task_number(ctx.body)
    if task_number is None:
        message = "No linked implementation task was found in this PR body."
        if dry_run:
            print(render_failure_comment(message))
        else:
            upsert_marked_comment(client, repo, ctx.number, HYGIENE_MARKER, render_failure_comment(message))
        return 1

    task = client.get_issue(repo, task_number)
    if "pull_request" in task:
        message = f"Linked item #{task_number} is a pull request, not an implementation task."
        if dry_run:
            print(render_failure_comment(message))
        else:
            upsert_marked_comment(client, repo, ctx.number, HYGIENE_MARKER, render_failure_comment(message))
        return 1

    pr_issue = client.get_issue(repo, ctx.number)
    status = project_status_for_event(ctx)

    sync_pr_metadata(client, repo, ctx, task, pr_issue, dry_run=dry_run)
    sync_task_project_status(client, repo, project_number, task, status, owner=owner, dry_run=dry_run)
    sync_parent_relationship(client, repo, task, dry_run=dry_run)

    if dry_run:
        print(render_success_comment(ctx, task_number, status))
    else:
        try:
            upsert_marked_comment(client, repo, ctx.number, HYGIENE_MARKER, render_success_comment(ctx, task_number, status))
        except GitHubRequestError as exc:
            if exc.status != 403:
                raise
            print(f"warning: token cannot update PR hygiene comment: {exc}")
    return 0


def apply_pr_hygiene_from_path(
    client: GitHubClient,
    repo: str,
    event_path: str,
    project_number: int,
    owner: str | None = None,
    dry_run: bool = False,
) -> int:
    return apply_pr_hygiene(client, repo, load_event(event_path), project_number, owner=owner, dry_run=dry_run)


def project_number_arg(value: int | None) -> int:
    raw = value if value is not None else os.getenv("GOVERNANCE_PROJECT_NUMBER")
    if raw is None or str(raw).strip() == "":
        raise SystemExit("Missing --project-number and GOVERNANCE_PROJECT_NUMBER")
    return int(raw)
