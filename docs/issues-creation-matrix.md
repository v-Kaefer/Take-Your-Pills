# Issues Creation Matrix (batch-ready)

> Campos padrão por issue ao criar no GitHub: **Title, Objective, Acceptance Criteria, Dependencies, Labels, Milestone, Assignee (principal), Shadow Assignee**.

## Estratégia de labels
- Base: `priority:*`, `type:*`, `area:*`
- Durante execução: adicionar `status:*` conforme fluxo.

## Matriz

| ID | Título | Tipo | Prioridade | Área | Milestone sugerida | Dependências | Labels sugeridas | Principal | Sombra |
|---|---|---|---|---|---|---|---|---|---|
| 01.01 | Congelar escopo do projeto | docs | high | repo | Fase A | nenhuma | `type:docs`, `priority:high`, `area:repo` | TBD | TBD |
| 01.02 | Definir regras oficiais de pontuação | docs | high | runner/speed-system | Fase A | 01.01 | `type:docs`, `priority:high`, `area:runner`, `area:speed-system` | TBD | TBD |
| 01.03 | Definir os 4 coletáveis iniciais | docs | high | collectables | Fase A | 01.01 | `type:docs`, `priority:high`, `area:collectables` | TBD | TBD |
| 01.04 | Definir convenções de repositório | docs | medium | repo | Fase A | nenhuma | `type:docs`, `priority:medium`, `area:repo` | TBD | TBD |
| 02.01 | Estruturar projeto Godot | chore | high | repo/build | Fase A | 01.01 | `type:chore`, `priority:high`, `area:repo`, `area:build` | TBD | TBD |
| 02.02 | Configurar scripts de verificação antes do push | chore | high | repo/test | Fase A | 01.04, 02.01 | `type:chore`, `priority:high`, `area:repo` | TBD | TBD |
| 01.05 | Integrar pipeline de review automático (CODEOWNERS + vínculo PR/issue + roteamento) | chore | high | repo/qa/build | Fase A | 01.04, 02.02 | `type:chore`, `priority:high`, `area:repo`, `area:qa`, `area:build` | TBD | TBD |
| 03.01 | Implementar corrida automática | feature | high | player | Fase A | 02.01 | `type:feature`, `priority:high`, `area:player` | TBD | TBD |
| 03.02 | Implementar pulo | feature | high | player | Fase A | 03.01 | `type:feature`, `priority:high`, `area:player` | TBD | TBD |
| 03.03 | Implementar colisão e derrota | feature | high | player/speed-system | Fase A | 03.01, 03.02 | `type:feature`, `priority:high`, `area:player`, `area:speed-system` | TBD | TBD |
| 03.04 | Implementar reinício rápido | feature | high | ui/runner | Fase A | 03.03 | `type:feature`, `priority:high`, `area:ui`, `area:runner` | TBD | TBD |
| 04.01 | Implementar score e distância | feature | high | runner/ui | Fase A | 03.01 | `type:feature`, `priority:high`, `area:runner`, `area:ui` | TBD | TBD |
| 04.02 | Implementar sistema genérico de coletáveis | feature | high | collectables | Fase B | 01.03, 02.01 | `type:feature`, `priority:high`, `area:collectables` | TBD | TBD |
| 04.03 | Implementar máquina de estados de velocidade | feature | high | speed-system | Fase B | 04.02 | `type:feature`, `priority:high`, `area:speed-system` | TBD | TBD |
| 04.04 | Implementar multiplicadores de score | feature | high | runner/speed-system | Fase B | 01.02, 04.01, 04.03 | `type:feature`, `priority:high`, `area:runner`, `area:speed-system` | TBD | TBD |
| 04.05 | Implementar feedback de estado de velocidade | feature | high | speed-system/ui/audio | Fase B | 04.03 | `type:feature`, `priority:high`, `area:speed-system`, `area:ui`, `area:audio` | TBD | TBD |
| 05.01 | Implementar laboratório | feature | high | scenario | Fase B | 03.01, 03.02, 04.01, 04.02 | `type:feature`, `priority:high`, `area:scenario` | TBD | TBD |
| 05.02 | Implementar ruas | feature | high | scenario | Fase B | 05.01 | `type:feature`, `priority:high`, `area:scenario` | TBD | TBD |
| 05.03 | Implementar transição laboratório → ruas | feature | high | scenario/runner | Fase B | 05.01, 05.02 | `type:feature`, `priority:high`, `area:scenario`, `area:runner` | TBD | TBD |
| 06.01 | Implementar HUD | feature | high | ui | Fase B | 04.01, 04.03 | `type:feature`, `priority:high`, `area:ui` | TBD | TBD |
| 05.04 | Implementar casa temporária | feature | high | scenario | Fase C | 05.02 | `type:feature`, `priority:high`, `area:scenario` | TBD | TBD |
| 05.05 | Implementar entrada e saída da casa | feature | high | scenario/runner | Fase C | 05.04, 04.03 | `type:feature`, `priority:high`, `area:scenario`, `area:runner` | TBD | TBD |
| 06.02 | Implementar menu inicial, pausa e game over | feature | high | ui | Fase C | 03.04, 06.01 | `type:feature`, `priority:high`, `area:ui` | TBD | TBD |
| 06.03 | Implementar ranking local | feature | high | ui/runner | Fase C | 04.01, 06.02 | `type:feature`, `priority:high`, `area:ui`, `area:runner` | TBD | TBD |
| 07.01 | Definir suíte de testes automatizados | test | medium | qa | Fase C | 02.02 | `type:test`, `priority:medium`, `area:qa` | TBD | TBD |
| 07.02 | Implementar testes automatizados críticos | test | medium | qa | Fase D | 07.01, 04.03, 04.04, 05.05, 06.03 | `type:test`, `priority:medium`, `area:qa` | TBD | TBD |
| 07.03 | Montar checklist de testes manuais | test | high | qa | Fase D | 03.04, 04.04, 05.05, 06.03 | `type:test`, `priority:high`, `area:qa` | TBD | TBD |
| 08.01 | Integrar áudio funcional | polish | medium | audio | Fase E | 04.05, 06.02 | `type:polish`, `priority:medium`, `area:audio` | TBD | TBD |
| 08.02 | Integrar VFX leves e melhoria de legibilidade | polish | medium | ui | Fase E | 04.05, 06.01 | `type:polish`, `priority:medium`, `area:ui` | TBD | TBD |
| 08.03 | Balancear dificuldade e ritmo | polish | high | qa/runner/scenario | Fase F | 07.03, 08.02 | `type:polish`, `priority:high`, `area:qa`, `area:runner`, `area:scenario` | TBD | TBD |
| 08.04 | Fechar build final e material de apresentação | chore | high | build/qa/docs | Fase F | todas críticas anteriores | `type:chore`, `priority:high`, `area:build`, `area:qa` | TBD | TBD |

## Observações operacionais
- Evitar múltiplas labels `type:*` por issue.
- Em issues de múltiplas áreas, manter no máximo 2–3 labels `area:*`.
- Sempre preencher responsável principal e sombra antes de mover para **Ready**.
