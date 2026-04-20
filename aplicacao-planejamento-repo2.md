# Aplicação do planejamento no Repo 2 (`v-Kaefer/Take-Your-Pills`)

## 1. Diagnóstico atual do Repo 2

Pelo que foi possível inspecionar diretamente no repositório, o Repo 2 hoje aparenta estar em um estado **bem inicial**, com foco de base ainda pequena.

### Evidências observadas
- `README.md` descreve o projeto como um **jogo infinity runner, side-scroller**.
- `.gitignore` é claramente orientado a **Godot 4+**.
- Não encontrei workflows já prontos em `.github/workflows/` nas verificações iniciais.
- O repositório parece estar em um ponto muito bom para receber uma base de automação sem precisar refatorar uma estrutura já complexa.

## Conclusão prática
A melhor forma de aplicar o planejamento no Repo 2 **não é tentar portar o modelo do Repo 1 inteiro de uma vez**, e sim fazer uma adaptação por camadas, respeitando o fato de que:

1. o Repo 2 é um projeto **Godot**;
2. ele ainda parece **leve e limpo**;
3. as automações de gestão e governança vão gerar valor antes mesmo do CI completo do jogo.

---

## 2. Melhor estratégia de aplicação

## 2.1. Ordem ideal

### Etapa 1 — Fundar a governança do repositório
Entram primeiro os arquivos que definem como o repositório será usado:

- `CODEOWNERS`
- templates de issue
- template de PR
- labels versionadas
- documentação de governança
- scripts de bootstrap de labels

### Etapa 2 — Ativar CI genérico de repositório
Antes de buildar o jogo, ativar checagens que já funcionam agora:

- `actionlint`
- `yamllint`
- `markdownlint`
- `shellcheck`
- validação dos arquivos de configuração da automação

### Etapa 3 — Ativar automação de backlog
Depois da base de governança:

- criação de issues
- criação de sub-issues
- criação de árvore de épico
- integração com project

### Etapa 4 — Ativar CI específico de Godot
Só quando a estrutura do projeto Godot estiver claramente assentada:

- detectar `project.godot`
- importar assets em headless
- validar export presets
- gerar build/export
- publicar artifact de teste

---

## 3. O que do plano anterior entra agora, e o que entra depois

## 3.1. Entra agora

### Arquivos de governança
- `.github/CODEOWNERS`
- `.github/pull_request_template.md`
- `.github/ISSUE_TEMPLATE/epic.yml`
- `.github/ISSUE_TEMPLATE/feature_request.yml`
- `.github/ISSUE_TEMPLATE/task.yml`
- `.github/ISSUE_TEMPLATE/bug_report.yml`
- `.github/labels.yml`

### Workflows que já geram valor
- `.github/workflows/ci.yml`
- `.github/workflows/repo-quality.yml`
- `.github/workflows/governance-checks.yml`

### Scripts que já valem a pena
- `scripts/github/bootstrap-labels.sh`
- `scripts/github/create-issue.sh`
- `scripts/github/create-subissue.sh`
- `scripts/github/create-issue-tree.sh`

### Documentação
- `docs/repository-governance.md`
- `docs/workflow-map.md`
- `docs/automation-runbook.md`

## 3.2. Entra depois

### Integração com Projects
- `scripts/github/create-project.sh`
- `scripts/github/seed-project.sh`
- `.github/workflows/project-sync.yml`
- `.github/project/fields.json`

### CI específico do Godot
- workflow de validação/import do projeto
- workflow de export/build
- workflow de release artifact

---

## 4. Adaptação correta do modelo do Repo 1 para o Repo 2

## 4.1. O padrão do Repo 1 que vale manter

Do Repo 1, o que vale preservar é a **arquitetura mental**:

- um workflow principal pequeno;
- workflows especializados e reaproveitáveis;
- operação guiada por arquivos versionados;
- governança explícita;
- crescimento por etapas.

## 4.2. O que deve ser removido na adaptação

No Repo 2, não faz sentido trazer agora:

- Docker build do backend;
- Terraform/LocalStack;
- Cognito/local auth;
- validação OpenAPI;
- Makefile com operação de stack backend.

## 4.3. O equivalente certo para o Repo 2

### Equivalência prática
- `ci.yaml` do Repo 1 → `ci.yml` no Repo 2
- `build/tests/docker-build` do Repo 1 → `repo-quality` + `governance-checks` agora, `godot-verify` depois
- `verify-copilot-contributions` do Repo 1 → opcionalmente `verify-ai-contributions` no Repo 2
- `Makefile` do Repo 1 → scripts GitHub focados em backlog/governança

---

## 5. Melhor desenho de workflows para o Repo 2

## 5.1. `ci.yml`

### Papel
Orquestrar o restante.

### Gatilhos
- `push`
- `pull_request`

### Inicialmente chama
- `repo-quality.yml`
- `governance-checks.yml`

### Depois passa a chamar também
- `godot-verify.yml`
- `project-sync.yml` quando apropriado

---

## 5.2. `repo-quality.yml`

### Papel
Validar a qualidade dos arquivos do próprio repositório.

### Deve checar
- YAML
- Markdown
- shell scripts
- arquivos de configuração de issue/labels
- consistência da pasta `.github/`

### Motivo
Esse workflow gera valor já no primeiro commit de automação.

---

## 5.3. `governance-checks.yml`

### Papel
Validar se PRs e branches obedecem o modelo de trabalho do repositório.

### Deve validar
- branch naming
- PR com issue associada
- template de PR preenchido
- labels esperadas
- arquivos de governança presentes

### Motivo
É ele que transforma o repo em um ambiente organizado, não só “com arquivos de automação”.

---

## 5.4. `godot-verify.yml` (fase posterior)

### Papel
Ser o primeiro workflow realmente ligado ao jogo.

### Só deve entrar quando
- o projeto Godot estiver assentado;
- `project.godot` estiver presente no caminho final adotado;
- existirem cenas/scripts/assets que façam sentido validar.

### O que ele deve fazer
- abrir/importar o projeto em modo headless;
- validar estrutura mínima;
- opcionalmente executar export de teste;
- publicar artifact.

### Observação importante
Como eu não confirmei a presença do `project.godot` por inspeção direta até aqui, **não recomendo ativar esse workflow logo no primeiro pacote de automações**. Ele deve entrar como fase 2 técnica.

---

## 6. Melhor forma de tratar backlog e sub-issues no Repo 2

Como o projeto é um jogo, a estrutura de backlog precisa refletir isso. O ideal não é usar apenas “tarefas soltas”, e sim uma hierarquia previsível.

## 6.1. Modelo recomendado

### Nível 1 — Épico
Exemplos:
- `Epic: Vertical Slice`
- `Epic: Core Gameplay`
- `Epic: UI Base`
- `Epic: Art Direction`
- `Epic: Audio Base`

### Nível 2 — Feature
Exemplos:
- `Feature: movimento do player`
- `Feature: sistema de obstáculos`
- `Feature: HUD inicial`
- `Feature: spawn manager`

### Nível 3 — Task/Sub-issue
Exemplos:
- `Task: ajustar colisão do player`
- `Task: criar layout provisório da HUD`
- `Task: definir placeholder do cenário`

## 6.2. Consequência prática
Isso torna o script `create-issue-tree.sh` muito mais importante do que o `create-issue.sh` isolado.

Para o Repo 2, o fluxo ideal é:

1. descrever um épico em YAML;
2. gerar a árvore inteira por script;
3. adicionar tudo ao project;
4. deixar as automações refletirem os status.

---

## 7. Projects: melhor forma de aplicar no Repo 2

## 7.1. Melhor abordagem

Para esse repositório, eu recomendo:

### Primeiro
Criar e estruturar o backlog por labels + issues + sub-issues.

### Depois
Criar um único GitHub Project principal, por exemplo:
- `Take Your Pills – Development`

### Campos sugeridos
- `Status`
- `Type`
- `Priority`
- `Area`
- `Sprint`

### Status sugeridos
- `Backlog`
- `Ready`
- `In Progress`
- `In Review`
- `Blocked`
- `Done`

## 7.2. Motivo
Para um repo ainda em fase inicial, o risco é gastar energia demais automatizando Projects antes de estabilizar os tipos de issue e a taxonomia do trabalho.

No Repo 2, a ordem correta é:

1. labels;
2. issue templates;
3. scripts de criação;
4. backlog real;
5. project sync.

---

## 8. Melhor pacote inicial para aplicar agora no Repo 2

Se o objetivo for aplicar o planejamento da forma mais eficiente possível, eu faria o primeiro pacote exatamente assim:

## Pacote 1 — Fundação
1. `.github/CODEOWNERS`
2. `.github/pull_request_template.md`
3. `.github/labels.yml`
4. `.github/ISSUE_TEMPLATE/*.yml`
5. `.github/workflows/ci.yml`
6. `.github/workflows/repo-quality.yml`
7. `.github/workflows/governance-checks.yml`
8. `scripts/github/bootstrap-labels.sh`
9. `scripts/github/create-issue.sh`
10. `scripts/github/create-subissue.sh`
11. `scripts/github/create-issue-tree.sh`
12. `docs/repository-governance.md`

### Resultado esperado do Pacote 1
O Repo 2 passa a ter:
- processo padronizado;
- backlog estruturável;
- automação de qualidade de configuração;
- base limpa para crescer.

---

## Pacote 2 — Planejamento operacional
1. `config/issues/roadmap.yml`
2. `config/issues/vertical-slice.yml`
3. criação do backlog inicial por script
4. padronização de labels/áreas/prioridades

### Resultado esperado do Pacote 2
O backlog do jogo deixa de ser manual e passa a ser reproduzível.

---

## Pacote 3 — Projects
1. `scripts/github/create-project.sh`
2. `scripts/github/seed-project.sh`
3. `.github/project/fields.json`
4. `.github/workflows/project-sync.yml`

### Resultado esperado do Pacote 3
Issues e PRs passam a atualizar o quadro automaticamente.

---

## Pacote 4 — Godot CI
1. `.github/workflows/godot-verify.yml`
2. `.github/workflows/godot-export.yml`
3. artifacts de export
4. release pipeline

### Resultado esperado do Pacote 4
O repo ganha CI/CD técnico do jogo, não apenas governança.

---

## 9. Recomendação final

A melhor forma de aplicar o planejamento no Repo 2 é esta:

### Primeiro
Transformar o repositório em uma **base de governança, backlog e automação de fluxo**.

### Depois
Acoplar GitHub Projects.

### Só então
Acoplar CI específico de Godot.

Esse é o caminho mais seguro porque:

- respeita o estado atual e enxuto do Repo 2;
- evita importar complexidade desnecessária do Repo 1;
- prioriza o que já gera valor agora;
- prepara o repo para crescer sem retrabalho.

---

## 10. Resumo objetivo

Hoje, para o Repo 2, a melhor aplicação do planejamento é:

- **adotar agora** governança + scripts de issues/sub-issues + CI genérico de repositório;
- **postergar um pouco** project sync total até a taxonomia de backlog estar estável;
- **postergar o CI técnico de Godot** até a estrutura do projeto estar claramente consolidada.

Em outras palavras: **o primeiro passo correto não é buildar o jogo no CI; é estruturar como o projeto vai ser organizado e evoluído dentro do GitHub**.
