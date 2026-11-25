#!/usr/bin/env bash
# Run the scaling gate and record wall time plus peak resident memory summed
# over the R parent and all of its worker processes (polled every 0.2 s).
# Usage: scripts/benchmark_gate.sh [output.csv] [capacity_pairs] [workers] [backend] [validation] [n_runs]
set -euo pipefail
repo="$(git rev-parse --show-toplevel)"
out="${1:-$repo/output/scaling_gate.csv}"
capacity="${2:-30}"; workers="${3:-8}"; backend="${4:-fork}"; validation="${5:-strict}"; n_runs="${6:-1000}"
mkdir -p "$(dirname "$out")"
[ -f "$out" ] || echo "capacity_pairs,n_runs,workers,backend,validation,elapsed_s,mean_living_years_11_40,min_living,max_living,accounting_reconciled,wall_s,peak_tree_rss_mb" > "$out"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
start="$(date +%s.%N)"
Rscript --vanilla "$repo/scripts/benchmark_gate.R" "$capacity" "$n_runs" "$workers" "$backend" "$validation" > "$tmp" &
pid=$!
peak=0
while kill -0 "$pid" 2>/dev/null; do
  rss="$(ps -e -o pid=,ppid=,rss= | awk -v root="$pid" '
    { parent[$1] = $2; mem[$1] = $3 }
    END {
      total = 0
      for (p in parent) {
        q = p
        while (q != "" && q != root && q != 1 && q != 0) q = parent[q]
        if (q == root) total += mem[p]
      }
      print total + 0
    }')"
  if [ "$rss" -gt "$peak" ]; then peak="$rss"; fi
  sleep 0.2
done
wait "$pid"
end="$(date +%s.%N)"
echo "$(tail -n 1 "$tmp"),$(awk -v start="$start" -v end="$end" 'BEGIN {printf "%.2f", end-start}'),$((peak / 1024))" >> "$out"
tail -n 1 "$out"
