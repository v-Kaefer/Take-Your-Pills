# Planejamento de Estrutura do Repositório — Take Your Pills

## 1. Objetivo deste documento

Este documento define, de forma operacional, a estrutura desejada para o repositório do projeto **Take Your Pills**, considerando o modelo exato de trabalho estabelecido para a disciplina.

A intenção não é apenas descrever boas práticas genéricas, mas orientar a **construção concreta da estrutura do repositório**, incluindo:

- modelo de fases do projeto;
- fluxo de branches e revisões;
- organização do backlog em **User Stories**;
- regras de testes e validação;
- níveis de **Definition of Done (DoD)**;
- organização de issues, sub-issues e GitHub Project;
- checklists detalhadas para implantação.

---

## 2. Premissas centrais

### 2.1 O projeto será construído de forma progressiva
O projeto **não** será tratado como uma única sprint grande de “MVP agora e refinamento depois”.

O desenvolvimento deverá acontecer em **fases progressivas**, alinhadas ao calendário real da disciplina e aos períodos/aulas, com possibilidade de refino posterior.

Cada fase deve conter, internamente:

1. desenvolvimento;
2. teste;
3. refinamento.

Portanto, o MVP deve ser **construído ao longo da matéria**, e não apenas “entregue” em uma etapa isolada no fim.

### 2.2 Todos os 4 membros participam de todas as fases
A estrutura do repositório **não deve assumir donos fixos por área** de forma rígida ou robótica.

O time não será modelado como “uma pessoa de player”, “uma pessoa de UI”, “uma pessoa de systems” e “uma pessoa de integração”.

A intenção correta é:

- os **4 membros** participando de todas as fases;
- todas as fases possuindo colaboração de todo o grupo;
- responsabilidades de revisão e condução sendo organizadas **por fase**, e não por área fixa do projeto.

### 2.3 O modelo-base do backlog será User Story, não épico
A estrutura principal do backlog deve usar:

- **Fases** como unidade de avanço macro;
- **User Stories** como unidade principal de objetivo funcional;
- **Tasks / sub-issues** como unidade de execução.

A hierarquia-base oficial do projeto será:

```text
Fase -> User Story -> Task/Sub-issue -> PR
```

O repositório não deve ser desenhado com “épicos” como centro da operação.

### 2.4 Convenção de idioma adotada
As convenções técnicas do repositório serão mantidas em **inglês** para:

- labels;
- branches;
- workflows;
- scripts.

Para facilitar a operação do time, será permitido manter em **português**:

- nomes de jobs;
- campos dos templates;
- textos de instrução e preenchimento.

### 2.5 Aplicação sem legado
Como nada foi implementado ainda no repositório, a adoção desta estrutura será feita como **aplicação direta do novo modelo**, sem necessidade de migração ou adaptação de estrutura legada.

---

## 3. Modelo de entrega por fase

## 3.1 Definição de fase
Cada fase representa um recorte real do projeto dentro da disciplina, com:

- objetivo concreto final;
- conjunto de User Stories vinculadas;
- tasks executáveis;
- branch específica da fase;
- critérios de revisão;
- DoD da fase.

### 3.2 Estrutura mínima de uma fase
Toda fase deve conter:

- **Objetivo final claro**
- **Escopo incluído**
- **Escopo excluído**
- **User Stories da fase**
- **Tasks da fase**
- **Critérios de teste**
- **Critérios de refinamento**
- **DoD da fase**

### 3.3 Resultado esperado ao final de cada fase
Ao final de cada fase, deve existir uma entrega que seja:

- funcional no contexto daquela fase;
- validada por testes compatíveis com o que foi implementado;
- refinada minimamente dentro do objetivo definido;
- pronta para integração em `develop`.

---

## 4. Fluxo de branches e revisões

## 4.1 Branches principais
A estrutura do repositório deve considerar, no mínimo:

- `main` → branch de versão mais estável e pronta para entrega macro;
- `develop` → branch de integração contínua do projeto;
- `phase/<nome-da-fase>` → branch dedicada a cada fase ativa;
- `task/<fase>/<nome-da-task>` ou `feat/<fase>/<nome-da-task>` → branch de implementação de cada task.

### 4.2 Regra operacional por fase
Para cada fase:

1. cria-se uma **branch própria da fase**;
2. as tasks dessa fase saem em branches de trabalho individuais;
3. cada task abre **PR para a branch da fase**;
4. depois de consolidada, a branch da fase abre **PR para `develop`**;
5. quando apropriado, `develop` abre **PR para `main`**.

### 4.3 Revisão de PRs das tasks para a branch da fase
Cada fase terá **2 responsáveis da fase**.

Esses 2 responsáveis:

- não são “donos da fase” no sentido de exclusividade;
- continuam participando junto com os demais;
- atuam como referência principal de revisão dos PRs das tasks daquela fase.

#### Regra de aprovação
PRs de task para a branch da fase devem ser revisados pelos **2 responsáveis da fase**, ou pelo menos obedecer à política definida para essa camada.

### 4.4 Revisão do PR da branch da fase para `develop`
Quando a branch da fase abrir PR para `develop`, a regra desejada é:

- aprovação dos **outros 2 membros**;
- mais **pelo menos 1 dos 2 responsáveis da fase**.

Isso garante que:

- quem acompanhou a fase de perto valide a consolidação;
- quem não era responsável direto também valide a integração.

### 4.5 Revisão do PR de `develop` para `main`
Para merge de `develop` em `main`, a regra desejada é:

- **aprovação dos 4 membros**.

Esta é a camada de revisão mais forte do projeto.

### 4.6 Consequência para a estrutura do repositório
A estrutura do repositório deve ser preparada para suportar:

- proteção de branches;
- exigência de reviewers mínimos;
- política clara de PR por camada;
- rastreabilidade de qual fase e qual User Story aquele PR atende.

---

## 5. Modelo de backlog

## 5.1 Hierarquia adotada
A hierarquia recomendada para o repositório será:

```text
Fase
└── User Stories
    └── Tasks / Sub-issues
        └── PRs / Commits
```

### 5.2 O que uma User Story deve conter
Cada User Story deve conter no mínimo:

- título claro;
- contexto funcional;
- descrição do valor entregue;
- critérios de aceite;
- dependências;
- fase associada;
- estratégia de teste;
- DoD da story.

### 5.3 O que uma task / sub-issue deve conter
Cada task ou sub-issue deve conter no mínimo:

- objetivo técnico claro;
- escopo exato;
- critérios de conclusão observáveis;
- vínculo com a User Story pai;
- expectativa de teste;
- evidência esperada;
- DoD da task.

### 5.4 O que não deve acontecer
Não devem existir itens vagos como:

- “fazer HUD”;
- “mexer na fase”;
- “melhorar score”;
- “ajustar player”;
- “refinar gameplay”.

Toda User Story e toda task devem permitir que qualquer membro compreenda:

- o que será feito;
- por que será feito;
- como validar que ficou pronto.

---

## 6. Política de testes

## 6.1 Princípio geral
Nenhuma implementação deve entrar apenas como “código feito”.

Toda implementação precisa vir acompanhada de **evidência de validação**.

### 6.2 Regra desejada por commit
A intenção declarada para o projeto é:

> cada commit deve trazer o teste referente ao que foi implementado.

Para tornar essa regra operacional sem perder o espírito do que foi definido, a estrutura do repositório deve considerar três formas de validação aceitáveis, nesta ordem de prioridade:

1. **teste automatizado**;
2. **smoke test executável / validável**;
3. **teste manual documentado e reproduzível**, quando automação ainda não for viável.

### 6.3 Automação em Godot
Se houver ferramenta viável para testes automatizados no ecossistema Godot, ela deve ser integrada ao repositório.

Essa integração deve priorizar, sempre que possível:

- regras de lógica;
- cálculos;
- transições de estado;
- persistência local;
- fluxo de cena controlável;
- comportamento determinístico.

### 6.4 Regra prática para revisão
Nenhum PR deve ser aceito sem deixar explícito:

- qual teste foi feito;
- que tipo de teste foi usado;
- qual evidência comprova a validação.

### 6.5 Tipos de evidência aceitos
O repositório deve prever espaço para registrar, por PR ou por task:

- nome do teste automatizado;
- comando executado;
- checklist manual executado;
- vídeo/gif/screenshot, quando fizer sentido;
- observações de limitação do teste.

### 6.6 Estratégia operacional de validação
A estratégia oficial de validação do projeto será:

- no **`pre-push`**: checks rápidos e baratos;
- no **CI**: checks mais completos;
- **QA manual**: fora do `pre-push`, como etapa humana de validação qualitativa.

### 6.7 Checks iniciais obrigatórios
Na ativação gradual da governança, os primeiros checks obrigatórios serão:

- branch naming;
- PR template/link;
- repo quality básico;
- Godot smoke check.

---

## 7. Definition of Done em múltiplas camadas

## 7.1 DoD da task
Uma task só é considerada pronta quando:

- o escopo definido foi implementado;
- a task continua restrita ao que foi prometido;
- existe teste compatível com a mudança;
- existe evidência de validação;
- a task foi revisada na camada correta;
- não introduz quebra conhecida no fluxo atual.

## 7.2 DoD da User Story
Uma User Story só é considerada pronta quando:

- todas as tasks vinculadas foram concluídas;
- os critérios de aceite da story foram atendidos;
- o comportamento esperado está visível no projeto;
- a validação da story está registrada;
- o resultado está integrado à branch da fase.

## 7.3 DoD da fase
Cada fase deve possuir uma DoD própria. No mínimo, a DoD da fase deve exigir:

- objetivo final da fase atingido;
- User Stories planejadas para a fase concluídas ou justificadamente replanejadas;
- testes executados e registrados;
- refinamentos mínimos da fase aplicados;
- branch da fase pronta para abrir PR para `develop`;
- pendências conhecidas registradas com clareza.

## 7.4 DoD do PR para a branch da fase
Um PR de task para a branch da fase só deve ser elegível a merge quando:

- a task vinculada estiver corretamente identificada;
- os testes estiverem descritos;
- a evidência de validação estiver anexada ou referenciada;
- o diff estiver coerente com a task;
- os responsáveis da fase tiverem revisado conforme a política definida.

## 7.5 DoD do PR da fase para `develop`
O PR da fase para `develop` só deve ser elegível a merge quando:

- a DoD da fase estiver cumprida;
- as User Stories da fase estiverem rastreáveis;
- os outros 2 membros tiverem aprovado;
- pelo menos 1 dos 2 responsáveis da fase tiver aprovado;
- a integração em `develop` estiver pronta.

## 7.6 DoD do PR de `develop` para `main`
O PR de `develop` para `main` só deve ser elegível a merge quando:

- o incremento estiver estável;
- os 4 membros tiverem aprovado;
- a entrega estiver adequada ao objetivo macro do período;
- os riscos conhecidos estiverem documentados.

## 7.7 Handoff operacional
Além da DoD, o projeto adotará prática formal de **handoff** sempre que uma task, story ou fase mudar de mãos ou exigir continuidade por outra pessoa.

O handoff deve registrar, no mínimo:

- o que funciona;
- o que falta;
- problemas conhecidos;
- próximo passo sugerido.

A DoD continua definindo quando algo está pronto. O handoff existe para garantir continuidade e reduzir perda de contexto antes da conclusão.

---

## 8. Estrutura de GitHub recomendada

## 8.1 O que deve existir no repositório
A estrutura recomendada deve prever, no mínimo:

```text
.github/
  ISSUE_TEMPLATE/
  workflows/
  pull_request_template.md
  CODEOWNERS                # opcional / complementar, não como eixo principal
  labels.yml ou labels.json
  phase-review-policy.json  # configuração da política por fase

docs/
  repo/
  phases/
  stories/

scripts/
  github/
  validation/

config/
  phases/
  stories/
  project/
```

### 8.2 Observação sobre CODEOWNERS
Como o modelo **não** é centrado em donos fixos por área, `CODEOWNERS` não deve ser tratado como o mecanismo principal de governança.

Ele pode existir de forma complementar para:

- caminhos críticos do repositório;
- proteção de arquivos de governança;
- fallback técnico.

Mas o eixo principal deve ser:

- fase;
- User Story;
- PR template;
- metadata da task;
- política de revisão configurada para cada camada.

---

## 9. Templates de issues e PRs

## 9.1 Templates recomendados de issue
O repositório deve ter, no mínimo, templates para:

- **User Story**;
- **Task / Sub-issue**;
- **Bug Report**;
- **Phase Setup / Phase Planning**, se desejado.

### 9.2 Campos obrigatórios da User Story
Template de User Story deve exigir:

- resumo da funcionalidade;
- valor para o jogo/projeto;
- fase associada;
- critérios de aceite;
- dependências;
- estratégia de teste;
- DoD da story.

### 9.3 Campos obrigatórios da task / sub-issue
Template de task deve exigir:

- descrição objetiva;
- story associada;
- escopo técnico;
- testes esperados;
- evidência esperada;
- DoD da task.

### 9.4 Template de PR
O template de PR deve exigir:

- issue/story/task vinculada;
- fase associada;
- resumo do que foi implementado;
- como testar;
- evidência anexada;
- riscos conhecidos;
- checklist de DoD correspondente.

---

## 10. GitHub Project recomendado

## 10.1 Papel do Project
O GitHub Project deve servir como painel operacional do time, e não apenas como lista visual de tarefas.

Ele deve permitir enxergar:

- fase atual;
- User Stories da fase;
- tasks abertas e concluídas;
- camada de revisão em que cada item está;
- estado de teste/validação;
- bloqueios;
- pronto para integração em fase / develop / main.

### 10.2 Campos recomendados no Project
Campos sugeridos:

- `Phase`
- `Item Type` (`user-story`, `task`, `bug`, `phase-support`)
- `Status`
- `Priority`
- `Review Layer`
- `Test Type`
- `DoD Status`
- `Responsible Pair`
- `Target Branch`

### 10.3 Status recomendados
Exemplo de status:

- `Planned`
- `Ready`
- `In Progress`
- `In Review (Task -> Phase)`
- `In Review (Phase -> Develop)`
- `In Review (Develop -> Main)`
- `Blocked`
- `Validated`
- `Done`

---

## 11. Estratégia de automação

## 11.1 O que pode ser automatizado
O repositório deve ser preparado para automação de:

- criação de User Stories e tasks a partir de manifesto;
- sincronização de labels;
- labeler automático com actions;
- validação de branch naming;
- validação de PR template;
- verificação de vínculo PR ↔ issue;
- verificação de presença de teste/evidência;
- geração de estrutura inicial do Project;
- review automático em toda PR aberta ou atualizada.

### 11.2 Review automático por PR
Cada PR aberta, reaberta ou atualizada deverá receber validação automática com foco em:

- resumo do que foi adicionado;
- indicação se a mudança está quebrada;
- indicação de risco de quebrar outra parte do projeto;
- verificação de aderência ao padrão estabelecido.

A saída recomendada para essa automação é um comentário ou resumo estruturado na PR, consolidando:

- escopo alterado;
- checks executados;
- riscos detectados;
- conformidade com o padrão do repositório;
- pendências de correção.

### 11.3 O que deve continuar manual
O **QA** permanecerá como etapa manual do processo.

Devem continuar humanos e não automatizados os julgamentos ligados a:

- qualidade de gameplay;
- UX e legibilidade;
- balanceamento;
- avaliação qualitativa da fase;
- aceite final de QA.

### 11.4 O que deve ser tratado com cuidado
A automação não deve se tornar mais complexa do que o processo real do time.

Logo:

- a política de revisão por fase deve ser explícita e auditável;
- os workflows devem validar metadados antes de escrever na PR;
- cada parte do workflow deve ser modular e segmentada, mas integrada a uma build (como dependência);
- scripts devem priorizar previsibilidade e rastreabilidade.

---

## 12. Modelo de labels recomendado

## 12.1 Categorias mínimas
O repositório deve ter labels separadas por categoria:

### Tipo
- `type:user-story`
- `type:task`
- `type:bug`
- `type:phase-support`

### Fase
- `phase:1`
- `phase:2`
- `phase:3`
- `phase:4`
- etc., conforme o planejamento real

### Prioridade
- `priority:high`
- `priority:medium`
- `priority:low`

### Estado
- `status:blocked`
- `status:needs-review`
- `status:validated`
- `status:ready-for-phase-merge`
- `status:ready-for-develop`
- `status:ready-for-main`

### Teste
- `test:automated`
- `test:smoke`
- `test:manual`

---

## 13. Estrutura documental recomendada

## 13.1 Documentos do repositório
O repositório deve centralizar documentação suficiente para que qualquer membro compreenda o processo sem depender de contexto implícito. A documentação deve estar disponível em Português Brasileiro e Inglês.

Documentos recomendados:

- `docs/repo/branching-policy.md`
- `docs/repo/review-policy.md`
- `docs/repo/testing-policy.md`
- `docs/repo/dod-policy.md`
- `docs/repo/project-board-policy.md`
- `docs/phases/phase-01.md`, `phase-02.md`, etc.
- `docs/stories/story-index.md`

### 13.2 O que cada fase deve documentar
Cada documento de fase deve conter:

- objetivo da fase;
- User Stories da fase;
- Tasks/Issues pai da fase/user stories;
- critérios de teste da fase;
- DoD da fase;
- riscos conhecidos;
- saída esperada para `develop`.

---

## 14. Checklist detalhada para construir a estrutura do repositório

## Etapa 0 — Alinhamento do modelo
- [ ] Confirmar oficialmente que o projeto será organizado por **fases + User Stories + tasks**, e não por épicos.
- [ ] Definir a lista real de fases do projeto conforme o cronograma da disciplina.
- [ ] Definir, para cada fase, qual é o objetivo final concreto esperado.
- [ ] Definir se os 2 responsáveis de fase serão fixos por fase ou rotativos ao longo do projeto.
- [ ] Consolidar por escrito a regra de revisão em três camadas: `task -> phase`, `phase -> develop`, `develop -> main`.
- [ ] Formalizar que todos os 4 membros participam de todas as fases.
- [ ] Registrar oficialmente a hierarquia-base: `Fase -> User Story -> Task/Sub-issue -> PR`.
- [ ] Registrar oficialmente que a branch de integração do projeto será `develop`.

## Etapa 1 — Estruturar a governança básica do repositório
- [ ] Criar a pasta `.github/` com a organização-base.
- [ ] Criar o template de PR exigindo vínculo com fase, story/task, teste e evidência.
- [ ] Criar documento de política de branches.
- [ ] Criar documento de política de revisão.
- [ ] Criar documento de política de testes.
- [ ] Criar documento de política de DoD.
- [ ] Garantir que a documentação-base do repositório exista em Português Brasileiro e Inglês.
- [ ] Formalizar que labels, branches, workflows e scripts ficam em inglês, enquanto jobs e campos de templates podem ficar em português.
- [ ] Decidir se `CODEOWNERS` será usado apenas como apoio para arquivos críticos.

## Etapa 2 — Estruturar o modelo de backlog
- [ ] Criar template de **User Story**.
- [ ] Criar template de **Task / Sub-issue**.
- [ ] Criar template de **Bug Report**.
- [ ] Definir o formato padrão de escrita das User Stories.
- [ ] Definir o formato padrão de escrita das tasks.
- [ ] Garantir que cada template exija critérios de aceite.
- [ ] Garantir que cada template exija estratégia de teste.
- [ ] Garantir que cada template exija DoD.

## Etapa 3 — Preparar a estrutura de fases
- [ ] Criar um documento para cada fase planejada.
- [ ] Registrar objetivo final da fase.
- [ ] Registrar escopo incluído e excluído da fase.
- [ ] Registrar User Stories previstas para a fase.
- [ ] Registrar Tasks/Issues pai relacionadas à fase e às User Stories.
- [ ] Registrar a DoD específica da fase.
- [ ] Registrar a política de saída da fase para `develop`.

## Etapa 4 — Preparar o GitHub Project
- [ ] Criar o Project como painel operacional do time.
- [ ] Adicionar campo `Phase`.
- [ ] Adicionar campo `Item Type`.
- [ ] Adicionar campo `Status`.
- [ ] Adicionar campo `Review Layer`.
- [ ] Adicionar campo `Test Type`.
- [ ] Adicionar campo `DoD Status`.
- [ ] Adicionar campo `Responsible Pair`.
- [ ] Adicionar campo `Target Branch`.
- [ ] Criar visualizações por fase, por status e por camada de revisão.

## Etapa 5 — Preparar a taxonomia de labels
- [ ] Criar labels de tipo.
- [ ] Criar labels de fase.
- [ ] Criar labels de prioridade.
- [ ] Criar labels de estado.
- [ ] Criar labels de teste.
- [ ] Versionar a definição dessas labels em arquivo do repositório.
- [ ] Preparar sincronização manual ou automatizada das labels.
- [ ] Preparar labeler automático com GitHub Actions, quando o fluxo justificar.

## Etapa 6 — Preparar a estratégia de testes
- [ ] Pesquisar e selecionar a melhor abordagem de teste para Godot no projeto.
- [ ] Definir quais tipos de mudança exigem teste automatizado obrigatório.
- [ ] Definir quais mudanças aceitam smoke test.
- [ ] Definir quais mudanças aceitam teste manual documentado como fallback.
- [ ] Criar padrão de evidência de teste no PR.
- [ ] Criar checklist mínima de validação por PR.
- [ ] Formalizar a separação: `pre-push` rápido, CI completo e QA manual fora do `pre-push`.
- [ ] Preparar workflow para verificar presença de metadados de teste nas PRs.
- [ ] Definir os checks iniciais obrigatórios: branch naming, PR template/link, repo quality básico e Godot smoke check.

## Etapa 7 — Preparar o fluxo de branches e proteção
- [ ] Definir padrão de nome para branches de fase.
- [ ] Definir padrão de nome para branches de task.
- [ ] Configurar proteção em `main`.
- [ ] Configurar proteção em `develop`.
- [ ] Definir política operacional da branch da fase.
- [ ] Definir como os reviewers serão identificados por fase.
- [ ] Garantir que PRs para `main` exijam aprovação dos 4 membros.
- [ ] Garantir que PRs de fase para `develop` respeitem a regra dos outros 2 + pelo menos 1 responsável.
- [ ] Definir e documentar a política de handoff para continuidade entre integrantes.

## Etapa 8 — Preparar automações mínimas
- [ ] Criar workflow de validação de branch naming.
- [ ] Criar workflow de validação de PR template.
- [ ] Criar workflow de validação de vínculo PR ↔ issue/task.
- [ ] Criar workflow de validação da presença de teste/evidência no PR.
- [ ] Criar workflow de review automático por PR com resumo, checks, riscos e aderência ao padrão.
- [ ] Garantir que os workflows sejam modulares e segmentados, mas integrados a uma build/orquestração principal como dependência.
- [ ] Criar script para sincronizar labels.
- [ ] Criar script ou manifesto para gerar User Stories e tasks em lote.
- [ ] Planejar automação do Project apenas depois que a governança básica estiver estável.

## Etapa 9 — Preparar a geração de issues e sub-issues
- [ ] Definir um schema versionado para manifestos de User Stories e tasks.
- [ ] Criar arquivos de manifesto por fase.
- [ ] Garantir que cada item gerado tenha título, descrição, critérios de aceite, teste e DoD.
- [ ] Garantir que tasks sejam vinculadas corretamente à User Story correspondente.
- [ ] Garantir que bugs tenham fluxo separado das User Stories.
- [ ] Fazer validação em modo dry-run antes de criar itens reais.
- [ ] Registrar que, como não há legado implementado, a adoção do novo modelo será aplicada diretamente sem etapa de migração.

## Etapa 10 — Validar o processo completo em piloto
- [ ] Escolher uma fase piloto para testar o fluxo completo.
- [ ] Criar a branch da fase piloto.
- [ ] Gerar User Stories e tasks dessa fase.
- [ ] Abrir PRs simulando task -> phase.
- [ ] Validar o fluxo de revisão dos responsáveis da fase.
- [ ] Validar o PR phase -> develop.
- [ ] Validar o PR develop -> main.
- [ ] Ajustar templates, labels, workflows e documentação antes de expandir para todas as fases.

---

## 15. Ordem recomendada de implantação

A ordem recomendada para montar essa estrutura é:

1. alinhar o modelo de fases e revisão;
2. documentar políticas de branches, revisão, testes e DoD;
3. criar templates de User Story, task e PR;
4. montar labels e Project;
5. definir a estrutura documental das fases;
6. configurar proteções de branch;
7. adicionar automações mínimas de validação;
8. só então automatizar geração em lote de issues/sub-issues e integração mais profunda com o Project.

---

## 16. Diretriz final

Se houver dúvida entre:

- uma estrutura mais complexa e “inteligente”, ou
- uma estrutura mais simples, previsível e bem auditável,

a decisão padrão deve ser:

> preferir a estrutura mais clara, mais rastreável e mais compatível com a rotina real do grupo.

O repositório será considerado bem estruturado quando conseguir sustentar, sem ambiguidade:

- fases progressivas com objetivo concreto;
- User Stories claras;
- tasks testáveis;
- DoD por camada;
- revisão em múltiplos níveis;
- integração confiável entre `phase`, `develop` e `main`.
