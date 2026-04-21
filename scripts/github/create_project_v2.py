#!/usr/bin/env python3
import argparse
import json
import os
import subprocess


def run(cmd):
    result = subprocess.run(cmd, text=True, capture_output=True)
    if result.returncode != 0:
        raise RuntimeError(result.stderr)
    return result.stdout.strip()


def owner_node(owner):
    out = run([
        "gh", "api", "graphql",
        "-f", "query=query($login:String!){user(login:$login){id}}",
        "-f", f"login={owner}",
        "--jq", ".data.user.id"
    ])
    return out


def create_project(owner_id, title):
    out = run([
        "gh", "api", "graphql",
        "-f", "query=mutation($owner:ID!,$title:String!){createProjectV2(input:{ownerId:$owner,title:$title}){projectV2{id url}}}",
        "-f", f"owner={owner_id}",
        "-f", f"title={title}"
    ])
    return out


def main():
    parser = argparse.ArgumentParser(description="Create GitHub Project v2 from project definition")
    parser.add_argument("definition", help="Path to project-definition.json")
    parser.add_argument("--repo", default=os.getenv("GITHUB_REPOSITORY"), help="owner/repo")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    with open(args.definition, "r", encoding="utf-8") as f:
        definition = json.load(f)

    if not args.repo:
        raise SystemExit("Missing --repo and GITHUB_REPOSITORY")
    owner = args.repo.split("/", 1)[0]

    if args.dry_run:
        print(f"[DRY-RUN] Would create project: {definition['name']}")
        print("[DRY-RUN] Fields to configure:")
        for field in definition.get("fields", []):
            print(f"- {field['name']} ({field['type']})")
        return 0

    oid = owner_node(owner)
    out = create_project(oid, definition["name"])
    print(out)
    print("Project created. Configure custom fields and views using config/project/project-definition.json.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
