#!/bin/bash
# ============================================================
# run_feat.sh
#
# Runs FSL FEAT for all subjects in parallel.
# Reads design_<sub>.fsf from each subject's func/ directory.
#
# Usage (from the scripts/ root):
#   bash 1st_level_analysis/run_feat.sh [list_subj.txt]
#
# With nohup (survives connection drop):
#   nohup bash 1st_level_analysis/run_feat.sh > logs/feat.log 2>&1 &
#
# Custom subject list:
#   nohup bash 1st_level_analysis/run_feat.sh 1st_level_analysis/mini_list_subj.txt > logs/feat_mini.log 2>&1 &
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_ROOT="${SCRIPT_DIR}/.."

SUBJ_LIST="${1:-${SCRIPTS_ROOT}/list_subj.txt}"
data_root="/data00/leonardo/GUTS_fmri_preproc/people/judit/bids_concat/data"
N_PARALLEL=5

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Running FEAT (max ${N_PARALLEL} parallel jobs)"
echo "  Subject list : ${SUBJ_LIST}"
echo "════════════════════════════════════════════════════════"
echo ""

run_feat_sub() {
    sub="$1"
    fsf="${data_root}/${sub}/func/design_${sub}.fsf"
    if [ ! -f "${fsf}" ]; then
        echo "[${sub}] ERROR: design file not found: ${fsf}" >&2
        return 1
    fi
    echo "[${sub}] $(date '+%H:%M:%S')  Starting FEAT ..."
    feat "${fsf}"
    echo "[${sub}] $(date '+%H:%M:%S')  FEAT done."
}

export data_root
export -f run_feat_sub

xargs -a "${SUBJ_LIST}" -n 1 -P "${N_PARALLEL}" bash -c 'run_feat_sub "$@"' _

echo ""
echo "════════════════════════════════════════════════════════"
echo "  All FEAT runs complete."
echo "════════════════════════════════════════════════════════"
