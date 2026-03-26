#!/bin/bash

subject_list="./subject_list.txt"

# Launch parallel processing in background
cat ${subject_list} | xargs -P 3 -I{} ./do_synthstrip.sh {} &
JOBS_PID=$!

echo "Waiting for all synthstrip jobs to complete (PID: ${JOBS_PID})..."
wait ${JOBS_PID}
echo "All jobs completed!"

# Quick and dirty preview of the results
root="/dataGUTS2/GUTS/sample_data/bids"

# Find all ORIG_T1w and ORIG_T1w_brain files in anat_ORIG directories
imlist=$(find ${root} -path "*/anat_ORIG/*" \( -name "*ORIG_T1w.nii.gz" -o -name "*ORIG_T1w_brain.nii.gz" \))

slicesdir -o -e -0.1 ${imlist}
