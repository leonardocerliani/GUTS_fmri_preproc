#!/bin/bash

i=$1
sub=$(printf '%04d' "$i")

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=10

orig_root="/dataGUTS2/GUTS/WP3/Data_collection/newpps/raw_data/bids"
orig_path="${orig_root}/sub-gutsaumc${sub}/ses-1/anat"
orig="${orig_path}/sub-gutsaumc${sub}_ses-1_T1w.nii.gz"

dest_root="/dataGUTS2/GUTS/WP3/Data_analysis"
dest_path="${dest_root}/sub-gutsaumc${sub}/anat"
dest="${dest_path}/sub-gutsaumc${sub}_ses-1_T1w_RAW.nii.gz"

[ ! -d ${dest_path} ] && mkdir -p ${dest_path}

cp ${orig} ${dest}

# Bias Field correction
biasfield=${dest/RAW/bias}
corrected=${dest/RAW/N4}

N4BiasFieldCorrection \
  -i "${dest}" \
  -o ["${corrected}","${biasfield}"]


# # Brain extraction with ANTs - actually SynthStrip is faster and produces a better result
# antsBrainExtraction.sh \
#     -d 3 \
#     -a "${corrected}" \
#     -e "${ANTS_TEMPLATES}/Oasis/T_template0.nii.gz" \
#     -m "${ANTS_TEMPLATES}/Oasis/T_template0_BrainCerebellumProbabilityMask.nii.gz" \
#     -o "${dest_path}/out"

# # Move outputs to match your dest naming scheme
# mv "${dest_path}/outBrainExtractionBrain.nii.gz" "${dest_path}/sub-gutsaumc${sub}_ses-1_T1w_brain.nii.gz"
# mv "${dest_path}/outBrainExtractionMask.nii.gz" "${dest_path}/sub-gutsaumc${sub}_ses-1_T1w_brain_mask.nii.gz"



# Brain extraction with synthstrip
# https://surfer.nmr.mgh.harvard.edu/docs/synthstrip/
./synthstrip-docker \
  -i ${corrected} \
  -o ${corrected/T1w_N4/T1w_N4_brain} \
  -m ${corrected/T1w_N4/T1w_N4_brain_mask} \
  -t 10 \
  --no-csf
  


