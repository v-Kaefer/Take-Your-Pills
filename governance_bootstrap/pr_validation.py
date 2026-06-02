from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass

from .github import GitHubClient

VALIDATION_MARKER = "<!-- governance-pr-validation -->"
BRANCH_PATTERN = re.compile(
    r"^(feat|fix|docs|refactor|test|hotfix|phase|task)\/[a-z0-9._/-]+$"
)
HOTFIX_PATTERN = re.compile(r"^hotfix\/[a-z0-9._/-]+$")

REQUIRED_SECTIONS = [
    ("linked issue", "Linked Issue"),
    ("milestone", "Milestone"),
    ("summary", "Summary"),
    ("teste", "Teste"),
    ("known risks", "Known risks"),
    ("dod checklist", "DoD checklist"),
]

PLACEHOLDER_PATTERNS = [
    re.compile(r"^\s*[-*_]\s*$"),
    re.compile(
        r"\b(todo|tbd|placeholder|example|describe|replace me|fill in)\b", re.IGNORECASE
    ),
    re.compile(r"<[^>]+>"),
]

TEST_CHECKBOX_PATTERN = re.compile(r"^\s*-\s*\[(?P<mark>[ xX])\]\s*(?P<label>.+?)\s*$")
TEST_OPTION_LABELS = {
    "Sim, há teste implementado.",
    "Não, não há teste implementado.",
}


@dataclass(frozen=True)
class ValidationFinding:
    section: str
    problem: str
    fix: str


def normalize_header(header: str) -> str:
    normalized = unicodedata.normalize("NFKD", header)
    normalized = "".join(char for char in normalized if not unicodedata.combining(char))
    return " ".join(normalized.strip().lower().split())


def sections_from_body(body: str) -> dict[str, list[str]]:
    sections: dict[str, list[str]] = {}
    current = None
    for line in body.splitlines():
        match = re.match(r"^##\s+(.+?)\s*$", line)
        if match:
            current = normalize_header(match.group(1))
            sections.setdefault(current, [])
            continue
        if current:
            sections[current].append(line)
    return sections


def line_is_placeholder(line: str) -> bool:
    stripped = line.strip()
    if not stripped:
        return True
    return any(pattern.search(stripped) for pattern in PLACEHOLDER_PATTERNS)


def meaningful_lines(lines: list[str]) -> list[str]:
    values = []
    for line in lines:
        if line_is_placeholder(line):
            continue
        values.append(line.strip())
    return values


def is_hotfix_branch(branch: str | None) -> bool:
    return bool(branch and HOTFIX_PATTERN.fullmatch(branch.strip()))


def validate_test_section(lines: list[str]) -> list[ValidationFinding]:
    seen_options: set[str] = set()
    selected_options: set[str] = set()
    extra_lines: list[str] = []

    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue

        match = TEST_CHECKBOX_PATTERN.match(line)
        if not match:
            extra_lines.append(stripped)
            continue

        label = normalize_header(match.group("label"))
        if label not in TEST_OPTION_LABELS:
            extra_lines.append(stripped)
            continue

        seen_options.add(label)
        if match.group("mark").strip().lower() == "x":
            selected_options.add(label)

    if extra_lines:
        return [
            ValidationFinding(
                section="Teste",
                problem="A seção deve conter apenas as duas opções de checkbox.",
                fix="Use somente `- [ ] Sim, há teste implementado` ou `- [ ] Não, não há teste implementado` em `## Teste`.",
            )
        ]

    if seen_options != TEST_OPTION_LABELS:
        return [
            ValidationFinding(
                section="Teste",
                problem="A seção não contém as duas opções de teste esperadas.",
                fix="Inclua exatamente as duas linhas `- [ ] Sim, há teste implementado` e `- [ ] Não, não ha teste implementado`.",
            )
        ]

    if len(selected_options) != 1:
        return [
            ValidationFinding(
                section="Teste",
                problem="Selecione exatamente uma opção.",
                fix="Marque apenas uma das opções em `## Teste`.",
            )
        ]

    return []


def validate_branch_name(
    branch: str | None, base_ref: str | None = None
) -> list[ValidationFinding]:
    if not branch or not branch.strip():
        return [
            ValidationFinding(
                section="Branch name",
                problem="Nome da branch ausente.",
                fix="Use um prefixo aprovado como `feat/...`, `fix/...`, `docs/...`, `refactor/...`, `test/...`, `hotfix/...`, `phase/...` ou `task/...`.",
            )
        ]

    branch = branch.strip()
    if branch == "develop" and (base_ref or "").strip() == "main":
        return []

    if BRANCH_PATTERN.fullmatch(branch):
        return []

    return [
        ValidationFinding(
            section="Branch name",
            problem=f"Nome da branch inválido `{branch}`.",
            fix="Renomeie para o padrão do repositório, por exemplo: `feat/repo-governance-bootstrap` ou `task/phase-1/player-base`.",
        )
    ]


def validate_pr_body(body: str | None) -> list[ValidationFinding]:
    body = body or ""
    if not body.strip():
        return [
            ValidationFinding(
                section="PR body",
                problem="O corpo do PR esta vazio.",
                fix="Comece em `.github/pull_request_template.md` e preencha as seções obrigatórias: Linked Issue, Milestone, Summary, Teste, Known risks e DoD checklist.",
            )
        ]

    sections = sections_from_body(body)
    findings: list[ValidationFinding] = []

    for key, label in REQUIRED_SECTIONS:
        lines = sections.get(key)
        if lines is None:
            findings.append(
                ValidationFinding(
                    section=label,
                    problem="Seção ausente.",
                    fix=f"Adicione uma seção `## {label}` e preencha-a com conteúdo concreto.",
                )
            )
            continue
        if key == "teste":
            continue
        if not meaningful_lines(lines):
            findings.append(
                ValidationFinding(
                    section=label,
                    problem="Seção vazia ou ainda com texto de placeholder.",
                    fix=f"Substitua o texto de placeholder em `## {label}` pelas informações reais deste PR.",
                )
            )

    linked_issue = "\n".join(sections.get("linked issue", []))
    if linked_issue and not re.search(
        r"\b(closes|fixes|resolves)\s+#\d+\b", linked_issue, re.IGNORECASE
    ):
        findings.append(
            ValidationFinding(
                section="Linked Issue",
                problem="A seção não contém uma referência de issue vinculada.",
                fix="Escreva `Closes #321`, `Fixes #321` ou `Resolves #321` dentro de `## Linked Issue`.",
            )
        )

    milestone = "\n".join(sections.get("milestone", []))
    if milestone and not re.search(r"\bMS[0-6]\b", milestone, re.IGNORECASE):
        findings.append(
            ValidationFinding(
                section="Milestone",
                problem="O milestone está ausente ou inválido.",
                fix="Use um milestone como `MS1`, `MS2` ou o milestone atribuido a esta entrega.",
            )
        )

    test_lines = sections.get("teste", [])
    if test_lines:
        findings.extend(validate_test_section(test_lines))

    return findings


def validate_pull_request(
    branch: str | None, body: str | None, base_ref: str | None = None
) -> list[ValidationFinding]:
    branch_findings = validate_branch_name(branch, base_ref=base_ref)
    if is_hotfix_branch(branch):
        return branch_findings
    return branch_findings + validate_pr_body(body)


def render_failure_comment(findings: list[ValidationFinding]) -> str:
    lines = [
        VALIDATION_MARKER,
        "## Validação do PR falhou",
        "",
        "O PR ainda não atende aos requisitos do repositório. Corrija os itens abaixo e envie um novo commit.",
        "",
    ]

    for finding in findings:
        lines.append(f"### {finding.section}")
        lines.append(f"- Problema: {finding.problem}")
        lines.append(f"- Correcao: {finding.fix}")
        lines.append("")

    lines.extend(
        [
            "## Estrutura obrigatória do PR",
            "",
            "```md",
            "## Linked Issue",
            "- Closes #321",
            "- Troque `#321` pela issue que esta PR resolve.",
            "",
            "## Milestone",
            "- MS1",
            "- Use o milestone correto da entrega.",
            "",
            "## Summary",
            "- Explique o que mudou.",
            "",
            "## Teste",
            "- [ ] Sim, há teste implementado",
            "- [ ] Nao, não ha teste implementado",
            "",
            "## Known risks",
            "- Liste limitações conhecidas ou escreva `None` se nao houver.",
            "- [ ] None",
            "",
            "## DoD checklist",
            "- [ ] Escopo implementado conforme definido",
            "- [ ] Opção de teste selecionada",
            "- [ ] Nenhuma quebra crítica conhecida foi introduzida",
            "```",
        ]
    )
    return "\n".join(lines)


def find_validation_comment(
    client: GitHubClient, repo: str, pr_number: int
) -> dict | None:
    for comment in client.list_issue_comments(repo, pr_number):
        if VALIDATION_MARKER in (comment.get("body") or ""):
            return comment
    return None


def upsert_validation_comment(
    client: GitHubClient, repo: str, pr_number: int, findings: list[ValidationFinding]
) -> str | None:
    existing = find_validation_comment(client, repo, pr_number)
    if not findings:
        if existing:
            client.delete_issue_comment(repo, existing["id"])
            return "deleted"
        return None

    body = render_failure_comment(findings)
    if existing:
        client.update_issue_comment(repo, existing["id"], body)
        return "updated"
    client.create_issue_comment(repo, pr_number, body)
    return "created"
