# Autenticação do pipeline com a cloud via OIDC — token de curta duração,
# sem access key/secret key estático versionado ou configurado no CI.
# (A política em policy/iac-security.rego bloqueia aws_iam_access_key.)

provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "ci_pipeline_role" {
  name = "gh-actions-ci-oidc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:org/devsecops-secure-sdlc:ref:refs/heads/main"
        }
      }
    }]
  })
}
