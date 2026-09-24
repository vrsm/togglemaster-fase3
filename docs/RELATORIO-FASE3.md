# Relatório - POSTECH Tech Challenge Fase 3

## Participantes
- Nome / RM / Discord: PREENCHER

## Repositórios
- Aplicação + Terraform: PREENCHER
- GitOps: PREENCHER

## Vídeo
PREENCHER

## Arquitetura
ToggleMaster com 5 microsserviços, EKS, 3 RDS PostgreSQL, ElastiCache Redis, SQS e DynamoDB.

## Decisões
- Terraform com backend remoto S3.
- CI separado por microsserviço.
- SAST/SCA/Trivy com bloqueio de CRITICAL.
- ECR com tags por commit.
- GitOps com ArgoCD, sem `kubectl apply` no CI.

## Desafios
PREENCHER com evidências reais durante a execução.

## Custos AWS
Inserir print da estimativa de custos solicitada pela POSTECH.
