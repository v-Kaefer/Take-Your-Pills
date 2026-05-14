# Take Your Pills — Definições do Projeto (Planejamento Geral)

## 1. Objetivo deste documento

Este documento consolida as definições de escopo, produção, organização do time, fluxo técnico, política de branches, testes e validações de push do projeto **Take Your Pills**, para servir como referência operacional do grupo durante o desenvolvimento do trabalho.

Este documento **não implementa** nada no repositório. Ele define o padrão a ser seguido.

---

## 2. Contexto acadêmico e prazo real

### Situação atual
- **Entrega 1 já concluída:** Pitch / GDD / slides.
- **Parte 2:** desenvolvimento base do jogo em Godot e checkpoints intermediários.
- **Parte 3:** refinamento, playtesting, ajustes finais e entrega definitiva.

### Datas relevantes do cronograma
#### Parte 1
- **06/04/2026:** entrega e apresentação do trabalho — Parte 1 (Pitch)

#### Parte 2
- **13/05/2026:** checkpoint do trabalho — Parte 2
- **20/05/2026:** checkpoint do trabalho — Parte 2
- **01/06/2026:** entrega do trabalho — Parte 2
- **03/06/2026:** entrega do trabalho — Parte 2

#### Parte 3
- **22/06/2026:** checkpoint do trabalho — Parte 3
- **06/07/2026:** entrega do trabalho — Parte 3
- **08/07/2026:** entrega do trabalho — Parte 3

### Janela real de desenvolvimento do projeto
Considerando o cronograma completo, a janela principal de desenvolvimento do jogo vai de **08/04/2026 até 08/07/2026**.

### Interpretação adotada neste planejamento
- **Parte 2** é tratada como fase de construção do MVP jogável.
- **Parte 3** é tratada como fase de refinamento, estabilidade, playtesting e entrega final.
- Portanto, a **entrega final real** do projeto será considerada em **06/07/2026–08/07/2026**.

### Conteúdos da disciplina que impactam diretamente o projeto
- 08/04: criação de projeto, GDScript, temporização e entrada
- 13/04: tratamento de entrada e movimentação
- 15/04: sprites, animações, colisões, gravidade e saltos
- 22/04: câmera 2D e instanciação
- 27/04: transição entre cenas, HUD e AnimationPlayer
- 29/04: áudio e boas práticas de projeto
- 04/05: tilemaps e desenvolvimento da Parte 2
- 08/06: playtesting — teoria
- 10/06: playtesting — prática
- 29/06: playtesting — prática

---

## 3. Definição do MVP e da entrega final

### Escopo incluído no MVP
- runner infinito
- ranking local
- 4 coletáveis iniciais
- sistema de velocidade com aceleração e desaceleração
- 3 contextos de cenário:
  - laboratório
  - ruas
  - casa dos habitantes (temporária)
- visual 2D estilizado
- build jogável e apresentável

### Escopo excluído desta fase
- ranking online
- loja / upgrades
- narrativa formal expandida
- sistema de progresso persistente além do ranking local
- chefes, combate, inventário ou submodos complexos

### Objetivo da Parte 2
Fechar um **MVP totalmente jogável**, com loop central funcional, fluxo entre cenários, pontuação, ranking local e estrutura de build estável.

### Objetivo da Parte 3
Elevar o MVP para um estado de **entrega final**, com:
- melhor legibilidade visual
- melhor polimento audiovisual
- melhor estabilidade
- correção de bugs
- melhoria de UX
- refinamento via playtesting

---

## 4. Loop do jogo

### Loop macro
1. O jogador inicia no **laboratório**.
2. Corre, salta, coleta e evita obstáculos.
3. Ao atingir a condição de transição, vai para as **ruas**.
4. As **ruas** tornam-se o cenário base do loop principal.
5. Em condição específica, o jogador entra na **casa**.
6. A **casa** dura por tempo limitado.
7. Ao final do tempo ou da condição definida, o jogador retorna para as **ruas**.
8. O ciclo se repete até a derrota.

### Loop micro
1. correr
2. desviar
3. coletar
4. alterar estado de velocidade
5. sobreviver ao risco da velocidade extrema
6. acumular pontuação
7. morrer
8. registrar score local
9. reiniciar rapidamente

---

## 5. Sistema de pontuação

### Multiplicador por cenário
- **Laboratório:** `0.5x`
- **Ruas:** `1.0x`
- **Casa:** `2.0x`

### Multiplicador por estado de velocidade
- **Super Lento:** `0.5x`
- **Lento:** `0.75x`
- **Normal:** `1.0x`
- **Rápido:** `1.5x`
- **Super Rápido:** `2.0x`

### Fórmula adotada neste documento
```text
Pontos finais = Pontos base do coletável × Multiplicador do cenário × Multiplicador da velocidade
```

### Intenção de design
- laboratório: início mais seguro e menos lucrativo
- ruas: estado neutro e base do jogo
- casa: estado temporário de maior retorno
- velocidade rápida: maior risco e maior retorno
- velocidade lenta: punição implícita por baixo rendimento

---

## 6. Sistema de velocidade

### Estados
- **Lento**
- **Normal**
- **Rápido**

### Regras
- a cada 3 coletas do grupo de aceleração, o jogador sobe 1 estado
- a cada 3 coletas do grupo de desaceleração, o jogador desce 1 estado
- ultrapassar o limite superior causa derrota por queda / machucado
- ultrapassar o limite inferior causa derrota por sonolência / queda dormindo

### Regra de implementação
O sistema de velocidade deve ser tratado como **máquina de estados**, não como simples valor solto de velocidade.

### Feedback obrigatório
- indicador visual de estado no HUD
- feedback sonoro curto ao mudar de estado
- feedback visual sutil em transição
- aviso claro de estado extremo iminente

---

## 7. Coletáveis

Os 4 coletáveis iniciais deverão ser mantidos como sistema configurável.

### Estrutura recomendada
- **Coletável A:** pontuação comum
- **Coletável B:** pontuação especial / rara
- **Coletável C:** aceleração
- **Coletável D:** desaceleração

### Regra técnica
Os coletáveis devem ser definidos por dados configuráveis, com:
- identificador
- valor base
- tipo
- sprite
- efeito aplicado
- peso de spawn

---

## 8. Cenários

### 8.1 Laboratório
Função:
- introdução do jogo
- leitura inicial de mecânicas
- ganho reduzido de pontuação

Características:
- multiplicador de cenário 0.5x
- obstáculos mais previsíveis
- densidade de spawn moderada
- foco em onboarding implícito

### 8.2 Ruas
Função:
- cenário base principal
- maior permanência do jogador
- centro da rejogabilidade

Características:
- multiplicador de cenário 1.0x
- maior variedade visual e de obstáculos
- cenário de retorno após a casa

### 8.3 Casa
Função:
- evento temporário de alto risco e alta recompensa
- quebra controlada do ritmo
- espaço de maior multiplicação de score

Características:
- multiplicador de cenário 2.0x
- tempo limitado
- retorno automático às ruas
- não deve virar um modo separado nem um segundo jogo

---

## 9. Organização técnica em Godot

### Estrutura recomendada de cenas
- `Main`
- `Game`
- `Player`
- `HUD`
- `MainMenu`
- `GameOverMenu`
- `LocalRankingMenu`
- `ObstacleBase`
- `CollectableBase`
- `Spawner`
- `ScenarioController`
- `ScenarioTransitionTrigger`
- `HouseSessionController`

### Autoloads recomendados
- `GameSession`
- `SaveManager`
- `AudioManager`

### Configurações / dados
- `CollectableData`
- `ScenarioData`
- `SpeedStateConfig`
- `SpawnTable`

---

## 10. Organização do time

O projeto seguirá o modelo:
- **responsável principal**
- **responsável sombra**
- **integrador da semana**

### Áreas-base
#### Pessoa A — Core
- player
- pulo
- colisão
- morte
- game feel principal

#### Pessoa B — Systems
- score
- velocidade
- contadores
- regras de cenário
- spawn tables

#### Pessoa C — UI / fluxo
- HUD
- menus
- ranking local
- pausa
- reinício

#### Pessoa D — Integração / polish
- áudio
- efeitos
- integração de cenas
- build
- QA manual

### Regra de flexibilidade
Toda issue deve ter:
- 1 dono principal
- 1 dono sombra

Se o principal travar, atrasar ou abandonar a issue, o sombra assume com base no estado atual da branch.

### Regras operacionais
- ninguém fica mais de 2 dias úteis sem subir progresso da própria task
- toda branch em andamento deve estar publicada remotamente
- toda task parada deve ter handoff escrito
- todo fim de ciclo relevante exige push

---

## 11. Cronograma interno alinhado ao prazo real

## Fase A — Fundação técnica (16/04 a 29/04)
### Objetivo
Travamento do projeto, estrutura técnica e primeiro loop jogável.

### Entregas
- congelar escopo
- congelar regras de pontuação e velocidade
- estruturar projeto Godot
- implementar corrida, pulo, colisão, derrota e restart
- implementar HUD inicial
- implementar score e distância

## Fase B — MVP jogável para Parte 2 (30/04 a 13/05)
### Objetivo
Chegar ao checkpoint 1 com loop principal jogável.

### Entregas
- 4 coletáveis integrados
- sistema de velocidade funcional
- laboratório funcional
- ruas funcionais
- transição laboratório → ruas
- feedback básico de estado

### Meta do checkpoint 13/05
O jogo precisa estar jogável, entendível e demonstrável.

## Fase C — MVP completo para Parte 2 (14/05 a 03/06)
### Objetivo
Fechar a entrega da Parte 2 com o MVP completo.

### Entregas
- casa temporária funcional
- retorno casa → ruas funcional
- ranking local funcional
- menus básicos funcionais
- fluxo completo do jogo
- build estável da Parte 2

## Fase D — Playtesting e revisão estrutural (08/06 a 17/06)
### Objetivo
Usar o período de playtesting para levantar problemas reais e priorizar correções.

### Entregas
- checklist de testes manuais
- rodada de feedback do grupo
- priorização de bugs
- ajustes de ritmo, legibilidade e frustração

## Fase E — Refinamento para Parte 3 (18/06 a 22/06)
### Objetivo
Chegar ao checkpoint da Parte 3 com o jogo estável e melhor polido.

### Entregas
- correção dos bugs críticos
- melhoria de UX
- refinamento de UI e feedback
- melhoria do fluxo de pontuação e leitura de risco

## Fase F — Entrega final da Parte 3 (23/06 a 08/07)
### Objetivo
Produzir a versão final do trabalho.

### Entregas
- polimento final
- revisão audiovisual
- build final
- revisão do documento do projeto
- material final de apresentação / demonstração

---

## 12. Política de branches

### Branches principais
- `main` → sempre estável e jogável
- `dev` → integração do time

### Branches de trabalho
Saem de `dev`.

### Padrão de nome
- `feat/player-jump`
- `feat/speed-state-system`
- `feat/local-ranking`
- `fix/collision-box`
- `chore/project-structure`
- `docs/project-definitions`

### Regras
- sem commit direto em `main`
- `main` recebe apenas merge estável
- features entram primeiro em `dev`
- PR deve tratar um assunto de cada vez
- branch longa deve ser dividida ou integrada cedo

### Regra de handoff
Toda branch aberta deve informar:
- o que funciona
- o que falta
- problema conhecido
- próximo passo esperado

---

## 13. Prioridades e labels

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

## 14. Testes

## 14.1 Testes automatizados
Será considerado o uso de **GdUnit4** para testes automatizados de lógica.

### O que testar automaticamente
- transição entre estados de velocidade
- contagem de coletáveis
- cálculo de pontuação
- regras de multiplicador
- ordenação do ranking local
- persistência do ranking local
- entrada e saída da casa
- duração / timer da casa

## 14.2 Testes manuais obrigatórios
Checklist mínimo por build:
- corrida está suave?
- pulo responde corretamente?
- colisão parece justa?
- jogador entende por que morreu?
- HUD informa bem o estado de velocidade?
- score muda corretamente conforme cenário e velocidade?
- laboratório → ruas funciona?
- casa entra e sai corretamente?
- ranking local salva e carrega?
- reinício funciona sempre?

---

## 15. Validações de push e scripts planejados

Objetivo: impedir que alterações perigosas sejam enviadas sem verificação mínima.

### Estratégia
Será adotado um fluxo com hook de `pre-push`, apoiado por scripts dentro do repositório.

### Verificações planejadas no `pre-push`
1. detectar marcadores de conflito de merge (`<<<<<<<`, `=======`, `>>>>>>>`)
2. bloquear push de arquivos temporários ou indevidos
3. rodar validação rápida do projeto Godot
4. rodar suíte de testes, se existir
5. falhar o push se qualquer etapa crítica falhar

### Estrutura sugerida
- `.githooks/pre-push`
- `scripts/check_merge_conflicts.sh`
- `scripts/check_forbidden_files.sh`
- `scripts/run_godot_smoke.sh`
- `scripts/run_tests.sh`

### Hook sugerido (`.githooks/pre-push`)
```bash
#!/usr/bin/env bash
set -euo pipefail

bash scripts/check_merge_conflicts.sh
bash scripts/check_forbidden_files.sh
bash scripts/run_godot_smoke.sh
bash scripts/run_tests.sh

echo "pre-push: verificações concluídas com sucesso"
```

### Script sugerido: conflito de merge
```bash
#!/usr/bin/env bash
set -euo pipefail

if git grep -nE '^(<<<<<<<|=======|>>>>>>>)' -- . >/dev/null 2>&1; then
  echo "Erro: marcadores de conflito de merge encontrados."
  git grep -nE '^(<<<<<<<|=======|>>>>>>>)' -- . || true
  exit 1
fi
```

### Script sugerido: arquivos proibidos / temporários
```bash
#!/usr/bin/env bash
set -euo pipefail

changed_files=$(git diff --name-only --cached || true)

forbidden_pattern='(^|/)(\.godot/|build/|dist/|tmp/|\.DS_Store$)'

if echo "$changed_files" | grep -E "$forbidden_pattern" >/dev/null 2>&1; then
  echo "Erro: há arquivos temporários ou artefatos indevidos preparados para push."
  echo "$changed_files" | grep -E "$forbidden_pattern" || true
  exit 1
fi
```

### Script sugerido: smoke check do projeto Godot
```bash
#!/usr/bin/env bash
set -euo pipefail

: "${GODOT_BIN:?Defina a variável GODOT_BIN com o executável do Godot}"

"$GODOT_BIN" --headless --path . --import --quit
```

### Script sugerido: testes
```bash
#!/usr/bin/env bash
set -euo pipefail

if [ -d "tests" ] && [ -f "addons/gdUnit4/runtest.sh" ]; then
  chmod +x ./addons/gdUnit4/runtest.sh
  ./addons/gdUnit4/runtest.sh -a res://tests -c
else
  echo "Aviso: suíte automatizada ainda não configurada; seguindo sem GdUnit4."
fi
```

---

## 16. Convenções adicionais

### Commits
Padrão sugerido:
- `feat(player): add jump and auto-run`
- `feat(speed): implement speed state transitions`
- `fix(ui): correct game over restart`
- `chore(repo): organize scripts and hooks`

### PRs
Toda PR deve responder:
- o que foi feito
- como testar
- o que ainda falta
- riscos conhecidos
- screenshot / gif, quando aplicável

### Definition of Done
Uma issue só pode ser encerrada quando:
- funciona no jogo
- foi integrada em `dev`
- foi testada manualmente
- não quebra o fluxo principal
- possui revisão mínima de outra pessoa

---

## 17. Riscos principais do projeto

### Risco 1 — Escopo crescer demais
Mitigação:
- manter foco no escopo definido
- não adicionar sistemas de upgrade, online ou narrativa expandida

### Risco 2 — Branches longas e conflito de integração
Mitigação:
- branches curtas
- push frequente
- integração cedo em `dev`

### Risco 3 — Sistema de velocidade ficar confuso
Mitigação:
- HUD claro
- feedback audiovisual
- testes específicos de pontuação e estado

### Risco 4 — Casa virar um sub-jogo complexo
Mitigação:
- tratar casa como evento temporário
- reutilizar mecânicas do loop principal

### Risco 5 — Dependência excessiva de uma pessoa
Mitigação:
- responsável sombra
- handoff obrigatório
- branch sempre publicada

---

## 18. Diretriz final do projeto

Se houver dúvida entre adicionar uma feature nova ou melhorar a clareza do loop principal, a decisão padrão deve ser:

> priorizar controle, legibilidade, estabilidade e fluxo completo do MVP.

O projeto será considerado bem-sucedido se entregar:
- jogo jogável sem travas graves
- sistema de velocidade compreensível
- score coerente com cenário e velocidade
- fluxo laboratório → ruas → casa → ruas funcionando
- ranking local funcional
- polimento suficiente para apresentação final da Parte 3
