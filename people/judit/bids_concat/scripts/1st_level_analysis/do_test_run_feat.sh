#!/bin/bash

data_root="/data00/leonardo/GUTS_fmri_preproc/people/judit/bids_concat/data"
SUBJ_LIST="list_subj.txt"


# BLOCK 0 — kill running FEAT / film_gls
pkill -f film_gls    # kills the slow prewhitening step
pkill -f "feat "     # kills any remaining feat wrapper processes
pkill -f run_feat.sh # kills the outer launcher script



#  BLOCK 1 : remove .feat directories from previous test 
find ${data_root} -type d -name "*.feat"
rm -rf ${data_root}/sub-*/func/*.feat
find  ${data_root} -type d -name "*.feat"


#  BLOCK 2 : rebuild fsf's after editing the design_example.fsf
bash ./run_build_design_fsf.sh
bash ./run_check_designs.sh



#  BLOCK 3 : run FEAT in background 
nohup bash ./run_feat.sh > logs/feat_test.log 2>&1 &
echo "FEAT running in background — tail -f logs/feat_test.log"


