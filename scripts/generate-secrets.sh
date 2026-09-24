#!/usr/bin/env bash
set -euo pipefail
printf 'MASTER_KEY=%s\n' "$(openssl rand -hex 32)"
printf 'DB_PASSWORD=%s\n' "$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 24)"
