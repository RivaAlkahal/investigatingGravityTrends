#!/usr/bin/env bash
set -euo pipefail

# ==== CONFIG: THREE SOURCES ===================================================
# Only source arcs with index i where SRC_STARTn <= i <= SRC_ENDn are considered.
# From those, we apply a TAKE/SKIP cycle (per source): take TAKEn, skip SKIPn, repeat.
# Destination index is j = i + OFFn (shift can be negative).
#
# Convention:
#   - TAKE=0 and SKIP=0  -> take all
#   - SKIP=0             -> take all
#   - TAKE=0 and SKIP>0  -> take none


SRC1="path/to/output_test_MultiSats"     # base dir for per-arc outputs

OFF1=180
SRC_START1=0
SRC_END1=2117
TAKE1=0
SKIP1=0

SRC2="path/to/output_test_Vikings"
OFF2=-34
SRC_START2=0
TAKE2=6
SKIP2=12


SRC3="path/to/output_test_EDM"
OFF3=180
SRC_START3=2920
SRC_END3=9999999999
TAKE3=0
SKIP3=0


DEST="/path/to/merged_6_12"

mkdir -p "$DEST"

# Make globs with no matches expand to nothing
shopt -s nullglob

# Resolve absolute path of a directory (portable)
absdir () {
  local p="$1"
  [[ -d "$p" ]] || { echo "ERROR: not a directory: $p" >&2; return 1; }
  ( cd "$p" && pwd )
}

add_set_range_take_skip () {
  local SRC="$1" OFF="$2" SRC_START="$3" SRC_END="$4" TAKE="$5" SKIP="$6"

  if (( SRC_START > SRC_END )); then
    echo "WARN: SRC_START ($SRC_START) > SRC_END ($SRC_END) for '$SRC' — skipping." >&2
    return 0
  fi
  if (( TAKE < 0 || SKIP < 0 )); then
    echo "ERROR: TAKE/SKIP must be >= 0 for '$SRC'." >&2
    return 1
  fi

  local SRC_ABS
  SRC_ABS=$(absdir "$SRC")

  # Collect "index<TAB>path"
  local tmpfile
  tmpfile="$(mktemp)"
  # Ensure cleanup on function return
  trap 'rm -f "$tmpfile"' RETURN
  
  for d in "$SRC"/output_arc_*; do
    [[ -d "$d" ]] || continue
    [[ -f "$d/done.flag" ]] || continue
    base="${d##*/}"   # output_arc_123
    i="${base##*_}"   # 123
    case "$i" in (''|*[!0-9]*) continue ;; esac
    printf '%s\t%s\n' "$i" "$d" >> "$tmpfile"
  done

  if ! [[ -s "$tmpfile" ]]; then
    echo "WARN: No matching dirs in '$SRC'." >&2
    return 0
  fi

  # Iterate in numeric index order
  local pos=0                   # position among items WITHIN [SRC_START,SRC_END]
  local cycle=$(( TAKE + SKIP ))

  # Use process substitution to avoid subshell for the while loop body
  while IFS=$'\t' read -r i full; do
    # Filter by source index range
    if (( i < SRC_START || i > SRC_END )); then
      continue
    fi

    # Decide if we take this entry based on TAKE/SKIP cycle
    local take_this=1
    if (( TAKE == 0 && SKIP == 0 )); then
      take_this=1                        # take all
    elif (( SKIP == 0 )); then
      take_this=1                        # take all
    elif (( TAKE == 0 )); then
      take_this=0                        # take none
    else
      if (( (pos % cycle) >= TAKE )); then
        take_this=0
      fi
    fi

    if (( take_this )); then
      local j=$(( i + OFF ))
      # Create symlink; if already exists, keep the first (collapse)
      ln -s "${SRC_ABS}/output_arc_${i}" "$DEST/output_arc_${j}" 2>/dev/null || true
    fi

    pos=$(( pos + 1 ))
  done < <(sort -t $'\t' -k1,1n "$tmpfile")
}

add_set_range_take_skip "$SRC1" "$OFF1" "$SRC_START1" "$SRC_END1" "$TAKE1" "$SKIP1"
add_set_range_take_skip "$SRC2" "$OFF2" "$SRC_START2" "$SRC_END2" "$TAKE2" "$SKIP2"
#add_set_range_take_skip "$SRC3" "$OFF3" "$SRC_START3" "$SRC_END3" "$TAKE3" "$SKIP3"

echo "Merged into: $DEST"

