#!/usr/bin/env bash
set -euo pipefail

template=".github/pull_request_template.md"

[[ -f "$template" ]] || { echo "Missing required file: $template" >&2; exit 1; }

grep -Fq "## Linked Issue" "$template"
grep -Fq -- "- Closes #123" "$template"
grep -Fq -- "- Troque \`#123\` pela issue que esta PR resolve." "$template"
grep -Fq "## Milestone" "$template"
grep -Fq -- "- Use o milestone correto da entrega." "$template"
grep -Fq "## Summary" "$template"
grep -Fq -- "- Explique o que mudou e por que." "$template"
grep -Fq "## Teste" "$template"
grep -Fq -- "- [ ] Sim, ha teste implementado" "$template"
grep -Fq -- "- [ ] Nao, nao ha teste implementado" "$template"
! grep -Fq "## How to test" "$template"
! grep -Fq "## Evidence" "$template"
grep -Fq "## Known risks" "$template"
grep -Fq -- "- Liste quaisquer limitacoes conhecidas ou escreva \`None\` se nao houver." "$template"
grep -Fq "## DoD checklist" "$template"
grep -Fq -- "- [ ] Escopo implementado conforme definido" "$template"
grep -Fq -- "- [ ] Opcao de teste selecionada" "$template"
grep -Fq -- "- [ ] Nenhuma quebra critica conhecida foi introduzida" "$template"
grep -Fq "## Release version" "$template"
grep -Fq -- "- Para PRs \`develop -> main\`, use \`alpha-0.0.1\`, \`beta-0.1.0\` ou \`final-1.0.0\`." "$template"
grep -Fq -- "- Para qualquer outro PR, escreva \`N/A\`." "$template"
grep -Fq "## Related develop PRs" "$template"
grep -Fq -- "- Para PRs \`develop -> main\`, liste os numeros das PRs relacionadas como \`#123\`." "$template"
grep -Fq -- "- Para qualquer outro PR, escreva \`N/A\`." "$template"

echo "PR template contract OK"
