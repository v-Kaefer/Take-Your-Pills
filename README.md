# Take-Your-Pills
Take Your Pills - É um jogo infinity runner, side-scroller, ambientado em um Japão cyberpunk, durante a crise pós-guerra de 1945. Projeto elaborado para a matéria de Projeto de Desenvolvimento de Jogos da PUCRS

## Governança do repositório
- Artefatos de governança: `/docs`, `/config`, `/.github`, `/scripts`
- Conteúdo em `/scripts`: utilitários locais e manuais; não faz parte da validação automatizada do repositório.
- Runbook de bootstrap: `/docs/repo/governance-bootstrap-runbook.pt-BR.md`
- CLI reutilizável: `python -m governance_bootstrap`
- Make targets: `make help`
- Guia de contribuição: `/CONTRIBUTING.md`

## Make shortcuts
Use os atalhos abaixo para a rotina de governança:

```bash
make labels_sync
make milestones_sync
make project_create
make issues_generate

make issue_create REPO=v-Kaefer/Take-Your-Pills TITLE="New issue" BODY_FILE=/tmp/body.md LABELS="status:backlog type:task"
make issue_update REPO=v-Kaefer/Take-Your-Pills ISSUE_NUMBER=123 TITLE="Updated title" ADD_LABELS="priority:high"
make issue_delete REPO=v-Kaefer/Take-Your-Pills ISSUE_NUMBER=123
```

## Verificação local (full verify)
Use estes comandos antes de abrir/atualizar PR:

```bash
./scripts/validation/repo_quality.sh
python -m governance_bootstrap bootstrap --repo v-Kaefer/Take-Your-Pills --dry-run
```

> O primeiro comando valida baseline do repositório. O segundo valida o fluxo de bootstrap local (project + issues/tasks) sem alterar dados no GitHub.
