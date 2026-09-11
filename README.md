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
desenvolvimento, verificação, release, operação), ancoradas em NIST SSDF e
OWASP SAMM/ASVS, com o racional de por que threat modeling formal entra só
depois da maturidade inicial do time, não desde o primeiro dia.

**Testado:** a fase de Verificação está comprovada de ponta a ponta pelos
gates do pipeline (ponto 03). As fases de Requisitos e Design são processuais
por natureza, não têm o que rodar em pipeline.

## 03. Controles de segurança integrados ao pipeline CI/CD

**Implementado e testado com resultado real** (`secure-pipeline.yml`,
evidências completas em `docs/evidencias.md`):

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

**Limitação conhecida documentada no próprio workflow:** a CLI do Semgrep
não reconhece o nível de severidade Critical usado no registro mais recente
de regras, só INFO/WARNING/ERROR. O filtro atual cobre severidade High de
forma confiável; cobertura completa de High e Critical juntos exigiria
processar a saída em JSON e filtrar pelo campo de severidade de cada
finding, em vez de usar a flag nativa da CLI.

**Documentado, não executado neste ambiente:** container scan e assinatura
de artefato (Trivy + cosign) e DAST em staging (OWASP ZAP). Ambos são
aprofundamento dentro deste mesmo ponto (supply chain e teste dinâmico), não
uma lacuna dos 6 pontos do case. A lógica está escrita e comentada no
workflow, pronta para ativar. Decisão de não executar por custo e tempo
desproporcionais ao ganho de prova para este case específico, não por
limitação técnica: o build da imagem e a assinatura via cosign, por exemplo,
poderiam rodar sem custo algum usando o GitHub Container Registry e o OIDC
do próprio GitHub Actions.

## 04. Gestão de vulnerabilidades e tratamento de riscos

**Documentado em `SECURITY.md`:** SLA por severidade (24 a 48 horas para
crítico até backlog para baixo), critério de priorização considerando
exploitability e exposição além do CVSS puro, fluxo de exceção de risco com
prazo de expiração (sem aceite eterno), e referência à LGPD para dados de
cliente.

**Testado contra dado real:** as CVEs encontradas pelo Trivy no SCA (ponto
03) servem de caso concreto para aplicar o SLA definido. Por exemplo, uma
CVE de severidade Critical identificada em `urllib3` se enquadraria no prazo
de 24 a 48 horas segundo a política.

## 05. Proteção de branches

**Implementado e testado:** regra aplicada de verdade via API do GitHub
contra este repositório (`branch-protection/apply-branch-protection.sh`), com
2 aprovações exigidas, revisão de CODEOWNER obrigatória, commits assinados,
sem force push nem deleção de branch, sem bypass para admin.

Validado na prática: um push direto para `main` foi recusado pelo GitHub
(`GH006: Protected branch update failed`), exigindo Pull Request e assinatura
de commit. Print da configuração aplicada em `docs/evidencias.md`.

## 06. Gestão de segredos

**Implementado e testado:**
- Pre-commit com dupla camada (`gitleaks` + `detect-secrets`) bloqueia
  credencial antes mesmo do commit existir. Testado localmente com uma chave
  AWS de exemplo, commit recusado com o tipo e a localização do achado
  identificados corretamente.
- Secrets scan também roda no pipeline (ponto 03), como segunda linha de
  defesa cobrindo todo o histórico do repositório.

**Documentado, não validado contra cloud real:** autenticação via
OIDC/Workload Identity Federation (`terraform/example-oidc/main.tf`),
reforçada pela política em `policy/iac-security.rego` que nega o uso de
access key estática de IAM. O desenho está pronto e segue boas práticas
atuais, mas não foi testado contra uma conta AWS real, decisão de
custo-benefício para este case.

---

## Ordem de implantação recomendada (priorização por risco e esforço)

Como hoje não existe nenhum processo formal, a proposta é faseada:

1. Semana 1-2: pre-commit hooks (secrets) e proteção de branch. Baixo custo,
   alto impacto, evita o pior incidente (credencial vazada) imediatamente.
2. Semana 3-4: SAST, SCA e geração de SBOM como gate obrigatório no PR.
3. Mês 2: CODEOWNERS, classificação de criticidade, IaC scanning e
   policy-as-code.
4. Mês 2-3: assinatura de artefato (SLSA/cosign), DAST em staging, SLA formal
   de vulnerabilidade.
5. Mês 3 em diante: SSDLC completo com threat modeling nas features
   críticas.

## Referências de mercado usadas nesta proposta

NIST SSDF (SP 800-218) para a estrutura geral do ciclo seguro, OWASP ASVS e
SAMM para o nível de verificação por criticidade de aplicação, CIS Benchmarks
para hardening de containers e infraestrutura.

## Princípio orientador

Segurança que trava o time sem calibrar severidade gera fadiga de alerta, e o
time aprende a ignorar o gate. Todo controle aqui tem um limiar de
severidade que decide entre bloquear o merge ou abrir issue para tratar
depois, não é tudo bloqueante.
