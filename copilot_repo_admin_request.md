# Prompt para GitHub Copilot — Preparação Administrativa do Repositório `v-Kaefer/Take-Your-Pills`

## Contexto
Este prompt deve ser usado em conjunto com o arquivo de definições do projeto anexado a esta solicitação.

O objetivo é preparar o repositório **antes** da criação automatizada das issues, scripts e demais arquivos operacionais que poderão ser adicionados depois.

A preparação pedida aqui é focada principalmente em **aquilo que não está sendo feito diretamente por outra automação** neste momento, especialmente itens administrativos e de configuração do repositório.

---

## Repositório alvo
- **Owner/Repo:** `v-Kaefer/Take-Your-Pills`
- **Branch padrão atual:** `main`
- **Tecnologia principal:** Godot
- **Tipo de projeto:** jogo 2D side-scroller / runner infinito

---

## Resumo do projeto
O projeto é um jogo 2D estilizado, em Godot, com escopo acadêmico e foco em um **MVP jogável**, seguido de uma fase de refinamento final.

### Escopo do MVP
- runner infinito
- ranking local
- 4 coletáveis iniciais
- sistema de velocidade
- 3 contextos de cenário:
  - laboratório
  - ruas
  - casa dos habitantes por tempo limitado

### Escopo fora desta fase
- ranking online
- upgrades / loja
- narrativa expandida
- sistemas grandes fora do loop principal

---

## Definições normalizadas que devem ser tratadas como fonte de verdade

### 1. Sistema de velocidade — versão corrigida
Há versões conflitantes do material anterior. Para esta preparação, adote a seguinte definição como **canônica**:

#### Estados de velocidade
- **Super Lento**
- **Lento**
- **Normal**
- **Rápido**
- **Super Rápido**

#### Regras de transição
- a cada 3 coletas do grupo de desaceleração, o jogador desce 1 estado
- a cada 3 coletas do grupo de aceleração, o jogador sobe 1 estado
- tentar descer abaixo de **Super Lento** causa derrota por sonolência / queda dormindo
- tentar subir acima de **Super Rápido** causa derrota por queda / machucado

#### Multiplicadores de pontuação por velocidade
- **Super Lento:** `0.5x`
- **Lento:** `0.75x`
- **Normal:** `1.0x`
- **Rápido:** `1.5x`
- **Super Rápido:** `2.0x`

### 2. Multiplicadores de pontuação por cenário
- **Laboratório:** `0.5x`
- **Ruas:** `1.0x`
- **Casa:** `2.0x`

### 3. Fórmula de pontuação
```text
Pontos finais = Pontos base do coletável × Multiplicador do cenário × Multiplicador da velocidade
```

### 4. Regra obrigatória de dependência entre issues
Normalize todas as dependências do backlog com esta regra:

- **issues de implementação não podem depender de issues de teste**
- **issues de implementação não podem depender de issues de polish**
- **issues de teste dependem das issues de implementação já prontas**
- **issues de polish dependem das bases funcionais, e não o contrário**

### 5. Correções mínimas obrigatórias de dependência
Caso essas issues existam ou venham a ser criadas com o backlog atual, considere estas correções:

- `03.03 — Implementar colisão e derrota`
  - **remover** dependência de `07.02`
  - **usar** dependências funcionais apenas

- `04.05 — Implementar feedback de estado de velocidade`
  - não deve depender de áudio final como pré-requisito obrigatório
  - o feedback visual pode existir antes do áudio final

- `08.02 — Integrar VFX leves e melhoria de legibilidade`
  - deve depender do sistema funcional, não do áudio como bloqueio absoluto

Se houver qualquer outra dependência invertida do tipo “feature depende de teste” ou “feature depende de polish”, corrija no backlog/documentação.

---

## O que deve ser criado ou configurado agora

### 1. Labels do repositório
Criar as labels abaixo exatamente com esses nomes.

#### Prioridade
- `priority:low`
- `priority:medium`
- `priority:high`

#### Tipo
- `type:feature`
- `type:bug`
- `type:chore`
- `type:docs`
- `type:test`
- `type:polish`

#### Área
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

#### Estado
- `status:blocked`
- `status:needs-review`
- `status:ready-for-qa`

Se seu ambiente não puder criar labels diretamente, gere um arquivo Markdown com a lista completa e um checklist manual de criação.

---

### 2. Milestones do repositório
Criar milestones alinhadas às fases reais do projeto.

#### Milestones desejadas
- `Fase A — Fundação técnica (16/04–29/04)`
- `Fase B — MVP jogável para Parte 2 (30/04–13/05)`
- `Fase C — MVP completo para Parte 2 (14/05–03/06)`
- `Fase D — Playtesting e revisão estrutural (08/06–17/06)`
- `Fase E — Refinamento para Parte 3 (18/06–22/06)`
- `Fase F — Entrega final da Parte 3 (23/06–08/07)`

Se não puder criar milestones diretamente, gerar documentação manual com a descrição de cada uma.

---

### 3. Regras de branch / proteção do repositório
Configurar, se o ambiente permitir:

#### Para `main`
- impedir push direto
- exigir PR para merge
- exigir pelo menos 1 revisão
- impedir merge com checks obrigatórios falhando
- manter `main` sempre estável

#### Para `dev`
- permitir integração do time por PR
- exigir checks básicos quando existirem
- evitar merge direto sem revisão, se possível

Se o ambiente não puder alterar regras administrativas, gerar um arquivo em `docs/repo-admin-checklist.md` com:
- regras a aplicar manualmente
- ordem de aplicação
- nomes sugeridos dos checks obrigatórios

---

### 4. Branch `dev`
Se possível, criar a branch `dev` a partir de `main`.

Se não for possível, registrar isso no checklist manual.

---

### 5. Project board / tracking board
Se seu ambiente permitir, criar um board simples com colunas equivalentes a:
- Backlog
- Ready
- In Progress
- Review
- QA
- Done

Se isso não for possível, gerar documentação com a estrutura sugerida.

---

## O que NÃO deve ser feito neste momento
Não criar ainda:
- issues do backlog
- sub-issues
- scripts locais
- arquivos de workflow
- templates de issue
- templates de PR
- arquivos de automação local
- código do jogo

Esses itens poderão ser criados depois por outra automação.

---

## Resultado esperado desta preparação
Ao final, o repositório deve estar com o terreno pronto para a próxima fase, com:

- labels prontas
- milestones prontas
- regras de branch definidas ou documentadas
- branch `dev` pronta ou registrada como pendência
- board de acompanhamento pronto ou documentado
- inconsistências centrais de dependência e de velocidade registradas de forma corrigida

---

## Entrega alternativa, caso haja limitações do ambiente
Se você não puder executar parte das alterações administrativas diretamente no GitHub, então faça o seguinte:

1. Gere um arquivo `docs/repo-admin-checklist.md` contendo tudo que precisa ser configurado manualmente.
2. Gere um arquivo `docs/backlog-normalization-notes.md` registrando:
   - a versão final do sistema de velocidade
   - a regra correta de dependência entre issues
   - as correções mínimas de dependência listadas acima
3. Não invente novas features.
4. Não mude o escopo do jogo.
5. Não reabra discussão de design já definida.

---

## Critério de sucesso
Esta tarefa será considerada bem executada se, ao final, o repositório estiver preparado administrativamente para que outra automação possa, depois, criar:
- issues
- sub-issues
- documentação interna
- templates
- scripts
- workflows

com menos risco de inconsistência, retrabalho e conflito de organização.
