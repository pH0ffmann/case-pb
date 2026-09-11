package main

# Política própria de infraestrutura, versionada e revisada em PR — não
# configurada manualmente na UI de uma ferramenta de terceiro.

# Nega qualquer bucket S3 sem criptografia em repouso.
deny contains msg if {
  input.resource_type == "aws_s3_bucket"
  not input.server_side_encryption_configuration
  msg := sprintf("Bucket '%s' sem criptografia em repouso configurada", [input.name])
}

# Nega security group aberto (0.0.0.0/0) em porta administrativa.
deny contains msg if {
  input.resource_type == "aws_security_group_rule"
  input.cidr_blocks[_] == "0.0.0.0/0"
  input.from_port <= 22
  input.to_port >= 22
  msg := "Regra de security group expõe porta 22 (SSH) para a internet"
}

# Nega credencial estática de IAM (access key) em favor de OIDC.
deny contains msg if {
  input.resource_type == "aws_iam_access_key"
  msg := "Uso de access key estática de IAM não é permitido — use OIDC/federação (ver terraform/example-oidc)"
}
