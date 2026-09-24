variable "aws_region" { type = string default = "us-east-1" }
variable "project_name" { type = string default = "togglemaster" }
variable "academy_mode" { type = bool default = true description = "true para AWS Academy/LabRole; false para conta pessoal" }
variable "lab_role_name" { type = string default = "LabRole" }
variable "cluster_version" { type = string default = "1.34" }
variable "vpc_cidr" { type = string default = "10.20.0.0/16" }
variable "db_username" { type = string default = "togglemaster" sensitive = true }
variable "db_password" { type = string sensitive = true }
variable "master_key" { type = string sensitive = true }
variable "service_api_key" { type = string sensitive = true default = "" }
variable "gitops_repo_url" { type = string default = "https://github.com/SEU_USUARIO/togglemaster-gitops.git" }
variable "gitops_target_revision" { type = string default = "main" }
variable "enable_argocd" { type = bool default = true }
