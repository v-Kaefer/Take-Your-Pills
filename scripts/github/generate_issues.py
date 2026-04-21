#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import sys


def run(cmd):
    result = subprocess.run(cmd, text=True, capture_output=True)
    if result.returncode != 0:
        raise RuntimeError(f"GitHub command failed. stderr:\n{result.stderr}")
    return result.stdout.strip()


def create_issue(repo, title, body, labels):
    cmd = [
        "gh", "issue", "create",
        "--repo", repo,
        "--title", title,
        "--body", body,
    ]
    for label in labels:
        cmd += ["--label", label]
    url = run(cmd)
    number = url.rstrip("/").split("/")[-1]
    return int(number)


def issue_node_id(repo, number):
    owner, name = repo.split("/", 1)
    cmd = [
        "gh", "api", "graphql",
        "-f", "query=query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){issue(number:$number){id}}}",
        "-f", f"owner={owner}",
        "-f", f"repo={name}",
        "-F", f"number={number}",
        "--jq", ".data.repository.issue.id",
    ]
    return run(cmd)


def add_sub_issue(repo, parent_number, child_number):
    parent_id = issue_node_id(repo, parent_number)
    child_id = issue_node_id(repo, child_number)
    cmd = [
        "gh", "api", "graphql",
        "-f", "query=mutation($parent:ID!,$child:ID!){addSubIssue(input:{issueId:$parent,subIssueId:$child}){clientMutationId}}",
        "-f", f"parent={parent_id}",
        "-f", f"child={child_id}",
    ]
    run(cmd)


def main():
    parser = argparse.ArgumentParser(description="Generate user stories and tasks from manifest")
    parser.add_argument("manifest", help="Path to backlog-manifest.json")
    parser.add_argument("--repo", default=os.getenv("GITHUB_REPOSITORY"), help="owner/repo")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--link-subissues", action="store_true", help="Link tasks as real GitHub sub-issues")
    args = parser.parse_args()

    if not args.repo:
        print("Missing --repo and GITHUB_REPOSITORY")
        return 1

    with open(args.manifest, "r", encoding="utf-8") as f:
        data = json.load(f)

    for phase in data["phases"]:
        phase_label = phase["phase"]
        for story in phase["stories"]:
            story_labels = list(dict.fromkeys(story["labels"] + data.get("defaultIssueLabels", [])))
            story_body = (
                f"{story['body']}\n\n"
                f"- Phase: {phase['phase']}\n"
                f"- Milestone: {phase['milestone']}\n"
                f"- Item type: user-story\n"
            )
            if args.dry_run:
                print(f"[DRY-RUN] Story: {story['title']} labels={story_labels}")
                story_num = 0
            else:
                story_num = create_issue(args.repo, story["title"], story_body, story_labels)
                print(f"Created story #{story_num}: {story['title']}")

            for task_title in story.get("tasks", []):
                task_labels = ["type:task", phase_label, "status:backlog"]
                task_body = (
                    f"Parent story: {story['id']}"
                    + (f" (#{story_num})" if story_num else "")
                    + "\n\n- Item type: task/sub-issue\n- Test strategy: define in implementation PR\n"
                )
                if args.dry_run:
                    print(f"[DRY-RUN]   Task: {task_title} labels={task_labels}")
                else:
                    task_num = create_issue(args.repo, task_title, task_body, task_labels)
                    print(f"  Created task #{task_num}: {task_title}")
                    if args.link_subissues:
                        add_sub_issue(args.repo, story_num, task_num)
                        print(f"    Linked #{task_num} as sub-issue of #{story_num}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
