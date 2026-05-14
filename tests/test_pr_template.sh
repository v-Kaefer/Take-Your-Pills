#!/usr/bin/env bash
set -euo pipefail

template=".github/pull_request_template.md"

if [[ ! -f "$template" ]]; then
  echo "Missing PR template: $template" >&2
  exit 1
fi

for pattern in \
  '## Summary / Resumo' \
  '## Related Issue / Issue relacionada' \
  '## Change Type / Tipo de mudança' \
  '## Validation / Validação' \
  '## AI Usage / Uso de IA' \
  '## Notes / Observações' \
  'Closes #'
do
  if ! grep -Fq "$pattern" "$template"; then
    echo "Missing expected template content: $pattern" >&2
    exit 1
  fi
done
