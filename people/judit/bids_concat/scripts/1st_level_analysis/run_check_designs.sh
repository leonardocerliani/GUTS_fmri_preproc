#!/bin/bash
# ============================================================
# run_check_designs.sh
#
# Prints and validates key parameters in design_<sub>.fsf files.
# For npts and totalVoxels, cross-checks against fslinfo output.
# Output is printed to terminal AND saved to logs/check_designs.log
#
# Usage (from the scripts/ root):
#   bash 1st_level_analysis/run_check_designs.sh [list_subj.txt]
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_ROOT="${SCRIPT_DIR}/.."

SUBJ_LIST="${1:-${SCRIPTS_ROOT}/list_subj.txt}"
data_root="/data00/leonardo/GUTS_fmri_preproc/people/judit/bids_concat/data"

# ── Log to terminal + file ────────────────────────────────────
LOG="${SCRIPT_DIR}/logs/check_designs.log"
mkdir -p "${SCRIPT_DIR}/logs"
exec > >(tee "${LOG}") 2>&1

check_subject() {
    sub="$1"
    fsf="${data_root}/${sub}/func/design_${sub}.fsf"

    echo "┌─────────────────────────────────────────────────────────────"
    echo "│  Subject : ${sub}"
    echo "│  FSF     : ${fsf}"

    if [ ! -f "${fsf}" ]; then
        echo "│  ERROR: FSF file not found!"
        echo "└─────────────────────────────────────────────────────────────"
        echo ""
        return 1
    fi

    echo "├─────────────────────────────────────────────────────────────"

    # ── Extract key settings ──────────────────────────────────
    outputdir=$(grep -E '^set fmri\(outputdir\) '              "${fsf}" | awk '{print $3}' | tr -d '"')
    npts_fsf=$(grep -E '^set fmri\(npts\) '                    "${fsf}" | awk '{print $3}')
    regstandard=$(grep -E '^set fmri\(regstandard\) '          "${fsf}" | awk '{print $3}' | tr -d '"')
    nonlinear=$(grep -E '^set fmri\(regstandard_nonlinear_yn\) ' "${fsf}" | awk '{print $3}')
    totalVoxels_fsf=$(grep -E '^set fmri\(totalVoxels\) '      "${fsf}" | awk '{print $3}')
    feat_file=$(grep -E '^set feat_files\(1\) '                "${fsf}" | awk '{print $3}' | tr -d '"')
    highres_file=$(grep -E '^set highres_files\(1\) '          "${fsf}" | awk '{print $3}' | tr -d '"')
    prewhiten=$(grep -E '^set fmri\(prewhiten_yn\) '           "${fsf}" | awk '{print $3}')

    echo "│  outputdir      : ${outputdir}"
    echo "│  npts           : ${npts_fsf}"
    [ "${nonlinear}" = "1" ] && reg_type="nonlinear" || reg_type="linear"
    echo "│  regstandard    : ${regstandard}"
    echo "│  reg nonlinear  : ${nonlinear}  (${reg_type})"
    echo "│  totalVoxels    : ${totalVoxels_fsf}"
    echo "│  feat_files(1)  : ${feat_file}"
    echo "│  highres_files  : ${highres_file}"
    [ "${prewhiten}" = "1" ] && pw_label="ON  (FILM GLS — correct for inference)" \
                             || pw_label="OFF (OLS — fast but autocorrelation not corrected)"
    echo "│  prewhitening   : ${prewhiten}  (${pw_label})"
    echo "├─────────────────────────────────────────────────────────────"

    # ── Validate against fslinfo ──────────────────────────────
    nii="${feat_file}.nii.gz"
    if [ ! -f "${nii}" ]; then
        echo "│  ✗  fMRI file not found — cannot validate npts / totalVoxels"
        echo "│     ${nii}"
    else
        dim1=$(fslinfo "${nii}" | grep '^dim1' | awk '{print $2}')
        dim2=$(fslinfo "${nii}" | grep '^dim2' | awk '{print $2}')
        dim3=$(fslinfo "${nii}" | grep '^dim3' | awk '{print $2}')
        dim4=$(fslinfo "${nii}" | grep '^dim4' | awk '{print $2}')
        totalVoxels_computed=$((dim1 * dim2 * dim3 * dim4))

        # npts check
        if [ "${dim4}" = "${npts_fsf}" ]; then
            echo "│  npts         : FSF=${npts_fsf}  fslinfo dim4=${dim4}  → CORRECT"
        else
            echo "│  npts         : FSF=${npts_fsf}  fslinfo dim4=${dim4}  → WRONG"
        fi

        # totalVoxels check
        if [ "${totalVoxels_computed}" = "${totalVoxels_fsf}" ]; then
            echo "│  totalVoxels  : FSF=${totalVoxels_fsf}  computed=${totalVoxels_computed}  (${dim1}×${dim2}×${dim3}×${dim4})  → CORRECT"
        else
            echo "│  totalVoxels  : FSF=${totalVoxels_fsf}  computed=${totalVoxels_computed}  (${dim1}×${dim2}×${dim3}×${dim4})  → WRONG"
        fi
    fi

    echo "└─────────────────────────────────────────────────────────────"
    echo ""
}

export data_root
export -f check_subject

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Design file check"
echo "  Subject list : ${SUBJ_LIST}"
echo "  Log          : ${LOG}"
echo "════════════════════════════════════════════════════════"
echo ""

while IFS= read -r sub || [[ -n "${sub}" ]]; do
    [[ -z "${sub}" ]] && continue
    check_subject "${sub}"
done < "${SUBJ_LIST}"
