#/usr/bin/env bash
set -eou pipefail

DB_YAML=${DB_YAML:-db.yaml}
DB_JSON=${DB_JSON:-db.json}

cd "$(dirname "$0")"

case "${1:-}" in
  install)
    npm install -g json-server
    $0 reset-db
    ;;
  reset-db)
    echo Reseting \"$DB_JSON\" from \"$DB_YAML\" ...
    yq -o json "$DB_YAML" > "$DB_JSON"
    ;;
  start)
    json-server -w "$DB_JSON"
    ;;
esac
