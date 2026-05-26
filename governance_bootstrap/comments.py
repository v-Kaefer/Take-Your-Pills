from __future__ import annotations

from .github import GitHubClient


def find_marked_comment(client: GitHubClient, repo: str, number: int, marker: str) -> dict | None:
    for comment in client.list_issue_comments(repo, number):
        if marker in (comment.get("body") or ""):
            return comment
    return None


def upsert_marked_comment(client: GitHubClient, repo: str, number: int, marker: str, body: str) -> str | None:
    existing = find_marked_comment(client, repo, number, marker)
    if not body.strip():
        if existing:
            client.delete_issue_comment(repo, existing["id"])
            return "deleted"
        return None

    if existing:
        client.update_issue_comment(repo, existing["id"], body)
        return "updated"

    client.create_issue_comment(repo, number, body)
    return "created"
