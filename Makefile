SHELL := /bin/bash

local-up:
	docker compose up --build

local-down:
	docker compose down -v

terraform-fmt:
	terraform -chdir=terraform/environments/dev fmt -recursive

terraform-validate:
	terraform -chdir=terraform/environments/dev init -backend=false && terraform -chdir=terraform/environments/dev validate
