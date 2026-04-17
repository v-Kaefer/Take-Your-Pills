# Plano de implementação — preparação do repositório

Base: `análise_geral_preparacao_repositorio.md`  
Escopo: **apenas** padrões, regras, issues e configuração de repositório.  
Não inclui implementação de funcionalidades do jogo.

---

## 1) Objetivo
Planejar a implementação da preparação do repositório com ordem executável, dependências, responsáveis (4 integrantes) e critérios de pronto por etapa.

---

## 2) Escopo e regra canônica

### Incluído
- governança (`main`/`dev`, convenções de branch/commit/PR, handoff)
- taxonomia administrativa (labels, milestones, board)
- preparação de qualidade operacional (planejamento de pre-push e checks)
- pipeline de review da Fase A (`CODEOWNERS`, PR↔issue, roteamento de reviewers)
- criação/normalização de issues administrativas

### Excluído
- qualquer feature do jogo (player, cenário, score, UI de gameplay, etc.)

### Identificador canônico
- Para a frente de `CODEOWNERS` + pipeline/review, adotar **`01.05`** como referência única em todos os documentos.

---

## 3) Estrutura de execução por ondas

## Onda 0 — Normalização documental (pré-requisito)
- [x] Unificar referências (`01.05` no lugar de `02.03` quando aplicável).
- [x] Consolidar links cruzados entre os docs de planejamento.
- [x] Confirmar que todos os itens tratam apenas de preparação de repositório.

**Saída esperada:** base documental consistente para execução sem ambiguidade.

## Onda 1 — Governança e convenções (Issue 01.04 + 01.05)
- [x] Fechar padrão de branch (`main`, `dev`, branches de trabalho).
- [x] Fechar padrão de commit e PR template.
- [x] Fechar regra de handoff e responsabilidade principal/sombra.
- [x] Definir `CODEOWNERS` inicial por área (referência `01.05`).

**Dependência:** Onda 0.

## Onda 2 — Organização administrativa do repositório
- [x] Padronizar labels (`priority:*`, `type:*`, `area:*`, `status:*`).
- [x] Definir milestones de execução por fase.
- [x] Estruturar board (Backlog → Ready → In Progress → Review → QA → Done).
- [x] Definir critérios de transição entre colunas.

**Dependência:** Onda 1.

## Onda 3 — Qualidade operacional (planejamento de validação de push)
- [x] Formalizar plano do `pre-push` (conflitos, arquivos indevidos, smoke, testes).
- [x] Definir critérios de falha/sucesso por verificação.
- [x] Definir política de ativação gradual dos checks.

**Dependência:** Onda 1.

## Onda 4 — Pipeline de review da Fase A
- [x] Padronizar metadados em `.github/` (issue templates, PR template, routing, labels).
- [x] Planejar validação obrigatória PR ↔ issue.
- [x] Planejar solicitação automática de reviewers (técnico + funcional).
- [x] Planejar fallback por parent issue.
- [x] Confirmar requisitos de segurança (menor privilégio, separação validação/escrita, idempotência).

**Dependência:** Ondas 1 e 2 (e insumos da Onda 3 para gates).

---

## 4) Divisão de trabalho (4 integrantes, nomes a definir)

### Integrante 1 — Governança e metadados
- convenções de branch/commit/PR
- templates de issue/PR
- normalização documental (`01.05` canônico)

### Integrante 2 — Taxonomia administrativa
- labels, milestones, board e regras de fluxo

### Integrante 3 — Qualidade operacional
- planejamento de pre-push e critérios de validação/checks

### Integrante 4 — Pipeline de review
- plano de `CODEOWNERS`
- plano de validação PR↔issue
- plano de roteamento automático de reviewers

---

## 5) Dependências críticas
- Integrante 4 depende de metadados definidos pelo Integrante 1.
- Integração final da pipeline depende da taxonomia (Integrante 2).
- Gates de validação em PR devem considerar política operacional (Integrante 3).

---

## 6) Critérios de pronto do planejamento (implementação concluída)
- [x] Plano cobre somente requisitos de repositório.
- [x] Ordem de execução e dependências estão explícitas.
- [x] Responsabilidades dos 4 integrantes estão separadas.
- [x] Referência canônica `01.05` está consistente.
- [x] Não há tarefa de implementação de feature de jogo neste plano.

---

## 7) Estado após implementação desta rodada
Issues administrativas, templates e workflows foram implementados no repositório e estão prontos para uso incremental, mantendo rastreabilidade e sem misturar com backlog de features do jogo.
