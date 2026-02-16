#!/bin/bash

subject_list="/data00/leonardo/GUTS_data_analysis/subject_list.txt"

nohup cat ${subject_list} | xargs -P 3 -I{} ./do_skullstrip.sh {} &

# # Quick and dirty preview of the results
root="/dataGUTS2/GUTS/WP3/Data_analysis"
imlist=$(find ${root} \( -name "*T1w_N4.nii.gz" -o -name "*T1w_N4_brain.nii.gz" \))
slicesdir -o -e -0.1 ${imlist}


# EOF