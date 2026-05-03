#!/usr/bin/env python3
import argparse
import json
import os
import re
import urllib.error
import urllib.request


API_BASE = "https://api.github.com"
API_VERSION = "2022-11-28"


def get_token():
    return os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")


def request_json(method, url, token, payload=None):
    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {token}",
        "X-GitHub-Api-Version": API_VERSION,
        "Content-Type": "application/json",
    }
    data = None
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as res:
            body = res.read().decode("utf-8")
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as e:
        details = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"GitHub API request failed ({method} {url}) status={e.code}: {details}") from e


def list_paginated(path, token):
    items = []
    page = 1
    while True:
        sep = "&" if "?" in path else "?"
        batch = request_json("GET", f"{path}{sep}per_page=100&page={page}", token)
        items.extend(batch)
        if len(batch) < 100:
            break
        page += 1
    return items


def milestone_from_body(body):
    if not body:
        return None
    match = re.search(r"-\s*Milestone:\s*(MS\d+)", body)
    return match.group(1) if match else None


def parent_issue_number_from_body(body):
    if not body:
        return None
    match = re.search(r"Parent story:.*\(#(\d+)\)", body)
    return int(match.group(1)) if match else None


def sync_milestones(repo, token, clear_not_planned=False, dry_run=False):
    owner, name = repo.split("/", 1)
    repo_base = f"{API_BASE}/repos/{owner}/{name}"

    milestones = list_paginated(f"{repo_base}/milestones?state=all", token)
    milestone_by_title = {milestone["title"]: milestone for milestone in milestones}

    issues = [
        issue
        for issue in list_paginated(f"{repo_base}/issues?state=all&sort=created&direction=asc", token)
        if "pull_request" not in issue
    ]
    explicit_milestone_by_issue = {}
    for issue in issues:
        milestone = milestone_from_body(issue.get("body") or "")
        if milestone:
            explicit_milestone_by_issue[issue["number"]] = milestone

    updated = 0
    cleared = 0
    already_correct = 0
    unmapped = []

    for issue in issues:
        issue_number = issue["number"]
        current = issue.get("milestone")
        current_title = current["title"] if current else None

        if clear_not_planned and issue.get("state") == "closed" and issue.get("state_reason") == "not_planned":
            if current_title:
                if dry_run:
                    print(f"[DRY-RUN] Would clear milestone from not-planned issue #{issue_number}: {current_title}")
                else:
                    request_json("PATCH", f"{repo_base}/issues/{issue_number}", token, {"milestone": None})
                    print(f"cleared #{issue_number}: {current_title}")
                cleared += 1
            else:
                already_correct += 1
            continue

        target = explicit_milestone_by_issue.get(issue_number)
        if not target:
            parent_number = parent_issue_number_from_body(issue.get("body") or "")
            if parent_number:
                target = explicit_milestone_by_issue.get(parent_number)

        if not target:
            unmapped.append((issue_number, issue["title"]))
            continue

        milestone = milestone_by_title.get(target)
        if not milestone:
            raise RuntimeError(f"Milestone '{target}' referenced by issue #{issue_number} does not exist")

        if current_title == target:
            already_correct += 1
            continue

        if dry_run:
            print(f"[DRY-RUN] Would set issue #{issue_number}: {current_title or 'none'} -> {target}")
        else:
            request_json("PATCH", f"{repo_base}/issues/{issue_number}", token, {"milestone": milestone["number"]})
            print(f"updated #{issue_number}: {current_title or 'none'} -> {target}")
        updated += 1

    print(f"issues_checked={len(issues)}")
    print(f"updated={updated}")
    print(f"cleared_not_planned={cleared}")
    print(f"already_correct={already_correct}")
    print(f"unmapped={len(unmapped)}")
    for issue_number, title in unmapped:
        print(f"unmapped #{issue_number}: {title}")


def main():
    parser = argparse.ArgumentParser(description="Sync repository issue milestones from generated issue metadata")
    parser.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY"), help="owner/repo")
    parser.add_argument("--clear-not-planned", action="store_true", help="Clear milestones from closed not-planned issues")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if not args.repo:
        print("Missing --repo and GITHUB_REPOSITORY")
        return 1

    token = get_token()
    if not token:
        print("Missing GITHUB_TOKEN or GH_TOKEN")
        return 1

    sync_milestones(args.repo, token, clear_not_planned=args.clear_not_planned, dry_run=args.dry_run)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
