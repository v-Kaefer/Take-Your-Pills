# Política de Testes (PT-BR)

## Ordem de prioridade
1. Teste automatizado
2. Smoke test
3. Teste manual documentado (fallback)

## Stack Godot
- Framework preferencial: GDUnit4.

## Estratégia de validação
- pre-push: auditoria de arquivos alterados + checks de sintaxe direcionados
- CI: checks mais completos
- QA manual: validação qualitativa
