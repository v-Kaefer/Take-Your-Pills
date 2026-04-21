#!/usr/bin/env python3
import json
import os
import sys
import urllib.request
import urllib.error
import urllib.parse


def gh_request(method, url, token, payload=None):
    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {token}",
        "X-GitHub-Api-Version": "2022-11-28",
        "Content-Type": "application/json",
    }
    data = None
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    with urllib.request.urlopen(req) as res:
        body = res.read().decode("utf-8")
        return json.loads(body) if body else {}


def main():
    if len(sys.argv) != 2:
        print("Usage: sync_labels.py <labels.json>")
        return 2

    labels_file = sys.argv[1]
    token = os.environ.get("GITHUB_TOKEN")
    repo = os.environ.get("GITHUB_REPOSITORY")
    if not token or not repo:
        print("Missing GITHUB_TOKEN or GITHUB_REPOSITORY")
        return 1

    owner, name = repo.split("/", 1)
    with open(labels_file, "r", encoding="utf-8") as f:
        labels = json.load(f)

    for label in labels:
        base = f"https://api.github.com/repos/{owner}/{name}/labels"
        try:
            gh_request("POST", base, token, label)
            print(f"created: {label['name']}")
        except urllib.error.HTTPError as e:
            if e.code == 422:
                patch_url = f"{base}/{urllib.parse.quote(label['name'])}"
                gh_request("PATCH", patch_url, token, label)
                print(f"updated: {label['name']}")
            else:
                raise

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
