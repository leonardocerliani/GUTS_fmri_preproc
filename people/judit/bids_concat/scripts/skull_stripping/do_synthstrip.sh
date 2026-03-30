#!/bin/bash

sub=$1

root="/data00/EmoReg_running_analyses/preprocessing_2026/source_data/bids_LC/data"

anat=${root}/${sub}/ses-01/anat/${sub}_ses-01_acq-WIPacqMPRAGE_rec-EmoReg_T1w.nii.gz

# Step 1: Reorient to standard (intermediate file)
anat_reorient=${anat/T1w/T1w_reorient}
fslreorient2std ${anat} ${anat_reorient}

# Step 2: Resample to 1mm isotropic
anat_1mm=${anat/T1w/1mm_T1w}
flirt -in ${anat_reorient} \
      -ref ${anat_reorient} \
      -applyisoxfm 1 \
      -out ${anat_1mm}

# Step 3: Run SynthStrip on the preprocessed image
./synthstrip-docker \
  -i ${anat_1mm} \
  -o ${anat/T1w/1mm_T1w_brain} \
  -m ${anat/T1w/1mm_T1w_brain_mask} \
  -t 10 \
  --no-csf


