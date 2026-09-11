# Política de Segurança

## 1. Gestão de vulnerabilidades

### SLA por severidade

| Severidade | Critério | SLA |
|---|---|---|
| Crítica | CVSS ≥ 9.0 ou exploit ativo (KEV) ou dado sensível exposto | 24–48h |
| Alta | CVSS 7.0–8.9, exposta à internet | 7 dias |
| Média | CVSS 4.0–6.9 ou alta sem exposição direta | 30 dias |
| Baixa | CVSS < 4.0 | Backlog |

Priorização real considera exploitability e exposição, não só o score CVSS isolado —
o SBOM gerado em cada build (ver pipeline) permite checar exposição a uma CVE nova
publicada depois do deploy, sem re-escanear tudo do zero.

### Fluxo de exceção de risco

1. Solicitação com justificativa técnica e prazo de revisão.
2. Aprovação do time de segurança (nunca autoaprovação do próprio time de dev).
3. Toda exceção expira — sem "aceite eterno". Ao expirar: corrige, renova ou escala.
4. Exceções ativas visíveis em dashboard, com dono e prazo.

## 2. Gestão de segredos

- Zero secrets em código — bloqueado por `gitleaks` no pre-commit e no CI (dupla camada).
- Cofre central (Vault/Secrets Manager/Key Vault) com rotação automática.
- Autenticação do pipeline com a cloud via **OIDC/Workload Identity Federation**
  (ver `terraform/example-oidc/`) — sem access key estática. Reforçado como regra em
  `policy/iac-security.rego`.
- Scan cobre todo o histórico do git, não só commits novos.
- Secret encontrado em produção = incidente (rotação imediata + investigação), não
  finding de backlog.

## 3. Integridade de artefato (supply chain)

- SBOM (CycloneDX) gerado e versionado por build, permitindo auditoria de
  componentes independente de a CVE já existir no momento do build.
