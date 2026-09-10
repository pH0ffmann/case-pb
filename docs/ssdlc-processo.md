# Processo de Desenvolvimento Seguro (SSDLC)

Referência: NIST SSDF (SP 800-218) + OWASP SAMM/ASVS.

## Fase 1 — Requisitos
Requisito de segurança junto do requisito funcional (ex.: dado de cliente exige
criptografia em repouso/trânsito). Classificação de dados já na criação do ticket.

## Fase 2 — Design
Threat modeling leve (STRIDE) obrigatório só para features que tocam autenticação,
autorização, pagamento ou dado sensível — calibrado por risco, não todo ticket.

## Fase 3 — Desenvolvimento
Pre-commit hooks (`.pre-commit-config.yaml`) pegam secrets antes até do commit.
Guidelines de código seguro por linguagem (OWASP Cheat Sheets) no onboarding.

## Fase 4 — Verificação
Gates automatizados do PR: secrets scan, SAST, SCA+SBOM, IaC scan + policy-as-code
(ver `.github/workflows/secure-pipeline.yml`). Code review humano continua
obrigatório — ferramenta não substitui revisão de lógica de negócio/autorização.

## Fase 5 — Release
Container scan + assinatura de artefato (cosign) antes do deploy. DAST em staging.
Checklist de release: gates verdes + exceções de risco aprovadas e com prazo válido.

## Fase 6 — Operação
Monitoramento contínuo de postura em produção (CSPM/DSPM) — configuração de infra
muda depois do deploy também, então o gate de PR não é o fim da história.
Playbook de incidente para: secret vazado, CVE crítica explorada ativamente,
imagem não assinada detectada em produção.

## Por que essa ordem

Threat modeling formal em todo ticket, desde o dia 1, é inviável pra um time sem
processo de segurança prévio — gera resistência e trava entrega. A proposta no
README começa pelos controles automatizados de baixo atrito (pre-commit + gates de
pipeline) e só introduz threat modeling depois que o time já está acostumado a lidar
com achados de segurança no fluxo normal de trabalho.
