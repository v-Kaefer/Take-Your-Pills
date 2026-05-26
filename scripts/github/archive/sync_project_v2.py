#!/usr/bin/env python3
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from governance_bootstrap.cli import main


def parse_args():
    parser = argparse.ArgumentParser(description="Configure a GitHub Project v2 and add repo issues to it")
    parser.add_argument("project_definition")
    parser.add_argument("--repo")
    parser.add_argument("--owner")
    parser.add_argument("--project-number", type=int, required=True)
    parser.add_argument("--issue-state", default="open", choices=["open", "closed", "all"])
    parser.add_argument("--link-subissues", action="store_true")
    parser.add_argument("--only-link-subissues", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    cli_args = [
        "project",
        "sync",
        "--file",
        args.project_definition,
        "--project-number",
        str(args.project_number),
        "--issue-state",
        args.issue_state,
    ]
    if args.repo:
        cli_args += ["--repo", args.repo]
    if args.owner:
        cli_args += ["--owner", args.owner]
    if args.link_subissues:
        cli_args += ["--link-subissues"]
    if args.only_link_subissues:
        cli_args += ["--only-link-subissues"]
    if args.dry_run:
        cli_args += ["--dry-run"]
    raise SystemExit(main(cli_args))
