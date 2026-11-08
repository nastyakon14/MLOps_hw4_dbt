#!/usr/bin/env bash
set -euo pipefail

mode="${1:-lint}"
shift || true

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root/dbt"

files=()
if [[ $# -eq 0 ]]; then
  files=(models tests)
else
  for file in "$@"; do
    if [[ "$file" = /* ]]; then
      abs="$file"
    else
      abs="$root/$file"
    fi
    files+=("${abs#"$root/dbt/"}")
  done
fi

exec "$root/.venv/bin/sqlfluff" "$mode" --dialect clickhouse "${files[@]}"
