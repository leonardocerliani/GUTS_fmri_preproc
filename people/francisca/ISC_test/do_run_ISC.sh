#!/bin/bash

# https://github.com/snastase/isc-tutorial
# the script on the github has a bug: np.product --> np.prod

preproc_data_dir="/data00/leonardo/GUTS_fmri_preproc/people/francisca/preproc_data_MNI"

python isc_cli.py \
  --input ${preproc_data_dir}/*preproc_bold.nii.gz \
  --output ./results_ISC/isc.nii.gz \
  --mask ./GM_mask_bin.nii.gz \
  --zscore --fisherz \
  --verbosity 5



