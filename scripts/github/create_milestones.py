#!/usr/bin/env python3
import argparse
import json
import os
import sys
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
            return json.loads(body) if body else []
    except urllib.error.HTTPError as e:
        details = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"GitHub API request failed ({method} {url}) status={e.code}: {details}") from e


def main():
    parser = argparse.ArgumentParser(description="Create repository milestones from a manifest")
    parser.add_argument("milestones_file", help="Path to milestones.json")
    parser.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY"), help="owner/repo")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if not args.repo:
        print("Missing --repo and GITHUB_REPOSITORY")
        return 1

    with open(args.milestones_file, "r", encoding="utf-8") as f:
        milestones = json.load(f)

    if args.dry_run:
        print(f"[DRY-RUN] Would sync {len(milestones)} milestones to {args.repo}")
        for milestone in milestones:
            print(f"- {milestone['title']} ({milestone.get('due_on', 'no-due-date')})")
        return 0

    token = get_token()
    if not token:
        print("Missing GITHUB_TOKEN or GH_TOKEN")
        return 1

    owner, name = args.repo.split("/", 1)
    base = f"{API_BASE}/repos/{owner}/{name}/milestones"
    existing = request_json("GET", f"{base}?state=all&per_page=100", token)
    existing_by_title = {item["title"]: item for item in existing}

    for milestone in milestones:
        title = milestone["title"]
        payload = {
            "title": title,
            "description": milestone.get("description", ""),
        }
        if milestone.get("due_on"):
            payload["due_on"] = milestone["due_on"]

        if title in existing_by_title:
            print(f"exists: {title}")
            continue

        request_json("POST", base, token, payload)
        print(f"created: {title}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

