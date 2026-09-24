# Bootstrap do Terraform

Cria somente o bucket S3 remoto do state. Execute antes do ambiente `dev`.

```bash
terraform init
terraform apply -var='state_bucket_name=SEU_BUCKET_UNICO'
```

Depois copie o nome do bucket para `environments/dev/backend.tf`.
