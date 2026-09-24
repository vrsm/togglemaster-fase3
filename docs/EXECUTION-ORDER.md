# Ordem de execução - Fase 3

1. Teste local: `docker compose up --build`.
2. Bootstrap S3: `terraform/bootstrap`.
3. Configure `terraform/environments/dev/backend.tf`.
4. Crie `terraform.tfvars` a partir do exemplo.
5. `terraform init`, `fmt`, `validate`, `plan`, `apply`.
6. Configure `kubectl` para o EKS.
7. Crie o Secret de runtime no namespace `togglemaster`.
8. Publique as primeiras imagens no ECR (ou rode CI na main).
9. Crie/ajuste o repositório GitOps.
10. Edite `gitops/argocd/application.yaml` com o URL real.
11. Aplique a Application no ArgoCD.
12. Valide Pods, Services, Ingress e HPA.

Não faça `kubectl apply` das aplicações como parte do CI: a Fase 3 exige GitOps/ArgoCD.

## Runtime Secret
Após o Terraform criar os RDS, exporte `TOGGLEMASTER_DB_PASSWORD`, `TOGGLEMASTER_MASTER_KEY` e `TOGGLEMASTER_SERVICE_API_KEY` e rode:

```bash
./scripts/render-k8s-secret.sh
kubectl apply -f /tmp/togglemaster-secret.yaml
```

Esse Secret fica fora do repositório GitOps; o GitOps gerencia os Deployments e configurações não sensíveis.

## Local API smoke test
Após `docker compose up -d --build`, gere uma chave pelo endpoint protegido do auth-service usando a `MASTER_KEY` local e exporte `SERVICE_API_KEY` antes de reiniciar evaluation.

```bash
export MASTER_KEY=toggle-master-dev-only
curl -s -X POST http://localhost:8001/admin/keys -H "Authorization: Bearer $MASTER_KEY" -H 'Content-Type: application/json' -d '{"name":"local-evaluation"}'
```
Use o campo `key` retornado como `SERVICE_API_KEY`.
## Correção para os serviços Go

Os projetos Go recebidos da Fase 2 não incluem `go.sum`. Os Dockerfiles da Fase 3 usam `go build -mod=mod` após `go mod download` para permitir que o módulo gere o checksum no build. Nos workflows GitHub Actions, `go mod download` é executado antes dos testes.
