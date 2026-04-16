# Backlog Normalization Notes — Take Your Pills

## 1) Fonte canônica consolidada

### Estados de velocidade (oficial)
- Super Lento
- Lento
- Normal
- Rápido
- Super Rápido

### Regras de transição (oficial)
- A cada 3 coletas de aceleração: sobe 1 estado.
- A cada 3 coletas de desaceleração: desce 1 estado.
- Tentar subir acima de **Super Rápido**: derrota por queda/machucado.
- Tentar descer abaixo de **Super Lento**: derrota por sonolência/queda dormindo.

### Multiplicadores (oficial)
- Velocidade:
  - Super Lento: `0.5x`
  - Lento: `0.75x`
  - Normal: `1.0x`
  - Rápido: `1.5x`
  - Super Rápido: `2.0x`
- Cenário:
  - Laboratório: `0.5x`
  - Ruas: `1.0x`
  - Casa: `2.0x`

### Fórmula (oficial)
```text
Pontos finais = Pontos base do coletável × Multiplicador do cenário × Multiplicador da velocidade
```

---

## 2) Regra obrigatória de dependências
- Implementação **não depende** de teste.
- Implementação **não depende** de polish.
- Teste depende de implementação pronta.
- Polish depende de base funcional pronta.

---

## 3) Divergências encontradas e correções aplicadas

### Divergência A — Estados de velocidade (3 vs 5)
- Onde estava divergente:
  - `take_your_pills_project_definitions_update.md` (seção de velocidade com 3 estados)
  - `take_your_pills_issues_detalhados.md` (Issue 04.03 com 3 estados)
- Correção aplicada:
  - Normalizado para 5 estados nos dois documentos.

### Divergência B — Dependência invertida em implementação
- Onde estava divergente:
  - `take_your_pills_issues_detalhados.md` Issue 03.03 dependia de 07.02 (teste).
- Correção aplicada:
  - 03.03 agora depende apenas de 03.01 e 03.02.

### Divergência C — Feature bloqueada por áudio/polish
- Onde estava divergente:
  - Issue 04.05 dependia de 08.01.
  - Issue 08.02 dependia de 08.01.
- Correção aplicada:
  - 04.05 agora depende só de 04.03.
  - 08.02 agora depende de 04.05 e 06.01.

### Divergência D — Critérios de score incompletos/defasados
- Onde estava divergente:
  - Issue 04.04 usava apenas 3 estados de velocidade e multiplicadores incorretos.
- Correção aplicada:
  - Critérios de aceite atualizados para os 5 estados canônicos e multiplicadores oficiais.
