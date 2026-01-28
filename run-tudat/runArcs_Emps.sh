#!/usr/bin/env bash
set -euo pipefail

# ===== SETTINGS =====
MAX_PARALLEL=25                       # how many arcs to run concurrently
ARC_CHUNK=365                          # combine every this many arcs
START_INDEX=100
STEP=1 				#set >0 to enable simple stepping or <0 otherwise
TAKE=-6					# set >0 with skip >=0 to enable take/skip mode or <0 otherwise
SKIP=-12					# set >=0 with take >0 to enable take/skip mode or <0 otherwise
CONFIG_DIR="path/to/configs"                 # where config_arc_*.json live
BASE_OUTPUT="path/to/output_test_MGSOnlyEmpiricals"     # base dir for per-arc outputs
EXEC_RUN_ARC="path/to/build/tudat/bin/parallelArcProcessEmpiricals"      # <<< compiled single-arc executable
EXEC_COMBINE="path/to/build/tudat/bin/computeCovariances_ForEmps"  # <<< compiled combiner

DEBUG=${DEBUG:-0}

# ===== Helpers =====
die() { echo "ERROR: $*" >&2; exit 1; }
say() { echo "[$(date +%H:%M:%S)] $*"; }
# Print expanded command in DEBUG, otherwise execute safely
run_cmd() {
  if [[ "$DEBUG" == "1" ]]; then
    printf '+'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

# Detect if wait -n exists
has_wait_n=0
if bash -c 'wait -n 2>/dev/null' < /dev/null 2>/dev/null; then
  has_wait_n=1
fi

# ===== Discover arcs & select=====
[[ -d "$CONFIG_DIR" ]] || die "Config dir '$CONFIG_DIR' not found."

# Count configs robustly
NUM_ARCS_FOUND=$(find "$CONFIG_DIR" -maxdepth 1 -type f -name 'config_arc_*.json' | wc -l | tr -d ' ')
(( NUM_ARCS_FOUND > 0 )) || die "No configs matching '$CONFIG_DIR/config_arc_*.json'"

NUM_ARCS=${1:-$NUM_ARCS_FOUND}  # use first CLI arg, else default = all
if (( NUM_ARCS > NUM_ARCS_FOUND )); then
  echo "Requested $NUM_ARCS arcs, but only $NUM_ARCS_FOUND configs found — truncating."
  NUM_ARCS=$NUM_ARCS_FOUND
fi

declare -a SELECTED=()

if ((STEP >0 )) && ((TAKE <=0)); then
    for ((i= START_INDEX; i<NUM_ARCS; i+=STEP)); do
	SELECTED+=( "$i" )
    done
elif ((TAKE >0)) && ((SKIP >=0)) && ((STEP<=0)); then
    i=$START_INDEX
    while ((i<NUM_ARCS)); do
	for ((j=0;j<TAKE && i+j<NUM_ARCS;++j)); do
	    SELECTED+=( $((i + j)) )
	done
	i=$((i+TAKE+SKIP))
    done
else 
    say "Config error: choose EITHER STEP>0 (and TAKE <=0), OR TAKE>0/SKIP>=0 (and STEP<=0)"
fi

TOTAL_SELECTED=${#SELECTED[@]}
echo "$TOTAL_SELECTED"
((TOTAL_SELECTED>0)) || { say "no selected arcs"; exit 1;}

[[ -x "$EXEC_RUN_ARC" ]] || die "Executable not found or not executable: $EXEC_RUN_ARC"
[[ -x "$EXEC_COMBINE" ]] || say "WARNING: Combiner not executable yet: $EXEC_COMBINE"

#say "Found $NUM_ARCS configs in $CONFIG_DIR"
say "MAX_PARALLEL=$MAX_PARALLEL, ARC_CHUNK=$ARC_CHUNK, has_wait_n=$has_wait_n"

run_cmd mkdir -p "$BASE_OUTPUT"

launch_arc() {
  local idx="$1"
  local outdir="${BASE_OUTPUT}/output_arc_${idx}"
  run_cmd mkdir -p "$outdir"
  if [[ "$DEBUG" == "1" ]]; then
    printf '+ (dry-run) '
    printf '%q ' "$EXEC_RUN_ARC" --config "$CONFIG_DIR/config_arc_${idx}.json" --output-dir "$outdir"
    printf '\n'
    printf '+ (dry-run) '
    printf '%q ' touch "$outdir/done.flag"
    printf '\n'
  else
    (
      set -e
      "$EXEC_RUN_ARC" --config "$CONFIG_DIR/config_arc_${idx}.json" \
                      --output-dir "$outdir" > "$outdir/log.txt" 2>&1
      touch "$outdir/done.flag"
    ) &
  fi
}

run_chunk() {
  local start="$1" end="$2"
  local running=0
  for (( k=start; k<=end; ++k )); do
    local i="${SELECTED[$k]}"
    say "Launching arc $i"
    launch_arc "$i"
    running=$((running+1))
    if (( running >= MAX_PARALLEL )); then
      if (( has_wait_n == 1 )); then
        [[ "$DEBUG" == "1" ]] && echo "+ (dry-run) wait -n" || wait -n
        running=$((running-1))
      else
        # Fallback: batch wait when we reach the cap
        [[ "$DEBUG" == "1" ]] && echo "+ (dry-run) wait" || wait
        running=0
      fi
    fi
  done
  [[ "$DEBUG" == "1" ]] && echo "+ (dry-run) wait" || wait
}

combine_up_to_arc_exclusive() {
  local processed="$1"                               # combine arcs [0 .. upto-1]
  local upto="${SELECTED[$((processed-1))]}"
  local tag="after_${processed}_sampled"
  local outdir="${BASE_OUTPUT}/combined_${tag}"
  run_cmd mkdir -p "$outdir"
  say "Combining arcs [0..(up to real arc index) $((upto))] into $outdir"

  run_cmd "$EXEC_COMBINE" \
    --baseDir "$BASE_OUTPUT" \
    --num-arcs "$((upto + 1))" \
    --start "$START_INDEX" \
    --step "$STEP" \
    --take "$TAKE" \
    --skip "$SKIP" 
  say "Wrote: $outdir/combined_normal.bin and $outdir/combined_covariance.bin"
}

# ===== Main driver =====

chunk_start=0
while (( chunk_start < TOTAL_SELECTED )); do
    chunk_end=$((chunk_start + ARC_CHUNK - 1))
    (( chunk_end >= TOTAL_SELECTED )) && chunk_end=$(( TOTAL_SELECTED - 1 ))
    run_chunk "$chunk_start" "$chunk_end"
    processed=$(( chunk_end + 1 ))
    combine_up_to_arc_exclusive "$processed"

    chunk_start=$(( chunk_end + 1 ))
done
