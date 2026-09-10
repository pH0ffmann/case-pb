# Secure SDLC & DevSecOps — Proposta de Implantação

> Case técnico — proposta prática de segurança embutida desde o início do ciclo de
> desenvolvimento (shift-left), não como etapa pós-deploy.

## Cenário

Aplicação web crítica, múltiplos times, sem processo formal de segurança hoje.
Vulnerabilidades só aparecem em produção.

## Aplicação alvo desta demonstração

Em vez de escrever uma aplicação vulnerável do zero, este repositório usa o
**[PyGoat](https://github.com/adeyosemanputra/pygoat)** — projeto listado no catálogo oficial de aplicações vulneráveis da OWASP (OWASP VWAD), aplicação
Django intencionalmente vulnerável ao OWASP Top 10, usada aqui só como alvo para
os gates do pipeline demonstrarem detecção real (não simulada).

```bash
git clone https://github.com/adeyosemanputra/pygoat.git target-app
```

O pipeline deste repo (`.github/workflows/secure-pipeline.yml`) assume que o código da
aplicação está em `target-app/`.

## Mapa da proposta

| Ponto exigido pelo case | Onde está neste repo |
|---|---|
| 1. Governança e gestão dos repositórios | `.github/CODEOWNERS`, seção "Governança" abaixo |
| 2. Processo de desenvolvimento seguro (SSDLC) | `docs/ssdlc-processo.md` |
| 3. Controles de segurança no pipeline CI/CD | `.github/workflows/secure-pipeline.yml`, `.pre-commit-config.yaml` |
| 4. Gestão de vulnerabilidades e riscos | `SECURITY.md` |
| 5. Proteção de branches | `branch-protection/apply-branch-protection.sh` |
| 6. Gestão de segredos | `terraform/example-oidc/main.tf` + seção secrets do `SECURITY.md` |

## 1. Governança e gestão de repositórios

- Template padrão de repositório (README + CODEOWNERS + SECURITY.md obrigatórios).
- Classificação de criticidade do repositório (crítico/alto/médio) — define quais gates
  do pipeline são bloqueantes vs informativos.
- Acesso por RBAC via time/squad, revisão trimestral de quem tem admin.
- `CODEOWNERS` (ver arquivo) força revisão de dono técnico em áreas sensíveis
  (autenticação, pipeline, IaC).

## Ordem de implantação (priorização por risco x esforço)

Como não existe processo hoje, a implantação é faseada:

1. **Semana 1–2** — pre-commit hooks (secrets) + branch protection. Mais barato, evita
   o pior incidente (credencial vazada) imediatamente.
2. **Semana 3–4** — SAST + SCA + geração de SBOM como gate obrigatório no PR.
3. **Mês 2** — CODEOWNERS, classificação de criticidade, IaC scanning + policy-as-code.
4. **Mês 2–3** — assinatura de artefato (SLSA/cosign), DAST em staging, SLA formal de
   vulnerabilidade.
5. **Mês 3+** — SSDLC completo com threat modeling nas features críticas.

## O que há de mais atual nesta proposta (vs. abordagem tradicional)

- **SBOM em toda build** (não só scan de vulnerabilidade) — dá rastreabilidade de
  componentes mesmo antes de uma CVE nova ser publicada.
- **Assinatura de artefato (Sigstore/cosign)** — garante que o que roda em produção é
  exatamente o que passou pelos gates, sem substituição no meio do caminho.
- **Policy-as-code (OPA/Conftest)** em vez de regras fixas de scanner — a política de
  segurança fica versionada e auditável junto do código, não configurada manualmente
  numa UI de ferramenta.
