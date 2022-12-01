#/usr/bin/env bash
set -eou pipefail

usage() {
  cat<<-EOF
	Usage:
	$0 <install|reset-db|start|restart>
	EOF
}

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
  restart)
    $0 reset-db
    $0 start
    ;;
  *) usage
esac
