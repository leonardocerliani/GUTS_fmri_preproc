# Try also removing the -p option
slicesdir -o -p $(find preproc_data_MNI -type f -name "sub-*_space-MNI152NLin2009cAsym_res-2_desc*.nii.gz" | sort -r)