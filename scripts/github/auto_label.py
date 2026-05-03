#!/usr/bin/env python3
import argparse
import json
import os
import re
import urllib.error
import urllib.request


API_BASE = "https://api.github.com"
API_VERSION = "2022-11-28"
LABEL_PREFIXES = ("type:", "priority:", "test:")


class GitHubRequestError(RuntimeError):
    def __init__(self, method, url, status, details):
        super().__init__(f"GitHub API request failed ({method} {url}) status={status}: {details}")
        self.status = status


def get_token():
    return os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")


def request_json(method, url, token, payload=None):
    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {token}",
        "X-GitHub-Api-Version": API_VERSION,
        "Content-Type": "application/json",
    }
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as res:
            body = res.read().decode("utf-8")
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as e:
        details = e.read().decode("utf-8", errors="replace")
        raise GitHubRequestError(method, url, e.code, details) from e


def load_event(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def load_allowed_labels(path):
    with open(path, "r", encoding="utf-8") as f:
        return {item["name"] for item in json.load(f)}


def label_names(item):
    return {label["name"] for label in item.get("labels", [])}


def find_test_label(text):
    patterns = [
        r"Test strategy\s*\n+\s*(automated|smoke|manual)\b",
        r"Expected test type\s*\n+\s*(automated|smoke|manual)\b",
        r"Test type:\s*(automated|smoke|manual)\b",
    ]
    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            return f"test:{match.group(1).lower()}"
    return None


def find_priority_label(text):
    match = re.search(r"Severity\s*\n+\s*(critical|high|medium|low)\b", text, re.IGNORECASE)
    return f"priority:{match.group(1).lower()}" if match else None


def title_type_label(title):
    if re.match(r"^US-\d+", title, re.IGNORECASE):
        return "type:user-story"
    if re.match(r"^T-\d+", title, re.IGNORECASE):
        return "type:task"
    if re.match(r"^BUG\b", title, re.IGNORECASE):
        return "type:bug"
    return None


def linked_issue_number(text):
    match = re.search(r"\b(?:closes|fixes|resolves)\s+#(\d+)\b", text, re.IGNORECASE)
    return int(match.group(1)) if match else None


def labels_from_linked_issue(repo, number, token):
    issue = request_json("GET", f"{API_BASE}/repos/{repo}/issues/{number}", token)
    return {
        name
        for name in label_names(issue)
        if name.startswith(LABEL_PREFIXES)
    }


def branch_type_label(branch):
    prefix = branch.split("/", 1)[0].lower()
    if prefix in {"fix", "hotfix"}:
        return "type:bug"
    if prefix in {"docs", "refactor", "test"}:
        return "type:repo"
    return None


def infer_issue_labels(issue):
    current = label_names(issue)
    body = issue.get("body") or ""
    labels = set()

    type_label = next((label for label in current if label.startswith("type:")), None)
    labels.add(type_label or title_type_label(issue.get("title", "")) or "")

    priority_label = find_priority_label(body)
    if priority_label:
        labels.add(priority_label)

    test_label = find_test_label(body)
    if test_label:
        labels.add(test_label)

    if not any(label.startswith("status:") for label in current):
        labels.add("status:backlog")

    return {label for label in labels if label}


def infer_pr_labels(repo, pr, token):
    body = pr.get("body") or ""
    labels = set()

    number = linked_issue_number(body)
    if number and token:
        try:
            labels.update(labels_from_linked_issue(repo, number, token))
        except GitHubRequestError as exc:
            print(f"warning: could not read linked issue #{number}: {exc}")

    test_label = find_test_label(body)
    if test_label:
        labels.add(test_label)

    if not any(label.startswith("type:") for label in labels):
        branch = pr.get("head", {}).get("ref", "")
        type_label = branch_type_label(branch)
        if type_label:
            labels.add(type_label)

    return labels


def event_target(event):
    if "issue" in event and "pull_request" not in event["issue"]:
        return "issue", event["issue"], event["issue"]["number"]
    if "pull_request" in event:
        return "pull_request", event["pull_request"], event["pull_request"]["number"]
    raise RuntimeError("Unsupported event payload: expected issue or pull_request")


def main():
    parser = argparse.ArgumentParser(description="Apply repository labels inferred from issue or PR metadata")
    parser.add_argument("--event-path", default=os.environ.get("GITHUB_EVENT_PATH"), help="Path to GitHub event payload")
    parser.add_argument("--labels-file", default="config/project/labels.json")
    parser.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY"), help="owner/repo")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if not args.event_path:
        print("Missing --event-path or GITHUB_EVENT_PATH")
        return 1
    if not args.repo:
        print("Missing --repo or GITHUB_REPOSITORY")
        return 1

    event = load_event(args.event_path)
    allowed = load_allowed_labels(args.labels_file)
    target_type, item, number = event_target(event)
    current = label_names(item)
    token = get_token()

    if target_type == "issue":
        inferred = infer_issue_labels(item)
    else:
        inferred = infer_pr_labels(args.repo, item, token)

    labels = sorted(label for label in inferred if label in allowed and label not in current)
    if not labels:
        print(f"No labels to add for {target_type} #{number}")
        return 0

    print(f"Labels to add to {target_type} #{number}: {', '.join(labels)}")
    if args.dry_run:
        return 0

    if not token:
        print("Missing GITHUB_TOKEN or GH_TOKEN")
        return 1

    try:
        request_json("POST", f"{API_BASE}/repos/{args.repo}/issues/{number}/labels", token, {"labels": labels})
    except GitHubRequestError as exc:
        if exc.status == 403:
            print(f"warning: token cannot add labels to {target_type} #{number}; skipping")
            return 0
        raise
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
