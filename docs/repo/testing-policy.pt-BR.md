# Política de Testes (PT-BR)

## Ordem de prioridade
1. Teste automatizado
2. Smoke test
3. Teste manual documentado (fallback)

## Stack Godot
- Framework preferencial: GDUnit4.
- Os testes de jogo em CI rodam via um workflow GdUnit4 em PRs que alteram código do jogo.
- Os smoke checks rápidos continuam separados para pegar falhas de boot do projeto cedo.

## Estratégia de validação
- pre-push: auditoria de arquivos alterados + checks de sintaxe direcionados
- CI: checks mais completos
- QA manual: validação qualitativa
