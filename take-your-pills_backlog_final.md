# Take Your Pills — Backlog Operacional
## User Stories, Tasks/Issues, Sub-issues, trilha de Design/Assets, GitHub Project e Milestones

## 1. Base adotada para este backlog

### Escopo-base considerado
Este backlog foi montado com prioridade no **GDD de 1 página** como fonte atual de escopo do jogo, complementado pelo deck anterior quando ele não conflita com o GDD.

### Síntese do jogo considerada para o planejamento
- Runner / sidescroller 2D.
- Japão pós-guerra.
- Yakuza / fuga / droga experimental.
- Loop de correr, desviar, coletar, sofrer efeito adverso, acumular pontos, melhorar a run e repetir.
- Features prioritárias: corrida infinita, coleta e pontuação, efeito adverso ao acumular speed-ups, loja de upgrades e ranking. 

### Regra de planejamento adotada
Como o jogo **só precisa estar completo na primeira entrega da Parte 3**, este backlog foi organizado para:

- construir o jogo progressivamente durante a Parte 2 e a Parte 3;
- chegar com o **jogo completo até 06/07/2026**;
- tratar **08/07/2026** apenas como segundo dia de apresentação, sem novas modificações no jogo após a entrega de **06/07/2026**.

### Interpretação de escopo para caber no prazo
Para garantir completude até 06/07:
- **ranking local** entra como parte do escopo principal;
- **ranking online** entra como **stretch goal**, só se o núcleo estiver estável;
- loja de upgrades entra como **stretch goal**, em versão enxuta, funcional e suficiente para a proposta do jogo.

---

## 2. Datas e marcos da disciplina considerados

## Entregas e checkpoints relevantes
- **13/05/2026** — Checkpoint Parte 2
- **20/05/2026** — Checkpoint Parte 2
- **01/06/2026** — Entrega Parte 2
- **03/06/2026** — Entrega Parte 2
- **22/06/2026** — Checkpoint Parte 3
- **06/07/2026** — Entrega Parte 3 (buffer final)
- - **08/07/2026** — Segundo dia de apresentação da Parte 3 (sem novas modificações)

## Aulas com impacto técnico direto no backlog
- **08/04** — criação de projeto, GDScript, temporização, entrada
- **13/04** — tratamento de entrada e movimentação
- **15/04** — sprites, animações, colisões, gravidade e saltos
- **22/04** — câmera 2D e instanciação
- **27/04** — transição entre cenas, HUD e AnimationPlayer
- **29/04** — reprodução de áudio e boas práticas
- **04/05 em diante** — desenvolvimento da Parte 2
- **08/06 e 10/06** — playtesting teoria/prática
- **29/06** — playtesting prática

---

## 3. Fases operacionais do backlog

## Fase 0 — Estrutura do repositório e bootstrap do projeto
**Janela sugerida:** imediatamente / paralelo ao início do desenvolvimento

**Objetivo:** deixar repositório, branches, templates, tasks/issues, sub-issues, Project e backlog prontos para execução do time, antes de prosseguir qualquer fase ou passo.

### Entregas desta fase
- Project, milestones, labels e templates prontos
- backlog publicado
- convenção de nomes/pastas para arte e UI

### Resultado esperado
O time sai desta fase sabendo:
- o que precisa ser programado;
- o que precisa ser desenhado/produzido;
- o que será placeholder;

---

## Fase 1 — Fundação jogável + pré-produção de design
**Janela sugerida:** de **22/04** até o checkpoint de **13/05**

**Objetivo:** ter um runner jogável com chunks, colisão, derrota, restart, cenário inicial e loop base reconhecível.

### Entregas desta fase
- guia visual mínimo do jogo
- inventário inicial de assets
- placeholder kit definido

### Resultado esperado
O time sai desta fase com:
- placeholders prontos e padronizados;
- o que é asset crítico para o jogo completo.

---

## Fase 2 — Primeiro jogável com placeholders + Loop principal
**Janela sugerida:** TBD

**Objetivo:** consolidar coleta, pontuação, efeito adverso, HUD (básica/placeholder), fluxo de menus e chegar ao primeiro checkpoint com um runner claramente jogável, mesmo que ainda visualmente temporário.

### Regra central da fase
Nesta fase, o foco é provar o **funcionamento** do jogo, não a finalização visual/funcional.

### Entregas desta fase
- corrida contínua
- pulo
- colisão
- derrota
- restart
- cenário funcional com placeholders
- obstáculos básicos com formas simples
- HUD mínima com visual temporário
- primeiro jogável demonstrável em aula

### Resultado esperado
Um protótipo jogável, entendível e validável, mesmo usando caixas, blocos, cores chapadas e formas geométricas.

---

## Fase 3 — Sistemas de retenção + direção visual consolidada
**Janela sugerida:** de **08/06** até **22/06**

**Objetivo:** adicionar progressão enxuta, ranking local, upgrades e usar playtesting para consolidar o jogo completo e, em paralelo, fechar a direção visual que guiará a produção dos assets reais (sem necessariamente ter todos os assets prontos).

### Entregas desta fase
- coleta funcional
- score funcional
- efeito adverso funcional
- HUD legível
- menus básicos
- direção de arte validada pelo grupo
- backlog de assets críticos priorizado
- início da produção dos assets mais importantes do jogo

### Resultado esperado
O jogo já se sustenta como experiência demonstrável e o time deixa de trabalhar “no escuro” na parte visual.

---

## Fase 4 — Jogo completo em sistemas + integração dos assets críticos
**Janela sugerida:** de **23/06** até **05/07** com folga para o dia da entrega.

**Objetivo:** fechar os sistemas que faltam e substituir os placeholders mais importantes pelos assets que realmente sustentam a identidade do jogo.

### Entregas desta fase
- loja enxuta funcional
- upgrades essenciais funcionais
- ranking local
- playtesting aplicado
- integração dos assets críticos:
  - player
  - coletáveis
  - obstáculos principais
  - HUD principal
  - menus principais
  - elementos de cenário prioritários

### Resultado esperado
O jogo deixa de ser apenas um protótipo jogável e passa a se parecer com o produto que será entregue.

---

## Fase 5 — Fechamento visual, audiovisual e entrega completa
**Janela sugerida:** de **06/07** até **08/07**

**Objetivo:** fechar o jogo como produto acadêmico completo, estável, coerente visualmente e apresentável.

### Entregas desta fase
- passe de polish visual
- passe de polish sonoro
- consistência entre assets e interface
- substituição dos placeholders remanescentes visíveis/indevidos
- balanceamento final
- build final apresentável

### Resultado esperado
Jogo completo no escopo principal, com identidade visual suficiente para apresentação e portfólio.

---

## Fase 6 — Stretch / buffer
**Janela sugerida:**  de **07/07** até **08/07** apenas se sobrar capacidade

**Objetivo:** atacar itens não essenciais sem comprometer a versão completa.

### Possíveis entregas
- ranking online
- melhorias cosméticas não críticas
- ajustes menores de UX e apresentação

---

## 4. Milestones sugeridos no GitHub

### MS0 — Repo & Bootstrap
**Prazo sugerido:** imediato

Escopo:
- Project criado
- milestones criadas
- labels criadas
- templates criados
- backlog inicial publicado

### MS1 — Checkpoint Parte 2 / 13-05
**Prazo:** 13/05/2026

Escopo mínimo:
- movimento jogável
- pulo
- colisão
- derrota
- restart
- cenário inicial funcional
- HUD mínima

### MS2 — Checkpoint Parte 2 / 20-05
**Prazo:** 20/05/2026

Escopo mínimo:
- coleta funcional
- score funcional
- efeito adverso funcional em versão inicial
- spawns minimamente consistentes

### MS3 — Entrega Parte 2 / 01-06
**Prazo:** 01/06/2026

Escopo mínimo:
- loop da Parte 2 demonstrável
- HUD legível
- menu básico
- build estável da Parte 2

### MS4 — Playtesting & Consolidação
**Prazo:** 22/06/2026

Escopo mínimo:
- ranking local
- loja enxuta
- upgrades essenciais
- rodada de playtesting aplicada
- checkpoint da Parte 3 atendido

### MS5 — Entrega Completa Parte 3
**Prazo:** 06/07/2026

Escopo mínimo:
- jogo completo no escopo principal
- polish suficiente para avaliação
- build final apresentável

### MS6 — Buffer / Stretch
**Prazo:** 08/07/2026

Escopo:
- ranking online, se viável
- ajustes finais não críticos
- publicação no itch.io

---

## 5. GitHub Project sugerido

## Campos
- **Phase**: F0 / F1 / F2 / F3 / F4 / F5
- **Milestone**: MS0 / MS1 / MS2 / MS3 / MS4 / MS5 / MS6
- **Item Type**: user-story / task / bug / repo / stretch
- **Priority**: critical / high / medium / low
- **Status**: backlog / ready / in-progress / review-phase / review-develop / review-main / qa-manual / done / blocked
- **Review Layer**: task->phase / phase->develop / develop->main
- **Test Type**: automated / smoke / manual
- **DoD Status**: not-started / partial / ready / done
- **Target Branch**: develop / phase/<fase>
- **Responsible Pair**: dupla da fase

## Views sugeridas
- **Roadmap por milestone**
- **Board por status**
- **Fase atual**
- **Em review**
- **QA manual**
- **Stretch backlog**
- **Bugs críticos**

---

## 6. User Stories principais e issues sugeridas

# FASE 0 — REPO E BOOTSTRAP

## US-00 — Como equipe, queremos uma estrutura de repositório operacional para conseguir executar o projeto com rastreabilidade e revisão consistente.
**Issue sugerida:** `US-00 | Estruturar repositório, Project, milestones e backlog inicial`

**Milestone:** MS0  
**Priority:** critical  
**DoD da story:**
- Project criado
- milestones publicadas
- labels publicadas
- templates publicados
- backlog inicial versionado

### Sub-issues / tasks
- `T-00.1 | Criar milestones MS0–MS6`
- `T-00.2 | Criar GitHub Project com campos e views`
- `T-00.3 | Criar labels base do fluxo`
- `T-00.4 | Criar templates de User Story, Task, Bug e PR`
- `T-00.5 | Publicar backlog inicial no repositório`

---

# FASE 1 — FUNDAÇÃO JOGÁVEL

## US-01 — Como jogador, quero controlar uma corrida lateral contínua para que o jogo tenha um loop base imediatamente compreensível.
**Issue sugerida:** `US-01 | Implementar corrida lateral contínua e base de movimentação`

**Milestone:** MS1  
**Priority:** critical

**Critérios de aceite:**
- personagem corre continuamente
- input principal responde corretamente
- velocidade base é estável
- corrida não trava no fluxo normal

**DoD da story:**
- sistema jogável integrado à branch da fase
- smoke test executado
- PR validada

### Sub-issues / tasks
- `T-01.1 | Criar cena base do Player`
- `T-01.2 | Implementar corrida automática`
- `T-01.3 | Implementar input principal e estados básicos`
- `T-01.4 | Conectar player à cena Game`

## US-02 — Como jogador, quero pular e cair de forma previsível para conseguir evitar obstáculos com leitura rápida.
**Issue sugerida:** `US-02 | Implementar pulo, gravidade e aterrissagem`

**Milestone:** MS1  
**Priority:** critical

**Critérios de aceite:**
- pulo responde corretamente
- gravidade funciona
- aterrissagem é consistente
- não há travamento de animação/colisão

### Sub-issues / tasks
- `T-02.1 | Implementar input de pulo`
- `T-02.2 | Implementar gravidade`
- `T-02.3 | Implementar detecção de chão`
- `T-02.4 | Ajustar parâmetros de salto`

## US-03 — Como jogador, quero morrer ao colidir com perigo para entender risco e consequência da run.
**Issue sugerida:** `US-03 | Implementar colisão, derrota e restart`

**Milestone:** MS1  
**Priority:** critical

**Critérios de aceite:**
- colisão com obstáculo encerra a run
- estado de game over é alcançado
- reinício funciona sem reset inconsistente

### Sub-issues / tasks
- `T-03.1 | Criar obstáculo base`
- `T-03.2 | Implementar colisão mortal`
- `T-03.3 | Implementar fluxo de derrota`
- `T-03.4 | Implementar restart da run`

## US-04 — Como jogador, quero um cenário inicial legível para compreender o espaço de jogo e o movimento.
**Issue sugerida:** `US-04 | Implementar cenário inicial, câmera e instanciação básica`

**Milestone:** MS1  
**Priority:** high

**Critérios de aceite:**
- cenário inicial existe e é navegável
- câmera acompanha a ação
- instanciação mínima de elementos funciona

### Sub-issues / tasks
- `T-04.1 | Criar cena do cenário inicial`
- `T-04.2 | Implementar câmera 2D`
- `T-04.3 | Instanciar obstáculos básicos`
- `T-04.4 | Ajustar layout inicial para leitura`

## US-05 — Como jogador, quero uma HUD mínima para acompanhar informações essenciais da run.
**Issue sugerida:** `US-05 | Implementar HUD mínima`

**Milestone:** MS1  
**Priority:** high

**Critérios de aceite:**
- HUD exibe pelo menos score/estado básico
- HUD não atrapalha leitura do cenário

### Sub-issues / tasks
- `T-05.1 | Criar estrutura base de HUD`
- `T-05.2 | Exibir score inicial`
- `T-05.3 | Exibir estado mínimo de run`

---

# FASE 2 — LOOP PRINCIPAL DA PARTE 2

## US-06 — Como jogador, quero coletar itens para acumular pontos e alimentar o loop de risco e recompensa.
**Issue sugerida:** `US-06 | Implementar sistema de coleta`

**Milestone:** MS2  
**Priority:** critical

**Critérios de aceite:**
- itens podem ser coletados
- coleta altera score ou estado
- feedback mínimo ocorre na coleta

### Sub-issues / tasks
- `T-06.1 | Criar CollectableBase`
- `T-06.2 | Implementar caixas e pílulas`
- `T-06.3 | Integrar coleta ao score`
- `T-06.4 | Adicionar feedback visual/sonoro mínimo`

## US-07 — Como jogador, quero um sistema de pontuação claro para perceber progresso e desempenho.
**Issue sugerida:** `US-07 | Implementar score, distância e feedback de pontuação`

**Milestone:** MS2  
**Priority:** critical

**Critérios de aceite:**
- score aumenta de forma previsível
- distância ou métrica equivalente é exibida
- HUD atualiza corretamente

### Sub-issues / tasks
- `T-07.1 | Criar contador de score`
- `T-07.2 | Criar contador de distância`
- `T-07.3 | Integrar score e distância à HUD`
- `T-07.4 | Ajustar atualização visual da HUD`

## US-08 — Como jogador, quero sentir o efeito adverso das pílulas ao acumular speed-ups para que o jogo tenha seu diferencial de risco.
**Issue sugerida:** `US-08 | Implementar efeito adverso e variação de velocidade`

**Milestone:** MS2  
**Priority:** critical

**Critérios de aceite:**
- ao acumular 3 speed-ups, o estado adverso dispara
- velocidade e/ou pontuação oscilam conforme a regra definida
- o efeito é perceptível ao jogador

### Sub-issues / tasks
- `T-08.1 | Criar contador de speed-ups`
- `T-08.2 | Implementar gatilho do estado adverso`
- `T-08.3 | Aplicar alteração temporária de velocidade`
- `T-08.4 | Exibir feedback do estado adverso`

## US-09 — Como jogador, quero menus básicos para iniciar, pausar e reiniciar a run com clareza.
**Issue sugerida:** `US-09 | Implementar fluxo de menu inicial, pausa e game over`

**Milestone:** MS3  
**Priority:** high

**Critérios de aceite:**
- menu inicial existe
- pausa funciona
- tela de game over funciona
- restart é acessível

### Sub-issues / tasks
- `T-09.1 | Criar menu inicial`
- `T-09.2 | Criar pausa`
- `T-09.3 | Criar tela de game over`
- `T-09.4 | Conectar menu ao fluxo da run`

## US-10 — Como equipe, queremos uma build demonstrável da Parte 2 para cumprir os checkpoints e a entrega com estabilidade.
**Issue sugerida:** `US-10 | Consolidar build da Parte 2`

**Milestone:** MS3  
**Priority:** critical

**Critérios de aceite:**
- projeto roda sem quebra crítica
- fluxo central é demonstrável
- build pode ser apresentada em aula

### Sub-issues / tasks
- `T-10.1 | Corrigir bugs críticos da Parte 2`
- `T-10.2 | Revisar fluxo principal`
- `T-10.3 | Preparar build/apresentação da Parte 2`

---

# FASE 3 — SISTEMAS DE RETENÇÃO E PREPARAÇÃO DA PARTE 3

## US-11 — Como jogador, quero uma loja simples de upgrades para transformar pontuação em progressão e rejogabilidade.
**Issue sugerida:** `US-11 | Implementar loja de upgrades enxuta`

**Milestone:** MS4  
**Priority:** high

**Critérios de aceite:**
- existe loja simples
- pontos/moedas podem ser gastos
- upgrades aplicam efeito real na run

### Sub-issues / tasks
- `T-11.1 | Definir moeda/recurso de compra`
- `T-11.2 | Criar interface da loja`
- `T-11.3 | Implementar compra e persistência mínima`
- `T-11.4 | Integrar loja ao fluxo da run`

## US-12 — Como jogador, quero upgrades essenciais para perceber evolução entre runs.
**Issue sugerida:** `US-12 | Implementar upgrades essenciais`

**Milestone:** MS4  
**Priority:** high

**Critérios de aceite:**
- pelo menos upgrades essenciais funcionam
- efeitos são perceptíveis
- não quebram o loop principal

### Escopo recomendado desta story
- pulo duplo
- escudo temporário
- dash
- multiplicador ou melhoria de pontuação

### Sub-issues / tasks
- `T-12.1 | Implementar pulo duplo`
- `T-12.2 | Implementar escudo temporário`
- `T-12.3 | Implementar dash`
- `T-12.4 | Implementar upgrade de multiplicador ou progressão equivalente`

## US-13 — Como jogador, quero um ranking local para acompanhar minha melhora e perseguir recordes.
**Issue sugerida:** `US-13 | Implementar ranking local`

**Milestone:** MS4  
**Priority:** critical

**Critérios de aceite:**
- score final entra no ranking local
- ranking salva e carrega corretamente
- ranking é exibido ao jogador

### Sub-issues / tasks
- `T-13.1 | Definir estrutura de dados do ranking local`
- `T-13.2 | Salvar ranking localmente`
- `T-13.3 | Carregar ranking ao abrir o jogo`
- `T-13.4 | Exibir ranking no menu/interface`

## US-14 — Como equipe, queremos usar playtesting para ajustar dificuldade, clareza e ritmo antes da entrega completa.
**Issue sugerida:** `US-14 | Executar playtesting e consolidar ajustes`

**Milestone:** MS4  
**Priority:** critical

**Critérios de aceite:**
- rodada de playtesting executada
- feedback consolidado
- ajustes priorizados e aplicados

### Sub-issues / tasks
- `T-14.1 | Criar checklist de playtesting`
- `T-14.2 | Rodar sessão de playtesting`
- `T-14.3 | Consolidar feedback em bugs/ajustes`
- `T-14.4 | Aplicar ajustes críticos identificados`

---

# FASE 4 — FECHAMENTO E ENTREGA COMPLETA

## US-15 — Como jogador, quero feedback audiovisual mais claro para sentir melhor risco, recompensa e estado da run.
**Issue sugerida:** `US-15 | Polir feedback visual e sonoro`

**Milestone:** MS5  
**Priority:** high

**Critérios de aceite:**
- coleta tem feedback melhor
- efeito adverso é legível
- derrota e risco são claros

### Sub-issues / tasks
- `T-15.1 | Melhorar feedback de coleta`
- `T-15.2 | Melhorar feedback do efeito adverso`
- `T-15.3 | Melhorar feedback de derrota`
- `T-15.4 | Revisar áudio e legibilidade geral`

## US-16 — Como equipe, queremos balancear o jogo para que a experiência final seja justa, clara e apresentável.
**Issue sugerida:** `US-16 | Balancear dificuldade, economia e progressão`

**Milestone:** MS5  
**Priority:** critical

**Critérios de aceite:**
- ritmo não está arbitrário
- dificuldade é apresentável
- upgrades não quebram o jogo
- loop completo parece coeso

### Sub-issues / tasks
- `T-16.1 | Balancear spawn de obstáculos`
- `T-16.2 | Balancear spawn de itens`
- `T-16.3 | Balancear custo/efeito dos upgrades`
- `T-16.4 | Balancear frequência e impacto do estado adverso`

## US-17 — Como equipe, queremos fechar uma build final estável para a primeira entrega da Parte 3.
**Issue sugerida:** `US-17 | Fechar build final da Parte 3`

**Milestone:** MS5  
**Priority:** critical

**Critérios de aceite:**
- jogo completo no escopo principal
- bugs críticos corrigidos
- build final apresentável
- material de demonstração pronto

### Sub-issues / tasks
- `T-17.1 | Executar checklist final de regressão`
- `T-17.2 | Corrigir bugs críticos finais`
- `T-17.3 | Gerar build final`
- `T-17.4 | Preparar material de apresentação/demo`

---

# FASE 5 — STRETCH / BUFFER

## US-18 — Como jogador, quero ranking online para competir além da máquina local.
**Issue sugerida:** `US-18 | Ranking online (stretch goal)`

**Milestone:** MS6  
**Priority:** low

**Observação:** esta story só deve entrar se o jogo completo já estiver estável até 06/07.

### Sub-issues / tasks
- `T-18.1 | Definir arquitetura mínima para ranking online`
- `T-18.2 | Implementar envio de score`
- `T-18.3 | Implementar leitura de ranking`
- `T-18.4 | Integrar ranking online ao menu/interface`

---

## 7. Ordem recomendada de criação das issues

### Onda 1 — bootstrap e fundação
1. US-00
2. US-01
3. US-02
4. US-03
5. US-04
6. US-05

### Onda 2 — loop principal da Parte 2
7. US-06
8. US-07
9. US-08
10. US-09
11. US-10

### Onda 3 — sistemas de retenção
12. US-11
13. US-12
14. US-13
15. US-14

### Onda 4 — fechamento
16. US-15
17. US-16
18. US-17

### Onda 5 — stretch
19. US-18

---

## 8. Sugestão de labels para estes itens

### Tipo
- `type:user-story`
- `type:task`
- `type:bug`
- `type:repo`
- `type:stretch`

### Fase
- `phase:0`
- `phase:1`
- `phase:2`
- `phase:3`
- `phase:4`
- `phase:5`

### Prioridade
- `priority:critical`
- `priority:high`
- `priority:medium`
- `priority:low`

### Teste
- `test:automated`
- `test:smoke`
- `test:manual`

### Status
- `status:backlog`
- `status:ready`
- `status:in-progress`
- `status:review-phase`
- `status:review-develop`
- `status:review-main`
- `status:qa-manual`
- `status:done`
- `status:blocked`

---

## 9. Regras de uso prático no Project

- Toda **User Story** entra já com `Phase`, `Milestone`, `Priority` e `Item Type` definidos.
- Toda **Task/Sub-issue** herda fase e milestone da User Story pai.
- Todo item pronto para implementação precisa ter:
  - critérios de aceite;
  - estratégia de teste;
  - DoD visível.
- Toda PR deve referenciar a task correspondente.
- QA final continua manual.
- Stretch goals nunca podem bloquear o fechamento da MS5.

---

## 10. Decisão final de escopo

Para manter o jogo **completo até 06/07/2026**, este backlog assume como escopo principal:

- corrida lateral contínua;
- pulo;
- colisão e derrota;
- restart;
- cenário jogável;
- coleta;
- score;
- efeito adverso por speed-up;
- HUD;
- menus básicos;
- upgrades essenciais;
- ranking local;
- playtesting aplicado;
- polish final suficiente para apresentação.

Fica como escopo secundário / stretch:

- loja enxuta;
- ranking online;
- expansões além do necessário para a entrega acadêmica.
