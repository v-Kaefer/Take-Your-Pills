# Take-Your-Pills
Take Your Pills - É um jogo infinity runner, side-scroller, ambientado em um Japão cyberpunk, durante a crise pós-guerra de 1945. Projeto elaborado para a matéria de Projeto de Desenvolvimento de Jogos da PUCRS

## Governança do repositório
- Artefatos de governança: `/docs`, `/config`, `/.github`, `/scripts`
- Runbook de bootstrap: `/docs/repo/governance-bootstrap-runbook.pt-BR.md`
- CLI reutilizável: `python -m governance_bootstrap`
- Guia de contribuição: `/CONTRIBUTING.md`

## Verificação local (full verify)
Use estes comandos antes de abrir/atualizar PR:

```bash
./scripts/validation/repo_quality.sh
python -m governance_bootstrap bootstrap --repo v-Kaefer/Take-Your-Pills --dry-run
```

> O primeiro comando valida baseline do repositório. O segundo valida o fluxo de bootstrap local (project + issues/tasks) sem alterar dados no GitHub.
