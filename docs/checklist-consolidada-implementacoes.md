# Checklist consolidada — preparação do repositório (sem implementação)

Base de alinhamento:
- `análise_geral_preparacao_repositorio.md`
- `plano_implementacao_preparacao_repositorio.md`

Escopo desta checklist:
- somente padrões, regras, issues e configuração do repositório
- nenhum item de feature de jogo

---

## Onda 0 — Normalização documental (pré-requisito)
- [ ] Confirmar identificador canônico `01.05` para frente CODEOWNERS/pipeline em todos os documentos.
- [ ] Atualizar referências antigas (`02.03`) para `01.05` quando representarem o mesmo tema.
- [ ] Validar links cruzados entre documentos de planejamento e checklist.
- [ ] Confirmar ausência de itens de gameplay neste checklist.

## Onda 1 — Governança e convenções (issues 01.04 e 01.05)
- [ ] Fechar política de branches (`main` estável, `dev` integração, branches de trabalho).
- [ ] Fechar padrão de nome de branch para tarefas administrativas do repositório.
- [ ] Fechar padrão de commit (mensagens claras e rastreáveis à issue).
- [ ] Fechar padrão de PR (vínculo obrigatório com issue, escopo e critérios de aceite).
- [ ] Definir política de handoff entre responsáveis.
- [ ] Planejar `CODEOWNERS` inicial por áreas de responsabilidade.

## Onda 2 — Organização administrativa do repositório
- [ ] Consolidar taxonomia de labels (`priority:*`, `type:*`, `area:*`, `status:*`).
- [ ] Definir milestones por fase de preparação do repositório.
- [ ] Consolidar estrutura de board (Backlog → Ready → In Progress → Review → QA → Done).
- [ ] Definir regras de entrada/saída por coluna do board.
- [ ] Definir padrão para abertura e rastreio de issues administrativas/sub-issues.

## Onda 3 — Qualidade operacional (pre-push e checks)
- [ ] Formalizar plano de validações de `pre-push` (conflitos, arquivos proibidos, smoke, testes quando houver).
- [ ] Definir critérios objetivos de falha/sucesso por verificação.
- [ ] Definir política de ativação gradual dos checks obrigatórios.
- [ ] Definir estratégia de exceção temporária (quando um check ainda não puder ser obrigatório).

## Onda 4 — Pipeline de review (Fase A)
- [ ] Planejar padrão de metadados obrigatórios em issue templates e PR template.
- [ ] Planejar estrutura de roteamento de revisão por área.
- [ ] Planejar validação obrigatória de vínculo PR ↔ issue.
- [ ] Planejar roteamento automático de reviewers técnicos.
- [ ] Planejar roteamento automático de reviewers funcionais.
- [ ] Planejar fallback para owner funcional da issue pai quando faltarem dados.
- [ ] Confirmar princípios de segurança da automação (menor privilégio, separação validação/escrita, idempotência).

---

## Divisão por responsáveis administrativos (4 integrantes)

### Integrante 1 — Governança e metadados
- [ ] Concluir itens de convenções de branch/commit/PR.
- [ ] Concluir padronização de templates e metadados.
- [ ] Concluir normalização documental do identificador `01.05`.

### Integrante 2 — Taxonomia e fluxo administrativo
- [ ] Concluir labels, milestones e board.
- [ ] Concluir critérios de fluxo e transição de status.

### Integrante 3 — Qualidade operacional
- [ ] Concluir planejamento de `pre-push` e critérios de validação.
- [ ] Concluir política de ativação gradual de checks.

### Integrante 4 — Pipeline de review
- [ ] Concluir planejamento de `CODEOWNERS`.
- [ ] Concluir planejamento de PR↔issue.
- [ ] Concluir planejamento de roteamento automático de reviewers.

---

## Dependências críticas de execução
- [ ] Integrante 4 depende dos metadados definidos pelo Integrante 1.
- [ ] Roteamento da pipeline depende da taxonomia definida pelo Integrante 2.
- [ ] Gates da pipeline devem respeitar os critérios definidos pelo Integrante 3.

---

## Critérios de pronto desta checklist (sem implementar)
- [ ] Todos os itens permanecem como planejamento (sem execução técnica).
- [ ] Escopo está restrito a preparação do repositório.
- [ ] Ordem por ondas e dependências está coerente com o plano.
- [ ] Responsabilidades dos 4 integrantes estão claras e não sobrepostas.
