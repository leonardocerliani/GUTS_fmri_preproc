#!/bin/bash

# Usage: ./convert_PARREC_2_nii.sh
#
# NB: requires the Octave script run_dicm2nii.m in the same directory
#     scroll to the bottom for a copy of this script
# 
# Converts the PAR/REC present in the orig folder and sends the .nii(.gz) to the dest folder
# Assumes the following directory tree for each sub
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
# - orig_root
# - dest_root
# - full path to sub_list containing sub numbers already zeropadded! One per line
# - n_processes to be run in parallel
# - fmt : format of the output : 0 = .nii, 1 = .nii.gz - see all codes in dicm2nii.m
#
# Also, you can choose between two procedures (by uncommenting the chosen below):
# - Destructive : replaces all the subs' folders in ${dest} created by previous run of this (or similar) script
# - Incremental : converts only the subs in the sub_list which are NOT already present in ${dest}
#
# LC - june 2024

sub_list="sub_list.txt" # full path to the subject list file./
n_processes=20  # be considerate with the available resources

launch_octave_conversion() {
    local sub=$1

    # # FOR TESTING ONLY
    # orig_root="/data00/leonardo/oda/fmri_preproc/simulate_data06"
    # dest_root="/data00/leonardo/oda/fmri_preproc/raw_data"
    
    # REAL DEAL
    orig_root="/data06/EmoReg/EmoReg/Data_collection/subs"
    dest_root="/data06/EmoReg/EmoReg/Data_collection/raw_data"
    

    # make one pass for ses-1 and another for ses-2
    for ses in 01 02; do
        for scan_type in anat func; do

            orig=${orig_root}/sub-${sub}/ses-${ses}/${scan_type}
            dest=${dest_root}/sub-${sub}/ses-${ses}/${scan_type}
            fmt=1   # 0 = .nii, 1 = .nii.gz - see all codes in dicm2nii.m

            # Destructive version : replaces every previous dest file/dir
            [ -d ${dest} ] && rm -rf ${dest}
            mkdir -p ${dest}  
            octave run_dicm2nii.m ${orig} ${dest} ${fmt}

            # # Incremental version : only converts files if anat/func do *NOT* exist yet
            # [ ! -d ${dest} ] && octave run_dicm2nii.m ${orig} ${dest} ${fmt}

            
        done
    done

}

export -f launch_octave_conversion

cat ${sub_list} | xargs -P ${n_processes} -I{} bash -c 'launch_octave_conversion {}'



#    % run_dicm2nii.m
#    % run from terminal with:
#    % octave run_dicm2nii.m [/path/to/PARREC] [/path/to/destination] [fmt]
#    % 
#    % update the location of dicm2nii
#
#    orig = argv(){1};  % PARREC location
#    dest = argv(){2};  % raw_data location
#    fmt = str2num(argv(){3});  % Convert fmt to a number
#
#    addpath(genpath('/data00/leonardo/warez/dicm2nii'))
#    dicm2nii(orig, dest, fmt)


