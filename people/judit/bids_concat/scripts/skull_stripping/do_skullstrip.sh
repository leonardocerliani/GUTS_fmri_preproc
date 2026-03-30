#!/bin/bash
# =============================================================================
# do_skullstrip.sh
#
# For each subject: copies the T1w scan from the source BIDS tree into the
# destination BIDS-concat tree, then runs the full skull-stripping pipeline:
#   1. fslreorient2std   → *_T1w_reorient.nii.gz
#   2. flirt -applyisoxfm 1  → *_1mm_T1w.nii.gz
#   3. SynthStrip (Docker)   → *_1mm_T1w_brain.nii.gz + *_brain_mask.nii.gz
#
# All subjects in list_subj.txt are processed in parallel (up to 5 at a time).
#
# Usage (self-contained, no arguments needed):
#   bash skull_stripping/do_skullstrip.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUBJ_LIST="${SCRIPT_DIR}/../list_subj.txt"

orig_root="/data00/EmoReg_running_analyses/preprocessing_2026/source_data/bids_LC/data"
dest_root="/data00/leonardo/GUTS_fmri_preproc/people/judit/bids_concat/data"

# ---------------------------------------------------------------------------
process_subject() {
    sub=$1

    echo "[$sub] Starting ..."

    src_anat="${orig_root}/${sub}/ses-01/anat"
    dst_anat="${dest_root}/${sub}/anat"

    # ------------------------------------------------------------------
    # 0. Create destination anat directory if it doesn't exist
    # ------------------------------------------------------------------
    mkdir -p "${dst_anat}"

    # ------------------------------------------------------------------
    # 1. Copy original T1w to destination
    # ------------------------------------------------------------------
    src_t1="${src_anat}/${sub}_ses-01_acq-WIPacqMPRAGE_rec-EmoReg_T1w.nii.gz"

    if [ ! -f "${src_t1}" ]; then
        echo "[$sub] ERROR: source T1w not found: ${src_t1}" >&2
        return 1
    fi

    cp "${src_t1}" "${dst_anat}/"
    dst_t1="${dst_anat}/${sub}_ses-01_acq-WIPacqMPRAGE_rec-EmoReg_T1w.nii.gz"
    echo "[$sub] Copied T1w → ${dst_anat}"

    # ------------------------------------------------------------------
    # 2. Reorient to standard orientation
    # ------------------------------------------------------------------
    dst_reorient="${dst_t1/T1w/T1w_reorient}"
    fslreorient2std "${dst_t1}" "${dst_reorient}"
    echo "[$sub] Reoriented → $(basename ${dst_reorient})"

    # ------------------------------------------------------------------
    # 3. Resample to 1mm isotropic
    # ------------------------------------------------------------------
    dst_1mm="${dst_t1/T1w/1mm_T1w}"
    flirt -in  "${dst_reorient}" \
          -ref "${dst_reorient}" \
          -applyisoxfm 1 \
          -out "${dst_1mm}"
    echo "[$sub] Resampled to 1mm → $(basename ${dst_1mm})"

    # ------------------------------------------------------------------
    # 4. SynthStrip skull stripping
    # ------------------------------------------------------------------
    dst_brain="${dst_t1/T1w/1mm_T1w_brain}"
    dst_mask="${dst_t1/T1w/1mm_T1w_brain_mask}"

    "${SCRIPT_DIR}/synthstrip-docker" \
        -i "${dst_1mm}" \
        -o "${dst_brain}" \
        -m "${dst_mask}" \
        -t 10 \
        --no-csf

    echo "[$sub] SynthStrip done → $(basename ${dst_brain})"
    echo "[$sub] All steps complete."
}

# Make paths and function available to child processes spawned by xargs
export orig_root dest_root SCRIPT_DIR
export -f process_subject

# ---------------------------------------------------------------------------
# Run all subjects in parallel (up to 5 at a time, one subject per job)
# ---------------------------------------------------------------------------
echo "Processing subjects from: ${SUBJ_LIST}"
echo "Source : ${orig_root}"
echo "Dest   : ${dest_root}"
echo ""

xargs -a "${SUBJ_LIST}" -n 1 -P 5 bash -c 'process_subject "$@"' _
