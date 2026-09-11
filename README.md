# Secure SDLC & DevSecOps: Proposta de Implantação

Case técnico: proposta prática de segurança embutida desde o início do ciclo de
desenvolvimento (shift-left), não como etapa pós-deploy.

## Cenário

Aplicação web crítica, múltiplos times, sem processo formal de segurança hoje.
Vulnerabilidades só aparecem em produção.

## Aplicação alvo desta demonstração

Em vez de escrever uma aplicação vulnerável do zero, este repositório usa o
[PyGoat](https://github.com/adeyosemanputra/pygoat), projeto listado no
catálogo oficial de aplicações vulneráveis da OWASP (OWASP VWAD), aplicação
Django intencionalmente vulnerável ao OWASP Top 10, usada aqui só como alvo
para os gates do pipeline demonstrarem detecção real, não simulada.

```bash
git clone https://github.com/adeyosemanputra/pygoat.git target-app
```

O pipeline deste repo (`.github/workflows/secure-pipeline.yml`) assume que o
código da aplicação está em `target-app/`.

As evidências reais de execução (prints do pipeline rodando contra o PyGoat)
estão em `docs/evidencias.md`.

---

## 01. Estratégia de governança e gestão dos repositórios

**Implementado:** `.github/CODEOWNERS` define donos técnicos por área
(infraestrutura Terraform, políticas, workflows de CI/CD, autenticação).
Classificação de criticidade de repositório e RBAC por squad estão descritos
como processo (não há artefato de código, já que dependem de ferramentas de
gestão de acesso da própria empresa).

## 02. Processo de desenvolvimento seguro (SSDLC)

**Documentado em `docs/ssdlc-processo.md`:** as 6 fases (requisitos, design,
desenvolvimento, verificação, release, operação).

**Testado:** a fase de Verificação está comprovada de ponta a ponta pelos
gates do pipeline. As fases de Requisitos e Design são processuais
por natureza, não têm o que rodar em pipeline.

## 03. Controles de segurança integrados ao pipeline CI/CD

**Implementado:**

- **Secrets scan (gitleaks):** roda em todo PR, passou limpo neste
  repositório. Localmente, via pre-commit, foi validado que uma credencial de
  exemplo é bloqueada antes mesmo do commit existir.
- **SAST (Semgrep):** encontrou findings reais e bloqueantes no PyGoat,
  incluindo uso de MD5 como hash de senha. Calibrado para bloquear apenas
  severidade alta (`--severity ERROR`), evitando fadiga de alerta com
  findings de baixo impacto.
- **SCA (Trivy):** encontrou CVEs reais em dependências do PyGoat (por
  exemplo `urllib3`, `sqlparse`), calibrado para bloquear apenas em
  severidade crítica ou alta (`--severity CRITICAL,HIGH`), consistente com o
  filtro usado no scan de infraestrutura.
- **SBOM (Syft, formato CycloneDX):** gerado antes do scan de vulnerabilidade
  rodar, para existir independente do resultado do gate. Um build bloqueado
  por CVE crítica ainda tem seu inventário de componentes registrado.
- **IaC scan (Trivy) + policy as code (Conftest/OPA):** validado com um
  Terraform de teste propositalmente inseguro (bucket S3 sem criptografia),
  bloqueado pelo Trivy antes mesmo da política Rego própria precisar agir.

## 04. Gestão de vulnerabilidades e tratamento de riscos

**Documentado em `SECURITY.md`:** SLA por severidade, critério de priorização considerando
exploitability e exposição além do CVSS puro, fluxo de exceção de risco com
prazo de expiração.

## 05. Proteção de branches

**Implementado:** Regra aplicada de via API do GitHub
contra este repositório (`branch-protection/apply-branch-protection.sh`), com
2 aprovações exigidas, revisão de CODEOWNER obrigatória, commits assinados,
sem force push nem deleção de branch, sem bypass para admin.

Validado na prática: um push direto para `main` foi recusado pelo GitHub
(`GH006: Protected branch update failed`), exigindo Pull Request e assinatura
de commit.

## 06. Gestão de segredos

**Implementado:**
- Pre-commit com dupla camada (`gitleaks` + `detect-secrets`) bloqueia
  credencial antes mesmo do commit existir. Testado localmente com uma chave
  AWS de exemplo, commit recusado com o tipo e a localização do achado
  identificados corretamente.
- Secrets scan também roda no pipeline (ponto 03), como segunda linha de
  defesa cobrindo todo o histórico do repositório.

---

## Ordem de implantação recomendada (priorização por risco e esforço)

Como hoje não existe nenhum processo formal, a proposta é faseada:

1. Fase imediata: pre-commit hooks (secrets) e proteção de branch. Baixo
   custo, alto impacto, evita o pior incidente (credencial vazada) o quanto
   antes.
2. Curto prazo: SAST, SCA e geração de SBOM como gate obrigatório no PR.
3. Médio prazo: CODEOWNERS, classificação de criticidade, IaC scanning e
   policy-as-code.
4. Médio a longo prazo: assinatura de artefato (SLSA/cosign), DAST em
   staging, SLA formal de vulnerabilidade.
5. Longo prazo: SSDLC completo com threat modeling nas features críticas.


