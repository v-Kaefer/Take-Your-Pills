# Repo Admin Checklist — `v-Kaefer/Take-Your-Pills`

## Ordem recomendada de aplicação
1. Criar labels.
2. Criar milestones.
3. Criar/confirmar branch `dev`.
4. Configurar proteção de branch (`main` e `dev`).
5. Criar board de acompanhamento.
6. Publicar regras operacionais (handoff + DoD).

---

## 1) Labels (taxonomia final)

Fonte modular: `docs/labels-patterns.md`

### Prioridade
- `priority:low`
- `priority:medium`
- `priority:high`

### Tipo
- `type:feature`
- `type:bug`
- `type:chore`
- `type:docs`
- `type:test`
- `type:polish`

### Área
- `area:player`
- `area:runner`
- `area:collectables`
- `area:speed-system`
- `area:scenario`
- `area:ui`
- `area:audio`
- `area:build`
- `area:qa`
- `area:repo`

### Estado
- `status:blocked`
- `status:needs-review`
- `status:ready-for-qa`

---

## 2) Milestones (fases)
- Criar os milestones **exatamente** conforme definidos em `take_your_pills_issues_detalhados.md`.
- Usar o documento canônico como fonte de verdade para:
  - nome da fase;
  - faixa de datas;
  - ordem/estrutura das fases.
- **Não** recriar nesta checklist uma lista paralela de fases/datas, para evitar inconsistências ao criar milestones no GitHub.

---

## 3) Política de branches e proteção

### `main`
- [ ] Bloquear push direto.
- [ ] Exigir PR para merge.
- [ ] Exigir pelo menos 1 review aprovada.
- [ ] Bloquear merge com checks obrigatórios falhando.
- [ ] Exigir branch atualizada antes do merge (se disponível).

### `dev`
- [ ] Exigir PR para merge.
- [ ] Bloquear merge direto sem revisão (se disponível).
- [ ] Exigir checks básicos quando existirem.

### Checks sugeridos para tornar obrigatórios (quando existirem)
- `smoke/godot-import`
- `tests/gdunit4`
- `checks/no-merge-conflict-markers`
- `checks/no-forbidden-files`

---

## 4) Branch `dev`
- [ ] Criar `dev` a partir de `main` (se ainda não existir).
- [ ] Definir `dev` como branch de integração do time.

---

## 5) Project board (tracking)

### Colunas
1. Backlog
2. Ready
3. In Progress
4. Review
5. QA
6. Done

### Regras mínimas do board
- Toda issue entra em **Backlog** com labels + milestone.
- Só entra em **Ready** com dependências resolvidas.
- **In Progress** exige assignee principal.
- **Review** exige PR vinculada.
- **QA** exige checklist manual mínimo.
- **Done** exige critérios de aceite completos.

---

## 6) Checklist operacional (handoff e Definition of Done)

### Handoff obrigatório (quando task troca de dono)
- [ ] O que funciona.
- [ ] O que falta.
- [ ] Problemas conhecidos.
- [ ] Próximo passo sugerido.

### Definition of Done
- [ ] Funciona no jogo.
- [ ] Integrado em `dev`.
- [ ] Validado manualmente.
- [ ] Não quebra o fluxo principal.
- [ ] Revisado por outra pessoa.
