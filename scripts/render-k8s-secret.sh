#!/usr/bin/env bash
set -euo pipefail
TF_DIR="$(cd "$(dirname "$0")/../terraform/environments/dev" && pwd)"
OUT="${1:-/tmp/togglemaster-secret.yaml}"
DB_USER="$(terraform -chdir="$TF_DIR" output -raw db_username)"
: "${TOGGLEMASTER_DB_PASSWORD:?Defina TOGGLEMASTER_DB_PASSWORD}"
: "${TOGGLEMASTER_MASTER_KEY:?Defina TOGGLEMASTER_MASTER_KEY}"
: "${TOGGLEMASTER_SERVICE_API_KEY:?Defina TOGGLEMASTER_SERVICE_API_KEY}"
readarray -t EP < <(terraform -chdir="$TF_DIR" output -json rds_endpoints | python3 -c 'import json,sys; x=json.load(sys.stdin); print(x["auth"]); print(x["flag"]); print(x["targeting"])')
cat > "$OUT" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: togglemaster-secret
  namespace: togglemaster
type: Opaque
stringData:
  MASTER_KEY: "${TOGGLEMASTER_MASTER_KEY}"
  SERVICE_API_KEY: "${TOGGLEMASTER_SERVICE_API_KEY}"
  AUTH_DATABASE_URL: "postgres://${DB_USER}:${TOGGLEMASTER_DB_PASSWORD}@${EP[0]}:5432/auth_db?sslmode=require"
  FLAG_DATABASE_URL: "postgres://${DB_USER}:${TOGGLEMASTER_DB_PASSWORD}@${EP[1]}:5432/flags_db?sslmode=require"
  TARGETING_DATABASE_URL: "postgres://${DB_USER}:${TOGGLEMASTER_DB_PASSWORD}@${EP[2]}:5432/targeting_db?sslmode=require"
EOF
echo "$OUT"
