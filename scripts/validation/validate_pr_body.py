#!/usr/bin/env python3
import argparse
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from governance_bootstrap.github import require_client
from governance_bootstrap.pr_validation import upsert_validation_comment, validate_pull_request


def read_body(args):
    if args.file:
        with open(args.file, "r", encoding="utf-8") as f:
            return f.read()
    if os.environ.get("PR_BODY"):
        return os.environ["PR_BODY"]
    if not sys.stdin.isatty():
        return sys.stdin.read()
    return ""


def main():
    parser = argparse.ArgumentParser(description="Validar os metadados do corpo do PR")
    parser.add_argument("--file", help="Ler o corpo do PR a partir de um arquivo")
    parser.add_argument("--branch", help="Validar tambem o nome da branch do PR")
    parser.add_argument("--base-branch", help="Branch base para excecoes na validacao do nome da branch")
    parser.add_argument("--repo", help="Repositorio owner/name para atualizar comentarios fixos do PR")
    parser.add_argument("--pr-number", type=int, help="Numero do PR para comentarios fixos de validacao")
    parser.add_argument("--comment", action="store_true", help="Criar ou atualizar o comentario fixo de validacao do PR")
    args = parser.parse_args()

    findings = validate_pull_request(args.branch, read_body(args), base_ref=args.base_branch)
    if findings:
        for finding in findings:
            print(f"{finding.section}: {finding.problem}", file=sys.stderr)
            print(f"  Correcao: {finding.fix}", file=sys.stderr)
        if args.comment:
            if not args.repo or not args.pr_number:
                print("Faltam --repo ou --pr-number para comentarios fixos do PR", file=sys.stderr)
                return 1
            upsert_validation_comment(require_client(), args.repo, args.pr_number, findings)
        return 1

    if args.comment:
        if not args.repo or not args.pr_number:
            print("Faltam --repo ou --pr-number para comentarios fixos do PR", file=sys.stderr)
            return 1
        client = require_client()
        existing = upsert_validation_comment(client, args.repo, args.pr_number, findings)
        if existing:
            print(f"Comentario de validacao removido: {existing}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
