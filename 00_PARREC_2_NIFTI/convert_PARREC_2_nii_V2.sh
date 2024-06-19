#!/bin/bash

# Usage: ./convert_PARREC_2_nii_V2.sh
#
# Converts the PAR/REC present in the orig folder and sends the .nii(.gz) to the dest(ination) folder
#
# Requires Octave to be installed and available in the path to the user who runs this script.
# Test this by running in the terminal 
#   which octave
# If octave is not installed, follow instructions here: https://wiki.octave.org/Octave_for_GNU/Linux
# 
# Assumes the following directory tree for each sub in the orig (i.e. source) folder where the 
# PARREC files are stored
#
# sub-[nnn]
#     ├── ses-01
#     │   ├── anat
#     │   │   └── PARREC files
#     │   └── func
#     │   │   └── PARREC files
#     └── ses-02
#         │   └── PARREC files
#         └── func
#             └── PARREC files  
#
# Parameters to set:
# - dicm2nii_path : local dir containing the repo https://github.com/xiangruili/dicm2nii
# - orig_root : location of the PAR/REC files
# - dest_root : desired location of raw .nii(.gz) files resulting from the PARREC conversion
# - sub_list : full path to text file containing sub numbers *already zeropadded!* One sub per line
# - n_processes : number of sub to process in parallel
# - fmt : format of the output : 0 = .nii, 1 = .nii.gz - see all codes in the script dicm2nii.m
#
# Also, you can choose between two procedures (by uncommenting the chosen below):
# - Destructive : replaces all the subs' folders in ${dest} created by previous run of this (or similar) script
# - Incremental : converts only the subs in the sub_list which are NOT already present in ${dest}
#
# LC - june 2024


sub_list="/data06/EmoReg/EmoReg/Data_collection/sub_list_MINI.txt" # full path to the subject list file.

n_processes=20  # be considerate with the available resources

launch_octave_conversion() {
    local sub=$1

    # # FOR TESTING ONLY
    # orig_root="/data00/leonardo/oda/GUTS_fmri_preproc/00_PARREC_2_NIFTI/simulate_data06"
    # dest_root="/data00/leonardo/oda/GUTS_fmri_preproc/00_PARREC_2_NIFTI/raw_data"
    
    # REAL DEAL
    orig_root="/data06/EmoReg/EmoReg/Data_collection/subs"
    dest_root="/data06/EmoReg/EmoReg/Data_analysis/preprocessing/raw_data"
    

    # make one pass for ses-1 and another for ses-2
    for ses in 01 02; do
        for scan_type in anat func; do

            orig=${orig_root}/sub-${sub}/ses-${ses}/${scan_type}
            dest=${dest_root}/sub-${sub}/ses-${ses}/${scan_type}
            fmt=1   # 0 = .nii, 1 = .nii.gz - see all codes in dicm2nii.m

            # location of the dicm2nii folder containing dicm2nii.m
            dicm2nii_path=/data06/EmoReg/EmoReg/Methods_and_materials/dicm2nii

            # # Destructive version : replaces every previous *dest* file/dir
            # # NB : no *orig* folder are removed/replaced or otherwise modified in this
            # [ -d ${dest} ] && rm -rf ${dest}
            # mkdir -p ${dest}
            # octave --no-gui --eval "addpath('${dicm2nii_path}'); dicm2nii('${orig}', '${dest}', ${fmt})"
 
            # Incremental version : only converts files if anat/func do *NOT* exist yet
            if [ ! -d "${dest}" ]; then
               octave --no-gui --eval "addpath('${dicm2nii_path}'); dicm2nii('${orig}', '${dest}', ${fmt})"
            fi
 
        done
    done

}

export -f launch_octave_conversion

# Launch the process for n subjects in parallel
cat ${sub_list} | xargs -P ${n_processes} -I{} bash -c 'launch_octave_conversion {}'


