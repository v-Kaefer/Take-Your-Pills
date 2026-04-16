# Take Your Pills — Backlog Detalhado de Issues e Sub-Issues

## 1. Objetivo deste documento

Este documento existe para detalhar, de forma explícita e sem subentendidos, as **issues** e **sub-issues** que deverão ser abertas no repositório do projeto.

Ele segue o **prazo real do trabalho**, considerando:
- checkpoints da Parte 2
- checkpoint da Parte 3
- entrega final na Parte 3

Este documento não cria nenhuma issue automaticamente. Ele define o backlog a ser criado.

---

## 2. Janela de execução adotada

### Fase 1 — Base técnica
**15/04 até 29/04**

### Fase 2 — MVP para Parte 2
**30/04 até 03/06**

### Fase 3 — Revisão e playtesting
**08/06 até 17/06**

### Fase 4 — Refinamento para Parte 3
**18/06 até 08/07**

---

## 3. Padrão obrigatório de issue

Toda issue deverá conter:
- **título claro**
- **objetivo**
- **descrição exata do que deve ser feito**
- **resultado esperado**
- **critérios de aceite**
- **dependências**
- **prioridade** (`low`, `medium`, `high`)
- **área**
- **fase / período alvo**
- **responsável principal**
- **responsável sombra**

Toda sub-issue deverá conter:
- um escopo menor e executável
- vínculo explícito com a issue-pai
- critério de conclusão observável

### Regra obrigatória de dependências
- issues de implementação não podem depender de issues de teste
- issues de implementação não podem depender de issues de polish
- issues de teste dependem de issues de implementação
- issues de polish dependem de bases funcionais

---

## 4. EPIC 01 — Governança do projeto

## Issue 01.01 — Congelar escopo do projeto
**Objetivo:** registrar formalmente o que entra e o que não entra no projeto.

**Descrição exata:**
Criar um documento curto, aprovado pelo grupo, com a versão definitiva do escopo do jogo para a disciplina.

**Resultado esperado:**
Existe um documento único dizendo claramente o que faz parte da entrega e o que foi excluído.

**Critérios de aceite:**
- o documento lista o MVP
- o documento lista explicitamente o que ficou fora
- todos do grupo concordaram com o texto

**Dependências:** nenhuma.

**Prioridade:** high  
**Área:** repo / docs  
**Período alvo:** Fase 1

### Sub-issues
- 01.01.1 listar features incluídas
- 01.01.2 listar features excluídas
- 01.01.3 validar o texto com o grupo

---

## Issue 01.02 — Definir regras oficiais de pontuação
**Objetivo:** registrar a fórmula de score sem ambiguidade.

**Descrição exata:**
Definir por escrito os multiplicadores por cenário e por velocidade, além da fórmula final de cálculo.

**Resultado esperado:**
Qualquer pessoa do grupo consegue implementar a pontuação sem precisar interpretar o design.

**Critérios de aceite:**
- laboratório = 0.5x
- ruas = 1.0x
- casa = 2.0x
- lento = 0.75x
- super lento = 0.5x
- normal = 1.0x
- rápido = 1.5x
- super rápido = 2.0x
- a fórmula final está registrada

**Dependências:** 01.01.

**Prioridade:** high  
**Área:** runner / speed-system  
**Período alvo:** Fase 1

### Sub-issues
- 01.02.1 documentar multiplicadores por cenário
- 01.02.2 documentar multiplicadores por velocidade
- 01.02.3 documentar fórmula final
- 01.02.4 adicionar exemplos de cálculo

---

## Issue 01.03 — Definir os 4 coletáveis iniciais
**Objetivo:** fixar quais são os quatro coletáveis do jogo.

**Descrição exata:**
Decidir e registrar nome, função e valor de cada coletável inicial.

**Resultado esperado:**
Não existe dúvida sobre quantos coletáveis existem e para que cada um serve.

**Critérios de aceite:**
- existem 4 coletáveis definidos
- cada coletável possui função registrada
- cada coletável possui valor base ou efeito registrado

**Dependências:** 01.01.

**Prioridade:** high  
**Área:** collectables  
**Período alvo:** Fase 1

### Sub-issues
- 01.03.1 definir coletável de pontuação comum
- 01.03.2 definir coletável de pontuação especial
- 01.03.3 definir coletável de aceleração
- 01.03.4 definir coletável de desaceleração

---

## Issue 01.04 — Definir convenções de repositório
**Objetivo:** padronizar branch, commit, PR, labels e prioridades.

**Descrição exata:**
Registrar no repositório o padrão de nome de branch, padrão de commit, labels e regras de PR.

**Resultado esperado:**
O grupo passa a trabalhar sob uma convenção única.

**Critérios de aceite:**
- padrão de branch definido
- padrão de commit definido
- labels definidas
- regra de PR definida
- prioridades low/medium/high definidas

**Dependências:** nenhuma.

**Prioridade:** medium  
**Área:** repo  
**Período alvo:** Fase 1

### Sub-issues
- 01.04.1 definir padrão de branch
- 01.04.2 definir padrão de commit
- 01.04.3 definir padrão de PR
- 01.04.4 definir labels
- 01.04.5 definir prioridades

---

## 5. EPIC 02 — Base técnica do projeto Godot

## Issue 02.01 — Estruturar projeto Godot
**Objetivo:** criar a estrutura-base do projeto.

**Descrição exata:**
Organizar pastas, cenas, autoloads e convenções de nomes para evitar bagunça durante o desenvolvimento.

**Resultado esperado:**
O projeto tem organização previsível e reutilizável.

**Critérios de aceite:**
- estrutura de pastas criada
- cenas-base criadas
- autoloads definidos
- nomes padronizados

**Dependências:** 01.01.

**Prioridade:** high  
**Área:** repo / build  
**Período alvo:** Fase 1

### Sub-issues
- 02.01.1 criar pastas principais
- 02.01.2 criar cenas base
- 02.01.3 registrar autoloads
- 02.01.4 documentar convenção de nomes

---

## Issue 02.02 — Configurar scripts de verificação antes do push
**Objetivo:** impedir envio de alterações perigosas sem checagem mínima.

**Descrição exata:**
Planejar e depois implementar scripts para detectar conflitos, arquivos indevidos, falhas básicas do projeto e falhas em testes.

**Resultado esperado:**
O repositório possui proteção mínima contra pushes problemáticos.

**Critérios de aceite:**
- existe plano de hook pre-push
- existem scripts previstos para conflito, arquivos proibidos, smoke check e testes
- o fluxo está documentado

**Dependências:** 01.04 e 02.01.

**Prioridade:** high  
**Área:** repo / test  
**Período alvo:** Fase 1

### Sub-issues
- 02.02.1 definir hook pre-push
- 02.02.2 definir script de conflito de merge
- 02.02.3 definir script de arquivos proibidos
- 02.02.4 definir smoke check do Godot
- 02.02.5 definir execução de testes

---

## 6. EPIC 03 — Movimento e sobrevivência

## Issue 03.01 — Implementar corrida automática
**Objetivo:** o personagem deve se mover automaticamente para frente.

**Descrição exata:**
Criar a lógica que faz o personagem correr sem input de movimentação horizontal manual.

**Resultado esperado:**
Ao iniciar a run, o personagem já está correndo automaticamente.

**Critérios de aceite:**
- o personagem se move sem precisar apertar tecla de andar
- a velocidade horizontal responde ao estado de velocidade atual
- o personagem não anda para trás
- a corrida para em pausa ou game over

**Dependências:** 02.01.

**Prioridade:** high  
**Área:** player  
**Período alvo:** Fase 1

### Sub-issues
- 03.01.1 criar script base do player
- 03.01.2 implementar movimento horizontal automático
- 03.01.3 conectar velocidade horizontal ao sistema de estado
- 03.01.4 garantir parada em pausa / derrota

---

## Issue 03.02 — Implementar pulo
**Objetivo:** permitir que o jogador desvie de obstáculos por salto.

**Descrição exata:**
Criar a lógica de pulo, queda e aterrissagem do personagem.

**Resultado esperado:**
O pulo é previsível, controlável e compatível com o ritmo do runner.

**Critérios de aceite:**
- o pulo acontece ao input correto
- o personagem sobe, cai e aterrissa corretamente
- o pulo não trava animações nem colisões
- o pulo funciona em sequência normal de gameplay

**Dependências:** 03.01.

**Prioridade:** high  
**Área:** player  
**Período alvo:** Fase 1

### Sub-issues
- 03.02.1 implementar input de pulo
- 03.02.2 implementar gravidade
- 03.02.3 implementar detecção de chão
- 03.02.4 ajustar parâmetros de salto

---

## Issue 03.03 — Implementar colisão e derrota
**Objetivo:** o jogo deve encerrar corretamente quando a condição de derrota ocorrer.

**Descrição exata:**
Criar a lógica de colisão com obstáculos e derrotas por velocidade extrema.

**Resultado esperado:**
O jogador consegue morrer de forma consistente e o jogo reage corretamente.

**Critérios de aceite:**
- obstáculo mata ou derrota conforme regra definida
- derrota por velocidade alta extrema funciona
- derrota por velocidade baixa extrema funciona
- a run encerra corretamente em qualquer derrota válida

**Dependências:** 03.01 e 03.02.

**Prioridade:** high  
**Área:** player / speed-system  
**Período alvo:** Fase 1

### Sub-issues
- 03.03.1 criar sistema de colisão com obstáculo
- 03.03.2 criar derrota por excesso de rapidez
- 03.03.3 criar derrota por excesso de lentidão
- 03.03.4 disparar fluxo de fim de run

---

## Issue 03.04 — Implementar reinício rápido
**Objetivo:** reiniciar a run com o menor atrito possível.

**Descrição exata:**
Criar o fluxo de restart após derrota, mantendo velocidade de uso alta em playtesting.

**Resultado esperado:**
Após morrer, o jogador consegue reiniciar rapidamente.

**Critérios de aceite:**
- existe botão ou ação clara de reinício
- reinício não quebra estado interno
- score e estado da run são resetados corretamente

**Dependências:** 03.03.

**Prioridade:** high  
**Área:** ui / runner  
**Período alvo:** Fase 1

### Sub-issues
- 03.04.1 criar ação de restart
- 03.04.2 resetar estado da sessão
- 03.04.3 validar reinício após cada tipo de derrota

---

## 7. EPIC 04 — Pontuação e velocidade

## Issue 04.01 — Implementar score e distância
**Objetivo:** o jogo deve medir pontuação e progresso de percurso.

**Descrição exata:**
Criar contadores para score total e distância percorrida na run.

**Resultado esperado:**
A HUD consegue exibir score e distância em tempo real.

**Critérios de aceite:**
- score atualiza quando o jogador coleta itens
- distância cresce com a run
- score e distância resetam em nova run

**Dependências:** 03.01.

**Prioridade:** high  
**Área:** runner / ui  
**Período alvo:** Fase 1

### Sub-issues
- 04.01.1 criar contador de score
- 04.01.2 criar contador de distância
- 04.01.3 integrar dados com HUD

---

## Issue 04.02 — Implementar sistema genérico de coletáveis
**Objetivo:** permitir criação, spawn e coleta dos 4 itens do jogo por uma mesma base técnica.

**Descrição exata:**
Criar estrutura reutilizável para coletáveis com dados configuráveis.

**Resultado esperado:**
Todos os coletáveis usam a mesma base de código e mudam apenas por configuração.

**Critérios de aceite:**
- existe uma cena ou estrutura base para coletável
- coletáveis aceitam configuração por tipo
- coletáveis podem aplicar score ou alteração de estado

**Dependências:** 01.03 e 02.01.

**Prioridade:** high  
**Área:** collectables  
**Período alvo:** Fase 2

### Sub-issues
- 04.02.1 criar CollectableBase
- 04.02.2 criar configuração por dados
- 04.02.3 integrar coleta com score
- 04.02.4 integrar coleta com velocidade

---

## Issue 04.03 — Implementar máquina de estados de velocidade
**Objetivo:** tratar velocidade como sistema fechado e previsível.

**Descrição exata:**
Criar os estados super lento, lento, normal, rápido e super rápido, com transições baseadas no acúmulo dos coletáveis corretos.

**Resultado esperado:**
O jogo consegue subir e descer níveis de velocidade de forma controlada.

**Critérios de aceite:**
- o jogador começa em estado normal
- o estado sobe com 3 coletas de aceleração
- o estado desce com 3 coletas de desaceleração
- tentar subir acima de super rápido causa derrota
- tentar descer abaixo de super lento causa derrota
- o sistema impede estados inválidos fora da regra

**Dependências:** 04.02.

**Prioridade:** high  
**Área:** speed-system  
**Período alvo:** Fase 2

### Sub-issues
- 04.03.1 criar enum ou estrutura de estados
- 04.03.2 criar contador de aceleração
- 04.03.3 criar contador de desaceleração
- 04.03.4 aplicar transição de estado
- 04.03.5 bloquear transições inválidas

---

## Issue 04.04 — Implementar multiplicadores de score
**Objetivo:** aplicar score conforme cenário e velocidade.

**Descrição exata:**
Conectar o sistema de pontuação aos multiplicadores de cenário e velocidade.

**Resultado esperado:**
O valor final de cada coleta respeita a fórmula do projeto.

**Critérios de aceite:**
- laboratório usa 0.5x
- ruas usam 1x
- casa usa 2x
- super lento usa 0.5x
- lento usa 0.75x
- normal usa 1x
- rápido usa 1.5x
- super rápido usa 2x
- o score final segue a fórmula registrada

**Dependências:** 01.02, 04.01 e 04.03.

**Prioridade:** high  
**Área:** runner / speed-system  
**Período alvo:** Fase 2

### Sub-issues
- 04.04.1 aplicar multiplicador de cenário
- 04.04.2 aplicar multiplicador de velocidade
- 04.04.3 validar cálculo final
- 04.04.4 exibir resultado corretamente na HUD

---

## Issue 04.05 — Implementar feedback de estado de velocidade
**Objetivo:** tornar o estado de velocidade legível para o jogador.

**Descrição exata:**
Adicionar feedback visual e sonoro ao entrar, sair ou aproximar-se de um estado extremo.

**Resultado esperado:**
O jogador entende em que estado está e percebe risco antes da derrota.

**Critérios de aceite:**
- a HUD exibe o estado atual
- há feedback de mudança de estado
- o estado extremo é perceptível antes da derrota

**Dependências:** 04.03.

**Prioridade:** high  
**Área:** speed-system / ui / audio  
**Período alvo:** Fase 2

### Sub-issues
- 04.05.1 mostrar estado na HUD
- 04.05.2 criar alerta visual
- 04.05.3 criar feedback sonoro

---

## 8. EPIC 05 — Cenários e fluxo

## Issue 05.01 — Implementar laboratório
**Objetivo:** criar o primeiro contexto de jogo.

**Descrição exata:**
Construir o cenário do laboratório com spawn, obstáculos e leitura inicial da mecânica.

**Resultado esperado:**
O laboratório funciona como início da run.

**Critérios de aceite:**
- o jogo inicia no laboratório
- o laboratório possui conteúdo jogável
- o laboratório permite score e coleta

**Dependências:** 03.01, 03.02, 04.01 e 04.02.

**Prioridade:** high  
**Área:** scenario  
**Período alvo:** Fase 2

### Sub-issues
- 05.01.1 montar layout base do laboratório
- 05.01.2 definir obstáculos do laboratório
- 05.01.3 definir tabela de spawn do laboratório

---

## Issue 05.02 — Implementar ruas
**Objetivo:** criar o cenário base principal do jogo.

**Descrição exata:**
Construir o cenário das ruas como contexto central da maior parte da run.

**Resultado esperado:**
As ruas funcionam como cenário recorrente principal.

**Critérios de aceite:**
- o cenário das ruas está jogável
- o score nas ruas usa multiplicador 1x
- o jogador pode permanecer nas ruas sem quebra do loop

**Dependências:** 05.01.

**Prioridade:** high  
**Área:** scenario  
**Período alvo:** Fase 2

### Sub-issues
- 05.02.1 montar layout base das ruas
- 05.02.2 definir obstáculos das ruas
- 05.02.3 definir tabela de spawn das ruas

---

## Issue 05.03 — Implementar transição laboratório → ruas
**Objetivo:** fazer a run sair corretamente do contexto inicial para o principal.

**Descrição exata:**
Criar a regra que detecta a condição de transição e troca o cenário mantendo a run viva.

**Resultado esperado:**
O jogador deixa o laboratório e entra nas ruas sem resetar a sessão.

**Critérios de aceite:**
- a transição ocorre em condição definida
- a sessão continua ativa após a transição
- score, velocidade e HUD continuam corretos

**Dependências:** 05.01 e 05.02.

**Prioridade:** high  
**Área:** scenario / runner  
**Período alvo:** Fase 2

### Sub-issues
- 05.03.1 definir gatilho da transição
- 05.03.2 trocar contexto de cenário
- 05.03.3 validar persistência do estado da sessão

---

## Issue 05.04 — Implementar casa temporária
**Objetivo:** criar o evento de cenário temporário de alta recompensa.

**Descrição exata:**
Construir o contexto da casa como cenário temporário com multiplicador 2x.

**Resultado esperado:**
A casa existe como evento funcional, com entrada e saída controladas.

**Critérios de aceite:**
- a casa pode ser acessada a partir das ruas
- a casa possui identidade própria
- a casa possui multiplicador 2x
- a casa não substitui permanentemente as ruas

**Dependências:** 05.02.

**Prioridade:** high  
**Área:** scenario  
**Período alvo:** Fase 3

### Sub-issues
- 05.04.1 montar layout base da casa
- 05.04.2 definir obstáculos da casa
- 05.04.3 definir tabela de spawn da casa

---

## Issue 05.05 — Implementar entrada e saída da casa
**Objetivo:** controlar corretamente o fluxo ruas → casa → ruas.

**Descrição exata:**
Criar condição de entrada, timer de permanência e retorno às ruas.

**Resultado esperado:**
A casa entra e sai da run sem quebrar o jogo.

**Critérios de aceite:**
- a casa só entra quando a condição definida for atendida
- a permanência na casa respeita tempo ou condição registrados
- ao sair, o jogo retorna às ruas mantendo a sessão

**Dependências:** 05.04 e 04.03.

**Prioridade:** high  
**Área:** scenario / runner  
**Período alvo:** Fase 3

### Sub-issues
- 05.05.1 definir gatilho de entrada na casa
- 05.05.2 implementar timer da casa
- 05.05.3 implementar retorno para ruas
- 05.05.4 validar score e velocidade após retorno

---

## 9. EPIC 06 — Interface e ranking local

## Issue 06.01 — Implementar HUD
**Objetivo:** exibir as informações vitais da run.

**Descrição exata:**
Criar interface que mostre score, distância e estado de velocidade em tempo real.

**Resultado esperado:**
O jogador consegue entender o estado atual do jogo olhando a HUD.

**Critérios de aceite:**
- HUD exibe score
- HUD exibe distância
- HUD exibe estado de velocidade
- HUD atualiza em tempo real

**Dependências:** 04.01 e 04.03.

**Prioridade:** high  
**Área:** ui  
**Período alvo:** Fase 2

### Sub-issues
- 06.01.1 exibir score
- 06.01.2 exibir distância
- 06.01.3 exibir estado de velocidade
- 06.01.4 estilizar leitura mínima

---

## Issue 06.02 — Implementar menu inicial, pausa e game over
**Objetivo:** fechar o fluxo de entrada, interrupção e encerramento da run.

**Descrição exata:**
Criar menus e telas mínimas necessárias para iniciar, pausar, perder e reiniciar.

**Resultado esperado:**
O jogo possui fluxo completo do início ao fim da run.

**Critérios de aceite:**
- existe menu inicial
- existe pausa funcional
- existe tela de game over
- existe opção clara de reinício

**Dependências:** 03.04 e 06.01.

**Prioridade:** high  
**Área:** ui  
**Período alvo:** Fase 3

### Sub-issues
- 06.02.1 criar menu inicial
- 06.02.2 criar pausa
- 06.02.3 criar tela de game over
- 06.02.4 conectar fluxo de reinício

---

## Issue 06.03 — Implementar ranking local
**Objetivo:** registrar e exibir os melhores resultados no próprio jogo.

**Descrição exata:**
Criar sistema local para salvar e ler os melhores scores da máquina.

**Resultado esperado:**
O jogo mantém histórico local dos melhores resultados.

**Critérios de aceite:**
- o score final é comparado com o ranking existente
- o ranking salva localmente
- o ranking carrega corretamente ao abrir o jogo
- o ranking é exibido ao usuário

**Dependências:** 04.01 e 06.02.

**Prioridade:** high  
**Área:** ui / runner  
**Período alvo:** Fase 3

### Sub-issues
- 06.03.1 definir estrutura de dados do ranking
- 06.03.2 salvar ranking localmente
- 06.03.3 carregar ranking ao iniciar
- 06.03.4 exibir ranking ao jogador

---

## 10. EPIC 07 — Testes e qualidade

## Issue 07.01 — Definir suíte de testes automatizados
**Objetivo:** selecionar e estruturar os testes automatizados de lógica.

**Descrição exata:**
Planejar e registrar quais partes do projeto serão cobertas por testes automatizados.

**Resultado esperado:**
Existe um plano de testes automatizados aplicável ao projeto.

**Critérios de aceite:**
- escopos de teste listados
- ferramenta escolhida registrada
- estratégia mínima documentada

**Dependências:** 02.02.

**Prioridade:** medium  
**Área:** test  
**Período alvo:** Fase 2

### Sub-issues
- 07.01.1 listar regras testáveis
- 07.01.2 definir organização da pasta de testes
- 07.01.3 decidir cobertura mínima

---

## Issue 07.02 — Implementar testes automatizados críticos
**Objetivo:** validar as regras mais importantes do projeto via automação.

**Descrição exata:**
Criar testes para score, multiplicadores, ranking local, velocidade e timer da casa.

**Resultado esperado:**
As regras mais críticas podem ser validadas sem depender exclusivamente de teste manual.

**Critérios de aceite:**
- existem testes de score
- existem testes de velocidade
- existem testes do ranking local
- existem testes do fluxo da casa

**Dependências:** 07.01, 04.03, 04.04, 05.05 e 06.03.

**Prioridade:** medium  
**Área:** test  
**Período alvo:** Fase 3

### Sub-issues
- 07.02.1 testar score
- 07.02.2 testar multiplicadores
- 07.02.3 testar ranking local
- 07.02.4 testar entrada e saída da casa

---

## Issue 07.03 — Montar checklist de testes manuais
**Objetivo:** padronizar a validação manual por build.

**Descrição exata:**
Criar checklist que o grupo deve executar ao gerar build interna.

**Resultado esperado:**
Toda build passa por verificação manual consistente.

**Critérios de aceite:**
- checklist documentado
- itens de fluxo principal cobertos
- itens de score e ranking cobertos
- itens de cenário cobertos

**Dependências:** 03.04, 04.04, 05.05 e 06.03.

**Prioridade:** high  
**Área:** qa  
**Período alvo:** Fase 3

### Sub-issues
- 07.03.1 validar movimento
- 07.03.2 validar score
- 07.03.3 validar transições
- 07.03.4 validar ranking
- 07.03.5 validar restart e pause

---

## 11. EPIC 08 — Polish e entrega final

## Issue 08.01 — Integrar áudio funcional
**Objetivo:** adicionar feedback sonoro mínimo para suportar clareza do jogo.

**Descrição exata:**
Adicionar sons de coleta, mudança de velocidade, derrota e navegação básica de menu.

**Resultado esperado:**
O jogo responde com áudio aos eventos mais importantes.

**Critérios de aceite:**
- coleta possui feedback sonoro
- mudança de velocidade possui feedback sonoro
- derrota possui feedback sonoro
- menu possui feedback básico

**Dependências:** 04.05 e 06.02.

**Prioridade:** medium  
**Área:** audio  
**Período alvo:** Fase 4

### Sub-issues
- 08.01.1 integrar som de coleta
- 08.01.2 integrar som de velocidade
- 08.01.3 integrar som de derrota
- 08.01.4 integrar som de UI

---

## Issue 08.02 — Integrar VFX leves e melhoria de legibilidade
**Objetivo:** melhorar leitura visual sem inflar escopo.

**Descrição exata:**
Adicionar efeitos leves de feedback, clareza e contraste para estados críticos e eventos importantes.

**Resultado esperado:**
O jogador percebe melhor risco, recompensa e status da run.

**Critérios de aceite:**
- estados críticos estão visualmente claros
- coleta e derrota possuem retorno visual
- legibilidade geral melhorou em relação ao MVP base

**Dependências:** 04.05 e 06.01.

**Prioridade:** medium  
**Área:** ui / polish  
**Período alvo:** Fase 4

### Sub-issues
- 08.02.1 feedback visual de coleta
- 08.02.2 feedback visual de estado crítico
- 08.02.3 feedback visual de derrota
- 08.02.4 revisar contraste de elementos jogáveis

---

## Issue 08.03 — Balancear dificuldade e ritmo
**Objetivo:** ajustar o jogo para uma experiência justa e clara.

**Descrição exata:**
Refinar spawn, velocidade, transição de cenários, frequência da casa e percepção de risco.

**Resultado esperado:**
O jogo fica menos injusto, mais legível e mais adequado para apresentação.

**Critérios de aceite:**
- o grupo considera a curva de dificuldade aceitável
- mortes injustas foram reduzidas
- a casa não entra cedo demais nem tarde demais
- velocidade extrema não parece arbitrária

**Dependências:** 07.03 e 08.02.

**Prioridade:** high  
**Área:** qa / runner / scenario  
**Período alvo:** Fase 4

### Sub-issues
- 08.03.1 ajustar frequência de obstáculos
- 08.03.2 ajustar frequência de coletáveis
- 08.03.3 ajustar gatilho da casa
- 08.03.4 ajustar severidade dos estados extremos

---

## Issue 08.04 — Fechar build final e material de apresentação
**Objetivo:** preparar a versão final para entrega da Parte 3.

**Descrição exata:**
Gerar build final, revisar o fluxo completo e preparar material de apresentação do jogo.

**Resultado esperado:**
Existe uma versão final demonstrável e pronta para ser entregue.

**Critérios de aceite:**
- build final gerada
- fluxo principal validado
- ranking local funcionando
- jogo apresentável para avaliação
- material de apoio separado

**Dependências:** todas as issues críticas anteriores.

**Prioridade:** high  
**Área:** build / qa / docs  
**Período alvo:** Fase 4

### Sub-issues
- 08.04.1 gerar build final
- 08.04.2 executar checklist final
- 08.04.3 capturar imagens ou vídeo
- 08.04.4 organizar apresentação final

---

## 12. Ordem prática de criação das issues

A ordem sugerida de abertura no GitHub é:
1. 01.01
2. 01.02
3. 01.03
4. 01.04
5. 02.01
6. 02.02
7. 03.01
8. 03.02
9. 04.01
10. 03.03
11. 03.04
12. 04.02
13. 04.03
14. 04.04
15. 04.05
16. 05.01
17. 05.02
18. 05.03
19. 06.01
20. 05.04
21. 05.05
22. 06.02
23. 06.03
24. 07.01
25. 07.02
26. 07.03
27. 08.01
28. 08.02
29. 08.03
30. 08.04

---

## 13. Regra final deste backlog

Nenhuma issue deve ser aberta com descrição vaga como:
- “fazer HUD”
- “arrumar cenário”
- “melhorar score”
- “mexer na velocidade”

Toda issue deve dizer claramente:
- o que será feito
- quando estará pronto
- como saber se ficou pronto
- do que depende
- qual é a prioridade

Se a descrição não permitir que outra pessoa assuma a task sem perguntar contexto adicional, a issue ainda está incompleta.
