from __future__ import annotations

import json
import os
import subprocess


def run_gh(cmd: list[str]) -> str:
    result = subprocess.run(cmd, text=True, capture_output=True)
    if result.returncode != 0:
        raise RuntimeError(f"GitHub command failed. stderr:\n{result.stderr}")
    return result.stdout.strip()


def create_issue(repo: str, title: str, body: str, labels: list[str]) -> int:
    cmd = ["gh", "issue", "create", "--repo", repo, "--title", title, "--body", body]
    for label in labels:
        cmd += ["--label", label]
    url = run_gh(cmd)
    parts = url.rstrip("/").split("/")
    if len(parts) < 2 or not parts[-1].isdigit():
        raise RuntimeError(f"Unexpected gh issue create output: {url}")
    return int(parts[-1])


def issue_node_id(repo: str, number: int) -> str:
    owner, name = repo.split("/", 1)
    return run_gh([
        "gh", "api", "graphql",
        "-f", "query=query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){issue(number:$number){id}}}",
        "-f", f"owner={owner}",
        "-f", f"repo={name}",
        "-F", f"number={number}",
        "--jq", ".data.repository.issue.id",
    ])


def add_sub_issue(repo: str, parent_number: int, child_number: int) -> None:
    parent_id = issue_node_id(repo, parent_number)
    child_id = issue_node_id(repo, child_number)
    run_gh([
        "gh", "api", "graphql",
        "-f", "query=mutation($parent:ID!,$child:ID!){addSubIssue(input:{issueId:$parent,subIssueId:$child}){clientMutationId}}",
        "-f", f"parent={parent_id}",
        "-f", f"child={child_id}",
    ])


def load_backlog(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    if "phases" not in data:
        raise ValueError("backlog manifest must contain phases")
    return data


def render_section_content(content: str | list[str] | None, fallback: str = "- TBD") -> str:
    if content is None:
        return fallback
    if isinstance(content, str):
        stripped = content.strip()
        return stripped or fallback
    if isinstance(content, list):
        if not content:
            return fallback
        return "\n".join(f"- {item}" for item in content)
    raise TypeError(f"Unsupported section content type: {type(content)!r}")


def render_section(title: str, content: str | list[str] | None, fallback: str = "- TBD") -> str:
    return f"## {title}\n{render_section_content(content, fallback)}\n\n"


def task_title(task: str | dict) -> str:
    if isinstance(task, str):
        return task
    title = task.get("title")
    if not title:
        raise ValueError("task objects must include a title")
    return title


def task_labels(task: str | dict) -> list[str]:
    labels = ["type:task", "status:backlog"]
    if isinstance(task, dict):
        labels.extend(task.get("labels", []))
    return list(dict.fromkeys(labels))


def task_body(story: dict, story_num: int, task: str | dict) -> str:
    parent_ref = f"Parent story: {story['storyId']}"
    if story_num:
        parent_ref += f" (#{story_num})"

    if isinstance(task, str):
        return (
            f"{parent_ref}\n\n"
            + "## Technical scope\n- TBD\n\n"
            + "## Completion criteria\n- TBD\n\n"
            + "## Test strategy\n- TBD\n\n"
            + "## Expected evidence\n- TBD\n\n"
            + "## Definition of Done\n- TBD\n\n"
            + "- Item type: task/sub-issue\n"
        )

    return (
        f"{parent_ref}\n\n"
        + render_section("Technical scope", task.get("technicalScope"))
        + render_section("Completion criteria", task.get("completionCriteria"))
        + render_section("Test strategy", task.get("testStrategy"))
        + render_section("Expected evidence", task.get("expectedEvidence"))
        + render_section("Definition of Done", task.get("dod"))
        + "- Item type: task/sub-issue\n"
    )


def generate_issues(repo: str, manifest: str, dry_run: bool = False, link_subissues: bool = False) -> None:
    if not repo:
        repo = os.getenv("GITHUB_REPOSITORY", "")
    if not repo:
        raise SystemExit("Missing --repo and GITHUB_REPOSITORY")

    data = load_backlog(manifest)
    for phase in data["phases"]:
        for story in phase["stories"]:
            story_labels = list(dict.fromkeys(story["labels"] + data.get("defaultIssueLabels", [])))
            story_body = (
                f"{story['body']}\n\n"
                + render_section("Acceptance criteria", story.get("acceptanceCriteria"))
                + render_section("Test strategy", story.get("testStrategy"))
                + render_section("Definition of Done", story.get("dod"))
                + f"- Milestone: {phase['milestone']}\n"
                + f"- Item type: user-story\n"
            )
            if dry_run:
                print(f"[DRY-RUN] Story: {story['title']} labels={story_labels}")
                story_num = 0
            else:
                story_num = create_issue(repo, story["title"], story_body, story_labels)
                print(f"Created story #{story_num}: {story['title']}")

            for task in story.get("tasks", []):
                current_task_title = task_title(task)
                current_task_labels = task_labels(task)
                current_task_body = task_body(story, story_num, task)
                if dry_run:
                    print(f"[DRY-RUN]   Task: {current_task_title} labels={current_task_labels}")
                    continue
                task_num = create_issue(repo, current_task_title, current_task_body, current_task_labels)
                print(f"  Created task #{task_num}: {current_task_title}")
                if link_subissues:
                    add_sub_issue(repo, story_num, task_num)
                    print(f"    Linked #{task_num} as sub-issue of #{story_num}")
