#!/bin/bash
# ============================================================
# run_build_design_fsf.sh
#
# Generates per-subject design_<sub>.fsf for all subjects.
#
# Usage (from the scripts/ root):
#   bash 1st_level_analysis/run_build_design_fsf.sh [list_subj.txt]
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_ROOT="${SCRIPT_DIR}/.."

SUBJ_LIST="${1:-${SCRIPTS_ROOT}/list_subj.txt}"
VENV="${SCRIPTS_ROOT}/venv_judit"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Generating design_<sub>.fsf"
echo "  Subject list : ${SUBJ_LIST}"
echo "════════════════════════════════════════════════════════"

source "${VENV}/bin/activate"
python3 "${SCRIPT_DIR}/build_design_fsf.py" "${SUBJ_LIST}"
deactivate
