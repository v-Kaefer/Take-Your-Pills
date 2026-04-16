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
- `Fase A — Fundação técnica (16/04–29/04)`
- `Fase B — MVP jogável para Parte 2 (30/04–13/05)`
- `Fase C — MVP completo para Parte 2 (14/05–03/06)`
- `Fase D — Playtesting e revisão estrutural (08/06–17/06)`
- `Fase E — Refinamento para Parte 3 (18/06–22/06)`
- `Fase F — Entrega final da Parte 3 (23/06–08/07)`

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
