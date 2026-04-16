# Plano de execução para abertura e priorização de issues

## Objetivo
Abrir e organizar o backlog em lotes, minimizando bloqueios e retrabalho.

---

## Lote 0 — Preparação administrativa (antes das issues)
- Aplicar labels.
- Criar milestones A–F.
- Criar board com colunas padrão.
- Configurar proteção de `main` e `dev`.
- Garantir branch `dev`.

Saída esperada: ambiente pronto para triagem e execução.

---

## Lote 1 — Fundação (Fase A)
Abrir e priorizar:
- 01.01, 01.02, 01.03, 01.04
- 02.01, 02.02
- 03.01, 03.02, 03.03, 03.04
- 04.01

Regra de prioridade:
- Primeiro `priority:high` com dependência zero.
- Depois itens que destravam múltiplas issues seguintes.

---

## Lote 2 — MVP jogável (Fase B)
Abrir e priorizar:
- 04.02, 04.03, 04.04, 04.05
- 05.01, 05.02, 05.03
- 06.01

Meta:
- Loop jogável completo para checkpoint inicial de Parte 2.

---

## Lote 3 — MVP completo (Fase C)
Abrir e priorizar:
- 05.04, 05.05
- 06.02, 06.03
- 07.01

Meta:
- Fechar fluxo completo e ranking local do MVP.

---

## Lote 4 — Qualidade e playtesting (Fase D)
Abrir e priorizar:
- 07.02
- 07.03

Meta:
- Formalizar qualidade automatizada + checklist manual estável.

---

## Lote 5 — Refinamento e entrega (Fases E/F)
Abrir e priorizar:
- 08.01, 08.02
- 08.03, 08.04

Meta:
- Polimento, balanceamento e pacote final de entrega.

---

## Critérios operacionais de priorização contínua
- Resolver bloqueadores primeiro (`status:blocked`).
- Não iniciar issue sem dependências concluídas.
- Limitar WIP por pessoa (1 principal + 1 sombra ativa).
- Toda transição para **Review** exige PR vinculada.
- Toda transição para **Done** exige critérios de aceite completos.
