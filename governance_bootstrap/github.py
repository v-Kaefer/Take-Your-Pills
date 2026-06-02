from __future__ import annotations

import json
import os
from pathlib import Path
import time
from typing import Any
import urllib.error
import urllib.parse
import urllib.request


API_BASE = "https://api.github.com"
GRAPHQL_URL = f"{API_BASE}/graphql"
API_VERSION = "2022-11-28"
RETRYABLE_HTTP_STATUS = {502, 503, 504}


class GitHubRequestError(RuntimeError):
    def __init__(self, method: str, url: str, status: int, details: str):
        super().__init__(f"GitHub API request failed ({method} {url}) status={status}: {details}")
        self.method = method
        self.url = url
        self.status = status
        self.details = details


def get_token() -> str | None:
    return os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")


def split_repo(repo: str) -> tuple[str, str]:
    if "/" not in repo:
        raise ValueError("repository must use owner/name format")
    return repo.split("/", 1)


class GitHubClient:
    def __init__(self, token: str):
        self.token = token

    def _headers(self, accept: str = "application/vnd.github+json", content_type: str | None = "application/json") -> dict[str, str]:
        headers = {
            "Accept": accept,
            "Authorization": f"Bearer {self.token}",
            "X-GitHub-Api-Version": API_VERSION,
        }
        if content_type:
            headers["Content-Type"] = content_type
        return headers

    def request_json(self, method: str, url: str, payload=None, accept: str = "application/vnd.github+json"):
        headers = self._headers(accept=accept)
        data = json.dumps(payload).encode("utf-8") if payload is not None else None
        return self.request_data_json(method, url, data, headers)

    def request_data_json(self, method: str, url: str, data: bytes | None, headers: dict[str, str]):
        for attempt in range(1, 6):
            req = urllib.request.Request(url, data=data, headers=headers, method=method)
            try:
                with urllib.request.urlopen(req) as res:
                    body = res.read().decode("utf-8")
                    return json.loads(body) if body else {}
            except urllib.error.HTTPError as exc:
                details = exc.read().decode("utf-8", errors="replace")
                if exc.code in RETRYABLE_HTTP_STATUS and attempt < 5:
                    wait_seconds = attempt * 2
                    print(f"warning: HTTP {exc.code} from GitHub; retrying in {wait_seconds}s")
                    time.sleep(wait_seconds)
                    continue
                raise GitHubRequestError(method, url, exc.code, details) from exc
            except urllib.error.URLError as exc:
                if attempt < 5:
                    wait_seconds = attempt * 2
                    print(f"warning: GitHub request failed; retrying in {wait_seconds}s: {exc.reason}")
                    time.sleep(wait_seconds)
                    continue
                raise

    def list_issue_comments(self, repo: str, number: int):
        return self.paginated(f"{API_BASE}/repos/{repo}/issues/{number}/comments")

    def create_issue_comment(self, repo: str, number: int, body: str):
        return self.request_json("POST", f"{API_BASE}/repos/{repo}/issues/{number}/comments", {"body": body})

    def update_issue_comment(self, repo: str, comment_id: int, body: str):
        return self.request_json("PATCH", f"{API_BASE}/repos/{repo}/issues/comments/{comment_id}", {"body": body})

    def delete_issue_comment(self, repo: str, comment_id: int):
        return self.request_json("DELETE", f"{API_BASE}/repos/{repo}/issues/comments/{comment_id}")

    def get_issue(self, repo: str, number: int) -> dict[str, Any]:
        return self.request_json("GET", f"{API_BASE}/repos/{repo}/issues/{number}")

    def add_issue_labels(self, repo: str, number: int, labels: list[str]):
        return self.request_json("POST", f"{API_BASE}/repos/{repo}/issues/{number}/labels", {"labels": labels})

    def add_issue_assignees(self, repo: str, number: int, assignees: list[str]):
        return self.request_json("POST", f"{API_BASE}/repos/{repo}/issues/{number}/assignees", {"assignees": assignees})

    def update_issue_milestone(self, repo: str, number: int, milestone_number: int):
        return self.request_json("PATCH", f"{API_BASE}/repos/{repo}/issues/{number}", {"milestone": milestone_number})

    def get_git_ref(self, repo: str, ref: str):
        encoded_ref = urllib.parse.quote(ref, safe="/")
        return self.request_json("GET", f"{API_BASE}/repos/{repo}/git/ref/{encoded_ref}")

    def create_git_ref(self, repo: str, ref: str, sha: str):
        return self.request_json("POST", f"{API_BASE}/repos/{repo}/git/refs", {"ref": ref, "sha": sha})

    def list_pull_request_files(self, repo: str, pr_number: int):
        return self.paginated(f"{API_BASE}/repos/{repo}/pulls/{pr_number}/files")

    def get_release_by_tag(self, repo: str, tag: str):
        encoded_tag = urllib.parse.quote(tag, safe="")
        return self.request_json("GET", f"{API_BASE}/repos/{repo}/releases/tags/{encoded_tag}")

    def list_releases(self, repo: str) -> list[dict[str, Any]]:
        return self.paginated(f"{API_BASE}/repos/{repo}/releases")

    def create_release(self, repo: str, version, sha: str, body: str):
        payload = {
            "tag_name": version.canonical,
            "target_commitish": sha,
            "name": version.canonical,
            "body": body,
            "prerelease": version.prerelease,
        }
        return self.request_json("POST", f"{API_BASE}/repos/{repo}/releases", payload)

    def update_release(self, repo: str, release_id: int, version, sha: str, body: str):
        payload = {
            "tag_name": version.canonical,
            "target_commitish": sha,
            "name": version.canonical,
            "body": body,
            "prerelease": version.prerelease,
        }
        return self.request_json("PATCH", f"{API_BASE}/repos/{repo}/releases/{release_id}", payload)

    def list_release_assets(self, repo: str, release_id: int):
        return self.paginated(f"{API_BASE}/repos/{repo}/releases/{release_id}/assets")

    def delete_release_asset(self, repo: str, asset_id: int):
        return self.request_json("DELETE", f"{API_BASE}/repos/{repo}/releases/assets/{asset_id}")

    def upload_release_asset(self, repo: str, upload_url: str, asset_path: str, name: str):
        base_url = upload_url.split("{", 1)[0]
        separator = "&" if "?" in base_url else "?"
        url = f"{base_url}{separator}{urllib.parse.urlencode({'name': name})}"
        data = Path(asset_path).read_bytes()
        headers = self._headers(content_type="application/octet-stream")
        return self.request_data_json("POST", url, data, headers)

    def paginated(self, url: str):
        items = []
        page = 1
        while True:
            sep = "&" if "?" in url else "?"
            batch = self.request_json("GET", f"{url}{sep}per_page=100&page={page}")
            items.extend(batch)
            if len(batch) < 100:
                return items
            page += 1

    def graphql(self, query: str, variables: dict | None = None):
        data = self.request_json("POST", GRAPHQL_URL, {"query": query, "variables": variables or {}})
        if data.get("errors"):
            raise RuntimeError(f"GraphQL error: {json.dumps(data['errors'], ensure_ascii=False)}")
        return data["data"]


def require_client() -> GitHubClient:
    token = get_token()
    if not token:
        raise SystemExit("Missing GITHUB_TOKEN or GH_TOKEN")
    return GitHubClient(token)
