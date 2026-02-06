#!/usr/bin/env bash
# status.sh — Read and display status of claude-code-dev jobs
# Usage: status.sh [job-id]  — show specific job
#        status.sh            — show most recent job
#        status.sh --all      — show all jobs

set -euo pipefail

JOBS_DIR="/tmp/claude-dev-jobs"

if [ ! -d "$JOBS_DIR" ] || [ -z "$(ls -A "$JOBS_DIR" 2>/dev/null)" ]; then
  echo '{"phase":"none","message":"Aucun job en cours"}'
  exit 0
fi

show_job() {
  local job_dir="$1"
  local status_file="$job_dir/status.json"
  if [ -f "$status_file" ]; then
    cat "$status_file"
  else
    echo "{\"job_id\":\"$(basename "$job_dir")\",\"phase\":\"unknown\",\"message\":\"Fichier status introuvable\"}"
  fi
}

if [ "${1:-}" = "--all" ]; then
  for d in "$JOBS_DIR"/*/; do
    [ -d "$d" ] || continue
    echo "=== $(basename "$d") ==="
    show_job "$d"
    echo ""
  done
elif [ -n "${1:-}" ]; then
  show_job "$JOBS_DIR/$1"
else
  latest=$(ls -t "$JOBS_DIR" | head -1)
  show_job "$JOBS_DIR/$latest"
fi
