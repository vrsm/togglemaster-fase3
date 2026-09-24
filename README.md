# ToggleMaster — POSTECH Tech Challenge Fase 3

Implementação baseada no código entregue na Fase 2 e nos requisitos do documento da Fase 3.

## Repositórios
- Este repositório: microsserviços, Docker, Terraform e GitHub Actions.
- `gitops/`: conteúdo para o repositório GitOps/ArgoCD.

## Comece localmente
```bash
docker compose up --build
```

Depois gere uma API key no `auth-service` conforme `docs/EXECUTION-ORDER.md` e reinicie o `evaluation-service` com `SERVICE_API_KEY`.

Serviços:
- auth: http://localhost:8001
- flag: http://localhost:8002
- targeting: http://localhost:8003
- evaluation: http://localhost:8004
- analytics: http://localhost:8005

## AWS
Leia `docs/EXECUTION-ORDER.md` e depois `terraform/bootstrap/README.md`.

### Academy
Use `academy_mode = true` e `LabRole`.

### Conta pessoal
Use `academy_mode = false`; o Terraform criará as roles EKS/Node necessárias.

## Segurança
- Não commite `terraform.tfvars`.
- Não commite Secrets reais.
- Configure as variáveis/Secrets do GitHub antes do push.
- O CI bloqueia vulnerabilidades CRITICAL via Trivy.

## Observação
O documento da Fase 2 menciona 4 bancos locais, mas o código fornecido contém 3 PostgreSQL + Redis + DynamoDB + LocalStack/SQS. Este pacote preserva a arquitetura efetivamente implementada no código e a exigência da Fase 3 de 3 RDS, Redis, DynamoDB e SQS.
