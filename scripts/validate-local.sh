#!/usr/bin/env bash
set -euo pipefail
docker compose config >/dev/null
docker compose build
echo "Compose configuration/build OK"
