# ToggleMaster — POSTECH Tech Challenge — Fase 3

Implementação da **Fase 3 do POSTECH Tech Challenge**, evoluindo a aplicação ToggleMaster para uma arquitetura automatizada de infraestrutura, CI/CD, DevSecOps e GitOps.

O projeto é composto por cinco microsserviços:

- **Auth Service**
- **Flag Service**
- **Targeting Service**
- **Evaluation Service**
- **Analytics Service**

A infraestrutura e o ciclo de implantação foram automatizados utilizando Terraform, GitHub Actions, Amazon ECR, Kubernetes, Amazon EKS e ArgoCD.

---

## Arquitetura da solução

O fluxo completo de entrega da aplicação é:

```text
                    ┌──────────────────────┐
                    │       GitHub         │
                    │   togglemaster-fase3 │
                    └──────────┬───────────┘
                               │
                               │ Push / Pull Request
                               ▼
                    ┌──────────────────────┐
                    │   GitHub Actions     │
                    │                      │
                    │ • Testes             │
                    │ • Lint               │
                    │ • SAST               │
                    │ • SCA                │
                    │ • Docker Build       │
                    │ • Trivy              │
                    └──────────┬───────────┘
                               │
                               │ imagem com SHA
                               ▼
                    ┌──────────────────────┐
                    │      Amazon ECR      │
                    └──────────┬───────────┘
                               │
                               │ atualização da imagem
                               ▼
                    ┌──────────────────────┐
                    │   Repositório GitOps │
                    │ togglemaster-gitops  │
                    └──────────┬───────────┘
                               │
                               │ monitoramento
                               ▼
                    ┌──────────────────────┐
                    │       ArgoCD         │
                    │  Sync + Self Heal    │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │      Amazon EKS      │
                    │                      │
                    │  5 microsserviços    │
                    └──────────────────────┘
