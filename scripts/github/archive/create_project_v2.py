#!/usr/bin/env python3
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from governance_bootstrap.cli import main


def parse_args():
    parser = argparse.ArgumentParser(description="Create GitHub Project v2 from project definition")
    parser.add_argument("definition")
    parser.add_argument("--repo")
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    cli_args = ["project", "create", "--file", args.definition]
    if args.repo:
        cli_args += ["--repo", args.repo]
    if args.dry_run:
        cli_args += ["--dry-run"]
    raise SystemExit(main(cli_args))
