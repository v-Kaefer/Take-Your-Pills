# Checklist consolidada — implementações planejadas

> Status inicial: **nenhuma implementação executada nesta checklist**.

## Fase A — Fundação técnica
- [ ] 01.01 — Congelar escopo do projeto
- [ ] 01.02 — Definir regras oficiais de pontuação
- [ ] 01.03 — Definir os 4 coletáveis iniciais
- [ ] 01.04 — Definir convenções de repositório
- [ ] 02.01 — Estruturar projeto Godot
- [ ] 02.02 — Configurar scripts de verificação antes do push
- [ ] 02.03 — Integrar pipeline de review automático (planejamento + implementação base em Fase A)
- [ ] 03.01 — Implementar corrida automática
- [ ] 03.02 — Implementar pulo
- [ ] 03.03 — Implementar colisão e derrota
- [ ] 03.04 — Implementar reinício rápido
- [ ] 04.01 — Implementar score e distância

## Fase B — MVP jogável
- [ ] 04.02 — Implementar sistema genérico de coletáveis
- [ ] 04.03 — Implementar máquina de estados de velocidade (5 estados canônicos)
- [ ] 04.04 — Implementar multiplicadores de score (cenário + velocidade)
- [ ] 04.05 — Implementar feedback de estado de velocidade
- [ ] 05.01 — Implementar laboratório
- [ ] 05.02 — Implementar ruas
- [ ] 05.03 — Implementar transição laboratório → ruas
- [ ] 06.01 — Implementar HUD

## Fase C — MVP completo
- [ ] 05.04 — Implementar casa temporária
- [ ] 05.05 — Implementar entrada e saída da casa
- [ ] 06.02 — Implementar menu inicial, pausa e game over
- [ ] 06.03 — Implementar ranking local
- [ ] 07.01 — Definir suíte de testes automatizados

## Fase D — Qualidade e playtesting
- [ ] 07.02 — Implementar testes automatizados críticos
- [ ] 07.03 — Montar checklist de testes manuais

## Fase E — Refinamento
- [ ] 08.01 — Integrar áudio funcional
- [ ] 08.02 — Integrar VFX leves e melhoria de legibilidade

## Fase F — Entrega final
- [ ] 08.03 — Balancear dificuldade e ritmo
- [ ] 08.04 — Fechar build final e material de apresentação

---

## Regras de dependência (aplicáveis a toda a checklist)
- [ ] Implementação não depende de teste/polish
- [ ] Teste depende de implementação
- [ ] Polish depende de base funcional
