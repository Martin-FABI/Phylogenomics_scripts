#!/usr/bin/env bash
set -u
IFS=$'\n\t'

# -------------------------
# USER SETTINGS
# -------------------------
EMAIL_TO="martin.coetzee@up.ac.za"

# If you know the subfolder name inside each genus folder that contains the fasta loci, set it here.
# If not found, the script will auto-detect a subfolder containing fasta files.
DEFAULT_ALIGN_SUBFOLDER=""

# IQ-TREE options
BOOTSTRAP=1000
ALRT=1000
THREADS="AUTO"   # or a number, e.g. 16

# Fasta extensions to consider
FA_EXT_REGEX='\.(fa|fasta|fas|fna|faa)$'

# -------------------------
# INPUT
# -------------------------
BASE_DIR="${1:-$PWD}"                         # top-level directory containing genus folders
ALIGN_SUBFOLDER="${2:-$DEFAULT_ALIGN_SUBFOLDER}"  # optional override for subfolder name

ts="$(date +%Y%m%d_%H%M%S)"
LOG="${BASE_DIR%/}/iqtree_batch_${ts}.log"

SUCCESS=0
FAIL=0
SKIP=0

# -------------------------
# EMAIL SENDER (tries mail, then sendmail)
# -------------------------
send_email() {
  local subject="$1"
  local body="$2"

  if command -v mail >/dev/null 2>&1; then
    printf "%b\n" "$body" | mail -s "$subject" "$EMAIL_TO" || true
    return 0
  fi

  if command -v sendmail >/dev/null 2>&1; then
    {
      echo "To: ${EMAIL_TO}"
      echo "Subject: ${subject}"
      echo
      printf "%b\n" "$body"
    } | sendmail -t || true
    return 0
  fi

  echo "WARN: No 'mail' or 'sendmail' found; cannot send email notification." | tee -a "$LOG"
  return 1
}

# -------------------------
# HELPERS
# -------------------------
find_alignment_dir() {
  local genus_dir="$1"

  # 1) If user specified a subfolder name and it exists, use it
  if [[ -n "$ALIGN_SUBFOLDER" && -d "${genus_dir%/}/${ALIGN_SUBFOLDER}" ]]; then
    echo "${genus_dir%/}/${ALIGN_SUBFOLDER}"
    return 0
  fi

  # 2) Otherwise, auto-detect a directory (within maxdepth 2) that contains fasta files
  local detected
  detected="$(find "$genus_dir" -maxdepth 2 -type f \
    | grep -E -i "$FA_EXT_REGEX" \
    | head -n 1 \
    | awk -F/ 'BEGIN{OFS="/"}{NF--; print $0}' )" || true

  if [[ -n "${detected:-}" && -d "$detected" ]]; then
    echo "$detected"
    return 0
  fi

  echo ""
  return 0
}

# -------------------------
# RUN
# -------------------------
{
  echo "=== IQ-TREE batch started: $(date) ==="
  echo "Base directory : $BASE_DIR"
  echo "Align subfolder: ${ALIGN_SUBFOLDER:-<auto-detect>}"
  echo "Log file       : $LOG"
  echo
} | tee -a "$LOG"

START_TIME="$(date)"

for genus_path in "${BASE_DIR%/}"/*/; do
  [[ -d "$genus_path" ]] || continue

  genus="$(basename "${genus_path%/}")"

  aln_dir="$(find_alignment_dir "$genus_path")"
  if [[ -z "${aln_dir:-}" ]]; then
    echo "[$genus] SKIP: no alignment directory with fasta files found." | tee -a "$LOG"
    ((SKIP++))
    continue
  fi

  outdir="${genus_path%/}/iqtree_out"
  mkdir -p "$outdir"

  prefix="${outdir}/${genus}_concat_ML"

  # Skip if already done
  if [[ -s "${prefix}.treefile" ]]; then
    echo "[$genus] SKIP: existing tree found: ${prefix}.treefile" | tee -a "$LOG"
    ((SKIP++))
    continue
  fi

  echo "[$genus] RUN: aln_dir=$aln_dir" | tee -a "$LOG"

  # Run IQ-TREE
  iqtree2 \
    -p "$aln_dir" \
    -m MFP+MERGE \
    -B "$BOOTSTRAP" \
    -alrt "$ALRT" \
    -T "$THREADS" \
    --prefix "$prefix" >>"$LOG" 2>&1

  exit_code=$?

  if [[ $exit_code -eq 0 && -s "${prefix}.treefile" ]]; then
    echo "[$genus] DONE: ${prefix}.treefile" | tee -a "$LOG"
    ((SUCCESS++))
  else
    echo "[$genus] FAIL: exit_code=$exit_code (see log)" | tee -a "$LOG"
    ((FAIL++))
  fi
done

END_TIME="$(date)"

SUMMARY=$(
  cat <<EOF
IQ-TREE batch finished.

Start : $START_TIME
End   : $END_TIME
Base  : $BASE_DIR

Success: $SUCCESS
Fail   : $FAIL
Skip   : $SKIP

Log file:
$LOG
EOF
)

echo
echo "$SUMMARY" | tee -a "$LOG"

send_email "IQ-TREE batch finished (${SUCCESS} ok, ${FAIL} failed)" "$SUMMARY" || true

echo "=== All done ===" | tee -a "$LOG"
