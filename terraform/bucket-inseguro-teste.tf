# ARQUIVO DE TESTE — propositalmente inseguro, só para demonstrar o gate
# de policy-as-code (policy/iac-security.rego) bloqueando de verdade.
# Remover antes do commit final.

resource "aws_s3_bucket" "dados_clientes_teste" {
  bucket = "dados-clientes-teste-inseguro"
  # Sem server_side_encryption_configuration -> deve ser bloqueado pela
  # política em policy/iac-security.rego
}
