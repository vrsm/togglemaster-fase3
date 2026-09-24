# Ambiente Dev

## 1. Bootstrap
Crie o bucket S3 em `terraform/bootstrap`.

## 2. Backend
Edite `backend.tf` e substitua `REPLACE_WITH_YOUR_TFSTATE_BUCKET`.

## 3. Variáveis
```bash
cp terraform.tfvars.example terraform.tfvars
chmod 600 terraform.tfvars
```
Em AWS Academy mantenha `academy_mode = true` e `lab_role_name = "LabRole"`. Em conta pessoal use `academy_mode = false`.

## 4. Apply
```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

**Importante:** `terraform.tfvars` e `terraform.tfstate` não devem ser commitados.
