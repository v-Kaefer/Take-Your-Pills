# Planejamento de automações, workflows, governança e scripts para o Repo 2 (`v-Kaefer/Take-Your-Pills`)

## 1. Objetivo

Usar o **Repo 1 (`v-Kaefer/Const-Software-25-02`) como referência estrutural** de CI/CD, organização e automações, mas **sem copiar a stack técnica específica dele** para o Repo 2.

Como você definiu que o **Repo 2 deve ser tratado como um repositório limpo**, este plano considera que ele vai receber:

- configurações de GitHub;
- workflows de Actions;
- convenções de branch/PR/issue;
- scripts para criação de issues e sub-issues;
- preparação para uso com GitHub Projects;
- base para futuras automações de review, labels, status e rastreabilidade.

A ideia é **portar o modelo**, e não o conteúdo técnico específico de Go/AWS/Cognito do Repo 1.

---

## 2. O que foi observado no Repo 1

### 2.1. Padrão geral de automação do Repo 1

O Repo 1 já tem uma base relativamente madura de automação, com estes pontos principais:

1. **Workflow orquestrador**
   - `ci.yaml` centraliza a execução.
   - Ele chama workflows reutilizáveis separados para build, testes e docker build.

2. **Workflows reutilizáveis e segmentados**
   - `build.yaml`
   - `tests.yaml`
   - `docker-build.yaml`

3. **Preocupação com qualidade e rastreabilidade**
   - `go vet`
   - validação do contrato OpenAPI
   - cobertura de testes com artifact
   - build de imagem Docker sem push

4. **Infraestrutura local e produtiva organizada**
   - `Makefile` como interface operacional
   - `docker-compose.yaml` para stack local
   - `Dockerfile`
   - `infra/` com Terraform
   - suporte a LocalStack + cognito-local

5. **Automação específica de governança de IA**
   - `verify-copilot-contributions.yaml` adiciona uma camada de controle para contribuições feitas com Copilot.

### 2.2. Conclusão prática sobre o Repo 1

O valor real do Repo 1, para reaproveitamento no Repo 2, está em:

- **separação entre workflow principal e workflows reutilizáveis**;
- **padronização operacional**;
- **organização da governança do repositório**;
- **preparo para evolução gradual**.

### 2.3. O que **não** deve ser copiado literalmente para o Repo 2

Como o Repo 2 será tratado como limpo, estes itens do Repo 1 devem servir apenas como inspiração, não como cópia direta:

- validações específicas de **Go**;
- validações específicas de **OpenAPI**;
- build específico de **Docker da API**;
- infra específica de **AWS / Terraform / Cognito / LocalStack**;
- comandos do `Makefile` acoplados ao backend do Repo 1.

---

## 3. Diretriz para o Repo 2

### 3.1. Estratégia recomendada

Para o Repo 2, a melhor abordagem é dividir a implantação em **3 camadas**:

#### Camada A — Governança do repositório
Base que independe da engine, linguagem ou runtime:

- labels padronizadas;
- templates de issue e PR;
- `CODEOWNERS`;
- convenções de branches;
- regras para milestones, épicos e sub-issues;
- automação de adição em project;
- automação de atualização de status.

#### Camada B — CI/CD genérico
Ainda sem depender fortemente da stack do projeto:

- lint de YAML, Markdown e shell scripts;
- validação de estrutura de arquivos obrigatórios;
- verificação de branches/nomes/PR metadata;
- checagem de consistência de labels e templates;
- checagem de arquivos de configuração do repositório.

#### Camada C — CI/CD específico da stack
Ativado depois que o Repo 2 tiver a stack final consolidada:

- build/test do jogo;
- export/pacote;
- validações de assets;
- release artifacts;
- smoke tests específicos.

Como o repo vai apenas receber as configs agora, o plano abaixo já deixa **A e B prontas**, e prepara **C** para encaixe posterior.

---

## 4. Estrutura recomendada para o Repo 2

```text
.github/
  CODEOWNERS
  pull_request_template.md
  labels.yml
  ISSUE_TEMPLATE/
    bug_report.yml
    feature_request.yml
    task.yml
    epic.yml
  workflows/
    ci.yml
    repo-quality.yml
    governance-checks.yml
    issue-automation.yml
    project-sync.yml
    verify-ai-contributions.yml   # opcional
  project/
    fields.json
    views.json
    workflows.json
scripts/
  github/
    bootstrap-labels.sh
    create-issue.sh
    create-subissue.sh
    create-issue-tree.sh
    create-project.sh
    seed-project.sh
    sync-project-fields.sh
config/
  issues/
    roadmap.yml
    sprint-01.yml
  projects/
    default-project.json
docs/
  repository-governance.md
  workflow-map.md
  automation-runbook.md
```

---

## 5. Workflows recomendados para o Repo 2

## 5.1. `ci.yml`

### Função
Workflow principal do repositório, inspirado no `ci.yaml` do Repo 1.

### Responsabilidade
Orquestrar os workflows menores.

### Gatilhos
- `push` para branches principais;
- `pull_request` para branches principais.

### Chamadas recomendadas
- `repo-quality.yml`
- `governance-checks.yml`
- futuramente `engine-build.yml` ou equivalente

### Vantagem
Repete o padrão mais saudável do Repo 1: **um workflow principal pequeno**, e o trabalho real distribuído em unidades reutilizáveis.

---

## 5.2. `repo-quality.yml`

### Função
Validar a qualidade dos próprios arquivos do repositório.

### Deve incluir
- `actionlint` para workflows;
- `yamllint` para YAML;
- `markdownlint` para documentação;
- `shellcheck` para scripts `.sh`;
- validação de JSON/YAML de configuração.

### Motivo
Como o Repo 2 vai começar recebendo configs, esta automação já traz valor imediatamente, mesmo antes do projeto ter código de produção.

---

## 5.3. `governance-checks.yml`

### Função
Validar regras de governança do repositório.

### Verificações recomendadas
- existência de `CODEOWNERS`;
- existência de templates obrigatórios;
- consistência do arquivo de labels;
- presença de issue types esperados;
- nome de branch no padrão definido;
- PR com template preenchido;
- PR referenciando issue vinculada quando aplicável.

### Exemplo de regra
Aceitar branches como:

- `feat/...`
- `fix/...`
- `chore/...`
- `docs/...`
- `refactor/...`
- `test/...`
- `hotfix/...`

---

## 5.4. `issue-automation.yml`

### Função
Responder a eventos de issues e PRs.

### Eventos úteis
- `issues: opened, edited, labeled`
- `pull_request: opened, edited, synchronize, closed`

### Ações sugeridas
- aplicar labels automáticas por template/título;
- comentar instruções iniciais em épicos;
- validar se issue pai tem subtarefas suficientes;
- checar se PR está vinculada a issue;
- atualizar status da issue quando PR é aberta;
- mover issue para “In Review” ao abrir PR;
- mover issue para “Done” ao mergear PR.

---

## 5.5. `project-sync.yml`

### Função
Sincronizar GitHub Issues/PRs com GitHub Projects.

### Responsabilidades
- adicionar novas issues ao project automaticamente;
- preencher campos como:
  - Status
  - Tipo
  - Prioridade
  - Área
  - Sprint
- atualizar status com base em eventos:
  - issue aberta → `Backlog`
  - issue com branch/PR → `In Progress`
  - PR aberta → `In Review`
  - PR mergeada → `Done`

### Observação importante
Esse workflow depende fortemente de:

- `PROJECT_ID`
- `FIELD_ID`s do project
- token com permissão para projects

Por isso, ele deve ser preparado desde o começo, mesmo que o project seja criado manualmente na primeira vez.

---

## 5.6. `verify-ai-contributions.yml` (opcional)

### Função
Transportar a ideia do Repo 1 de rastrear alterações assistidas por IA.

### Quando vale a pena
Se você quiser manter no Repo 2 uma disciplina semelhante à do Repo 1, com:

- PR checklist sobre uso de IA;
- changelog ou arquivo de rastreabilidade;
- comentários automáticos cobrando atualização de documentação.

### Recomendação
No Repo 2, eu usaria uma versão **mais genérica** que não dependa só de Copilot, por exemplo:

- verificar se o PR marcou `IA utilizada: sim/não`;
- exigir atualização de uma seção do template quando houve auxílio de IA.

---

## 6. Arquivos de governança recomendados

## 6.1. `CODEOWNERS`

Mesmo o Repo 1 não exibindo esse arquivo na base observada, o Repo 2 **deve** receber isso desde o início.

### Motivo
Ele viabiliza automações futuras como:

- review request por área;
- obrigatoriedade de aprovação por domínio;
- rastreabilidade por responsabilidade.

### Exemplo inicial
```text
* @v-Kaefer
.github/ @v-Kaefer
scripts/ @v-Kaefer
config/ @v-Kaefer
```

Se depois houver líderes por área, o arquivo pode crescer com granularidade.

---

## 6.2. Templates de issue

### Templates mínimos
- `epic.yml`
- `feature_request.yml`
- `task.yml`
- `bug_report.yml`

### Objetivo
Padronizar os metadados usados pelos scripts e pelas automações.

### Campos recomendados
- resumo;
- contexto;
- objetivo;
- critério de aceitação;
- área;
- prioridade;
- dependências;
- sprint;
- issue pai.

---

## 6.3. Template de PR

### Deve conter
- issue vinculada;
- tipo da mudança;
- impacto;
- evidências;
- checklist de validação;
- uso de IA;
- risco de merge.

---

## 6.4. `labels.yml`

Recomendo manter as labels como **fonte única da verdade** em arquivo versionado.

### Grupos sugeridos

#### Tipo
- `type:epic`
- `type:feature`
- `type:task`
- `type:bug`
- `type:chore`

#### Área
- `area:gameplay`
- `area:ui`
- `area:art`
- `area:audio`
- `area:infra`
- `area:docs`
- `area:automation`

#### Estado e prioridade
- `priority:p0`
- `priority:p1`
- `priority:p2`
- `priority:p3`
- `status:blocked`
- `status:needs-info`

#### Fluxo
- `needs-review`
- `ready`
- `in-progress`
- `good first issue`

---

## 7. Scripts recomendados

## 7.1. `bootstrap-labels.sh`

### Função
Criar/sincronizar labels a partir do arquivo versionado.

### Responsabilidade
- ler `.github/labels.yml`;
- criar labels ausentes;
- atualizar descrição/cor das existentes;
- opcionalmente arquivar ou avisar sobre labels órfãs.

### Ferramenta recomendada
- `gh api`
- ou script em Python/Node lendo YAML

### Valor
Evita configuração manual repetitiva em repositório novo.

---

## 7.2. `create-issue.sh`

### Função
Criar uma issue única de forma padronizada.

### Parâmetros sugeridos
- título
- tipo
- área
- prioridade
- body markdown
- labels
- milestone
- assignee

### Exemplo de uso
```bash
./scripts/github/create-issue.sh \
  --repo v-Kaefer/Take-Your-Pills \
  --title "Implementar menu inicial" \
  --type feature \
  --area ui \
  --priority p1
```

---

## 7.3. `create-subissue.sh`

### Função
Criar uma sub-issue vinculada a uma issue pai.

### Estratégia recomendada
1. criar a issue filha;
2. tentar criar o vínculo pai-filho via API/GraphQL;
3. se a API de sub-issue não estiver disponível no ambiente/token, aplicar fallback:
   - comentar/linkar na issue pai;
   - inserir backlinks no corpo da issue filha;
   - aplicar label indicando a issue pai.

### Exemplo de uso
```bash
./scripts/github/create-subissue.sh \
  --repo v-Kaefer/Take-Your-Pills \
  --parent 12 \
  --title "Criar HUD provisória" \
  --type task \
  --area ui \
  --priority p2
```

### Observação importante
Como a automação de sub-issues pode variar por API disponível, este script deve ser escrito com **fallback seguro**. Assim você não fica bloqueado se a mutation específica não estiver disponível no token/escopo atual.

---

## 7.4. `create-issue-tree.sh`

### Função
Criar uma árvore completa de planejamento a partir de um YAML.

### Entrada sugerida
Arquivo em `config/issues/*.yml` contendo:

```yaml
epic:
  title: "Vertical slice inicial"
  area: gameplay
  priority: p1
  children:
    - title: "Movimentação base"
      type: feature
      area: gameplay
      priority: p1
    - title: "HUD provisória"
      type: task
      area: ui
      priority: p2
    - title: "Cena de teste"
      type: task
      area: infra
      priority: p2
```

### Resultado esperado
- cria a issue pai;
- cria as issues filhas;
- vincula tudo;
- opcionalmente adiciona ao project.

### Esse é o script mais valioso
Se você quer acelerar o setup do Repo 2, esse tende a ser o script principal.

---

## 7.5. `create-project.sh`

### Função
Criar um GitHub Project e aplicar a configuração inicial.

### Estado prático
Isso **pode ser automatizado**, mas depende de:

- escopo correto do token;
- owner correto (usuário ou organização);
- suporte do ambiente para `gh project` ou GraphQL.

### Estratégia recomendada
#### Opção A — Preferencial
Usar CLI:

```bash
gh project create --owner v-Kaefer --title "Take Your Pills"
```

#### Opção B — Se necessário
Usar `gh api graphql` para criar e configurar o project.

### Risco
A parte mais sensível não é criar o project em si, e sim:

- configurar campos;
- obter IDs dos campos;
- versionar esses IDs de forma segura para as automações.

Por isso, mesmo que a criação inicial seja manual, o restante da automação ainda vale muito a pena.

---

## 7.6. `seed-project.sh`

### Função
Preparar um project já existente para as automações futuras.

### O que deve fazer
- localizar o `PROJECT_ID`;
- localizar os campos do project;
- exportar um mapa de IDs para `.github/project/fields.json`;
- opcionalmente criar views padrão;
- opcionalmente popular backlog inicial.

### Esse script resolve a parte mais chata
Depois que os IDs ficam versionados, os workflows de sync ficam muito mais simples.

---

## 8. Sobre automação de Projects

## 8.1. O que eu recomendo na prática

Para o Repo 2, eu **não colocaria a criação do Project como dependência crítica do setup**.

A melhor estratégia é:

1. preparar tudo para Projects;
2. criar o primeiro project manualmente ou por script, se o token permitir;
3. capturar os IDs e versionar a configuração;
4. só então ativar os workflows que sincronizam status automaticamente.

## 8.2. Por que isso é melhor

Porque o maior valor não está em “clicar menos para criar o project”, e sim em:

- adicionar issues automaticamente;
- sincronizar status;
- organizar backlog;
- refletir PRs no quadro;
- evitar trabalho manual recorrente.

## 8.3. Preparação mínima para automações de Project

Mesmo se o project inicial for manual, o Repo 2 já deve nascer com:

- labels padronizadas;
- tipos de issue definidos;
- campos esperados documentados;
- scripts para exportar IDs do project;
- workflow de sync pronto para receber os secrets/vars.

---

## 9. Permissões e segredos necessários

## 9.1. Para GitHub Actions

### Permissões mínimas por workflow

#### `ci.yml`, `repo-quality.yml`, `governance-checks.yml`
- `contents: read`

#### `issue-automation.yml`
- `contents: read`
- `issues: write`
- `pull-requests: write`

#### `project-sync.yml`
- `contents: read`
- `issues: write`
- `pull-requests: write`
- permissões equivalentes para projects

## 9.2. Token recomendado

Para scripts locais e automações mais fortes, o ideal é prever:

- `GH_TOKEN` para uso com `gh`;
- eventualmente um PAT ou GitHub App com acesso a:
  - issues
  - pull requests
  - metadata
  - projects

---

## 10. Regras fora do repositório que também devem ser planejadas

Estas partes não ficam em arquivo versionado, mas precisam entrar no plano do Repo 2:

### 10.1. Branch protection / rulesets
Aplicar em `main`:

- exigir PR;
- exigir checks obrigatórios;
- exigir branches atualizadas quando necessário;
- bloquear push direto;
- exigir pelo menos 1 aprovação;
- opcionalmente exigir review de code owner.

### 10.2. Merge strategy
Definir desde o início:

- squash merge como padrão, ou
- merge commit, se você quiser histórico mais fiel de agrupamento.

### 10.3. Naming conventions
Padronizar:

- branches;
- títulos de PR;
- labels;
- milestones;
- épicos.

---

## 11. Fases de implantação recomendadas

## Fase 1 — Base de governança
Implementar:

- `CODEOWNERS`
- templates de issue e PR
- `labels.yml`
- `bootstrap-labels.sh`
- `ci.yml`
- `repo-quality.yml`
- `governance-checks.yml`

### Resultado
O Repo 2 já fica pronto para receber trabalho real com padrão.

---

## Fase 2 — Automação de planejamento
Implementar:

- `create-issue.sh`
- `create-subissue.sh`
- `create-issue-tree.sh`
- `config/issues/*.yml`

### Resultado
Você consegue criar backlog estruturado rapidamente.

---

## Fase 3 — GitHub Projects
Implementar:

- criação do project (manual ou script)
- `seed-project.sh`
- `project-sync.yml`
- `fields.json`

### Resultado
Issues e PRs passam a refletir no quadro automaticamente.

---

## Fase 4 — Stack específica do projeto
Implementar depois que a stack do Repo 2 estiver definida:

- build do projeto;
- testes do projeto;
- export/pacote;
- release artifacts;
- smoke tests.

### Resultado
O repositório deixa de ser só governado e passa a ter CI/CD do produto.

---

## 12. Decisões recomendadas para o Repo 2

## 12.1. O que reaproveitar do Repo 1

Reaproveitar o **modelo**:

- workflow principal + workflows menores;
- separação clara de responsabilidades;
- documentação operacional;
- base para rastreabilidade;
- disciplina de qualidade nos arquivos do repo.

## 12.2. O que adaptar

Adaptar para uma base stack-agnostic:

- remover acoplamento com Go/AWS/Cognito;
- transformar o foco inicial em governança + automação de backlog;
- deixar build/test específico para fase posterior.

## 12.3. O que criar do zero

Criar do zero para o Repo 2:

- labels versionadas;
- scripts de criação de issues/sub-issues;
- preparo para GitHub Projects;
- templates de issue/PR;
- `CODEOWNERS`;
- workflow de sync com project.

---

## 13. Entregável ideal para a próxima etapa

Se a próxima etapa for implementação, eu recomendaria gerar estes arquivos primeiro:

1. `.github/labels.yml`
2. `.github/CODEOWNERS`
3. `.github/pull_request_template.md`
4. `.github/ISSUE_TEMPLATE/epic.yml`
5. `.github/ISSUE_TEMPLATE/feature_request.yml`
6. `.github/ISSUE_TEMPLATE/task.yml`
7. `.github/ISSUE_TEMPLATE/bug_report.yml`
8. `.github/workflows/ci.yml`
9. `.github/workflows/repo-quality.yml`
10. `.github/workflows/governance-checks.yml`
11. `scripts/github/bootstrap-labels.sh`
12. `scripts/github/create-issue.sh`
13. `scripts/github/create-subissue.sh`
14. `scripts/github/create-issue-tree.sh`
15. `docs/repository-governance.md`

E, numa segunda leva:

16. `scripts/github/create-project.sh`
17. `scripts/github/seed-project.sh`
18. `.github/workflows/project-sync.yml`
19. `.github/project/fields.json`

---

## 14. Resumo executivo

O Repo 1 mostra um padrão bom de automação baseado em:

- orquestração por workflow principal;
- workflows reutilizáveis;
- operação documentada;
- padronização de infraestrutura e execução.

Para o Repo 2, como ele será tratado como **repo limpo recebendo apenas configs**, o melhor plano é:

- **não portar a stack técnica do Repo 1**;
- **portar a arquitetura de governança e automação**;
- começar por **governança + CI genérico**;
- depois adicionar **scripts de backlog (issues/sub-issues)**;
- por fim integrar **GitHub Projects** e automações de status.

A parte de **criar projects por automação pode existir**, mas **não deve ser o gargalo do setup**. O mais importante é o Repo 2 já nascer preparado para:

- backlog estruturado;
- rastreabilidade;
- automação de fluxo;
- futura integração com project e review automático.

---

## 15. Referências observadas

Arquivos usados como base de leitura no Repo 1:

- `README.md`
- `.github/workflows/ci.yaml`
- `.github/workflows/build.yaml`
- `.github/workflows/tests.yaml`
- `.github/workflows/docker-build.yaml`
- `.github/workflows/verify-copilot-contributions.yaml`
- `Makefile`
- `docker-compose.yaml`
- `Dockerfile`
- `infra/README.md`

Arquivo observado no Repo 2:

- `README.md`

