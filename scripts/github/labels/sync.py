#!/usr/bin/env python3
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from governance_bootstrap.cli import main


def parse_args():
    parser = argparse.ArgumentParser(description="Sync repository labels from a manifest")
    parser.add_argument("labels_file")
    parser.add_argument("--repo")
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    cli_args = ["labels", "sync", "--file", args.labels_file]
    if args.repo:
        cli_args += ["--repo", args.repo]
    if args.dry_run:
        cli_args += ["--dry-run"]
    raise SystemExit(main(cli_args))
