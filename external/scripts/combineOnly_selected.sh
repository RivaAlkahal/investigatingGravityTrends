#!/usr/bin/env bash
set -euo pipefail

# ===== SETTINGS =====
ARC_CHUNK=3650
BASE_OUTPUT="merged_MultiSats"
EXEC_COMBINE="./computeCovariance_TestMultiSat"


DENSE_DIR="${BASE_OUTPUT}/"


DEBUG=${DEBUG:-0}
say() { echo "[$(date +%H:%M:%S)] $*"; }
run_cmd() { if [[ "$DEBUG" == "1" ]]; then printf '+'; printf ' %q' "$@"; printf '\n'; else "$@"; fi; }
die() { echo "ERROR: $*" >&2; exit 1; }

# ===== 1) Enumerate what actually exists =====
[[ -d "$BASE_OUTPUT" ]] || die "Base output dir '$BASE_OUTPUT' not found."

declare -a EXISTING=()
shopt -s nullglob
for d in "$BASE_OUTPUT"/output_arc_*; do
  [[ -d "$d" ]] || continue
  base="${d##*/}"               # output_arc_123
  i="${base##*_}"               # 123
  case "$i" in (''|*[!0-9]*) continue ;; esac
  EXISTING+=( "$i" )
done
(( ${#EXISTING[@]} > 0 )) || die "No arcs found in '$BASE_OUTPUT'."

# Sort numerically (BSD/GNU portable)
# shellcheck disable=SC2207
EXISTING=( $(printf "%s\n" "${EXISTING[@]}" | LC_ALL=C sort -n) )
TOTAL=${#EXISTING[@]}
say "Found $TOTAL arcs in $BASE_OUTPUT (some gaps are OK)."

# ===== 2) Build a dense view by position =====
run_cmd rm -rf "$DENSE_DIR"
run_cmd mkdir -p "$DENSE_DIR"
MANIFEST="$DENSE_DIR/manifest.tsv"  # dense_idx  real_idx  real_path
: > "$MANIFEST"

for ((k=0; k<TOTAL; ++k)); do
  real_idx="${EXISTING[$k]}"
  real_path="$BASE_OUTPUT/output_arc_${real_idx}"
  [[ -d "$real_path" ]] || die "Missing: $real_path"

  dense_path="$DENSE_DIR/output_arc_${k}"
  real_abs="$(cd "$real_path" && pwd)"
  ln -s "$real_abs" "$dense_path"
  printf "%s\t%s\t%s\n" "$k" "$real_idx" "$real_abs" >> "$MANIFEST"
done

say "Dense view ready: $DENSE_DIR"
say "Manifest: $MANIFEST"

# ===== 3) Combine in chunks, taking ALL dense arcs =====
combine_up_to_dense_exclusive() {
  local count="$1"                               # combine dense arcs [0 .. count-1]
  local tag="after_${count}_dense"
  local outdir="${DENSE_DIR}/combined_${tag}"
  run_cmd mkdir -p "$outdir"

  say "Combining dense arcs [0..$((count-1))] into $outdir"

  run_cmd "$EXEC_COMBINE" \
    --baseDir "$DENSE_DIR" \
    --num-arcs "$count" \
    --start 0 \
    --step 1 \
    --take 0 \
    --skip 0

  say "Wrote: $outdir/combined_normal.bin and $outdir/combined_covariance.bin"
}

chunk_start=0
while (( chunk_start < TOTAL )); do
  chunk_end=$((chunk_start + ARC_CHUNK - 1))
  (( chunk_end >= TOTAL )) && chunk_end=$(( TOTAL - 1 ))
  processed=$(( chunk_end + 1 ))  # count of dense arcs
  combine_up_to_dense_exclusive "$processed"
  chunk_start=$(( chunk_end + 1 ))
done

say "Done."

