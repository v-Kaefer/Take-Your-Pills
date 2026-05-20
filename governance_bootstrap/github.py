from __future__ import annotations

import json
import mimetypes
import os
from pathlib import Path
import time
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

    def request_json(self, method: str, url: str, payload=None, accept: str = "application/vnd.github+json"):
        headers = {
            "Accept": accept,
            "Authorization": f"Bearer {self.token}",
            "X-GitHub-Api-Version": API_VERSION,
            "Content-Type": "application/json",
        }
        data = json.dumps(payload).encode("utf-8") if payload is not None else None
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

    def list_pull_request_files(self, repo: str, number: int):
        return self.paginated(f"{API_BASE}/repos/{repo}/pulls/{number}/files")

    def get_git_ref(self, repo: str, ref_path: str):
        return self.request_json("GET", f"{API_BASE}/repos/{repo}/git/ref/{ref_path}")

    def create_git_ref(self, repo: str, ref_name: str, sha: str):
        return self.request_json("POST", f"{API_BASE}/repos/{repo}/git/refs", {"ref": ref_name, "sha": sha})

    def update_git_ref(self, repo: str, ref_path: str, sha: str, force: bool = False):
        return self.request_json("PATCH", f"{API_BASE}/repos/{repo}/git/refs/{ref_path}", {"sha": sha, "force": force})

    def get_release_by_tag(self, repo: str, tag: str):
        return self.request_json("GET", f"{API_BASE}/repos/{repo}/releases/tags/{tag}")

    def create_release(self, repo: str, version, sha: str, body: str):
        payload = {
            "tag_name": version.canonical,
            "target_commitish": sha,
            "name": version.canonical,
            "body": body,
            "draft": False,
            "prerelease": version.prerelease,
            "generate_release_notes": False,
        }
        return self.request_json("POST", f"{API_BASE}/repos/{repo}/releases", payload)

    def update_release(self, repo: str, release_id: int, version, sha: str, body: str):
        payload = {
            "tag_name": version.canonical,
            "target_commitish": sha,
            "name": version.canonical,
            "body": body,
            "draft": False,
            "prerelease": version.prerelease,
            "generate_release_notes": False,
        }
        return self.request_json("PATCH", f"{API_BASE}/repos/{repo}/releases/{release_id}", payload)

    def list_release_assets(self, repo: str, release_id: int):
        return self.paginated(f"{API_BASE}/repos/{repo}/releases/{release_id}/assets")

    def delete_release_asset(self, repo: str, asset_id: int):
        return self.request_json("DELETE", f"{API_BASE}/repos/{repo}/releases/assets/{asset_id}")

    def upload_release_asset(self, repo: str, upload_url: str, file_path: str, name: str):
        path = Path(file_path)
        content_type, _ = mimetypes.guess_type(path.name)
        if not content_type:
            content_type = "application/octet-stream"
        url = urllib.parse.urlparse(upload_url.split("{", 1)[0])
        query = urllib.parse.parse_qsl(url.query, keep_blank_values=True)
        query = [(key, value) for key, value in query if key not in {"name", "label"}]
        query.append(("name", name))
        base_url = urllib.parse.urlunparse(url._replace(query=urllib.parse.urlencode(query)))
        headers = {
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {self.token}",
            "X-GitHub-Api-Version": API_VERSION,
            "Content-Type": content_type,
        }
        data = path.read_bytes()
        for attempt in range(1, 6):
            req = urllib.request.Request(base_url, data=data, headers=headers, method="POST")
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
                raise GitHubRequestError("POST", base_url, exc.code, details) from exc
            except urllib.error.URLError as exc:
                if attempt < 5:
                    wait_seconds = attempt * 2
                    print(f"warning: GitHub request failed; retrying in {wait_seconds}s: {exc.reason}")
                    time.sleep(wait_seconds)
                    continue
                raise

    def create_issue_comment(self, repo: str, number: int, body: str):
        return self.request_json("POST", f"{API_BASE}/repos/{repo}/issues/{number}/comments", {"body": body})

    def update_issue_comment(self, repo: str, comment_id: int, body: str):
        return self.request_json("PATCH", f"{API_BASE}/repos/{repo}/issues/comments/{comment_id}", {"body": body})

    def delete_issue_comment(self, repo: str, comment_id: int):
        return self.request_json("DELETE", f"{API_BASE}/repos/{repo}/issues/comments/{comment_id}")

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
