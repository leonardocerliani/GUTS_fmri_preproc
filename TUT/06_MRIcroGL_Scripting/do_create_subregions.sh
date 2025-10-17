#!/bin/bash

for atlas in Yeo7 Yeo17 HO_cort AT; do 

  root=$(pwd)/${atlas}
  dest=${root}/rois

  [ ! -d ${dest} ] && mkdir ${dest}

  fsl2ascii ${root}/${atlas} ${root}/${atlas}.txt 
  cat ${root}/${atlas}.txt* | tr ' ' '\n' | sort -n | uniq | grep -v '^0$' > ${root}/rois_numba.txt
  rm ${root}/${atlas}.txt*

  for i in $(cat ${root}/rois_numba.txt); do
    # Zero-pad number to 5 digits
    i_padded=$(printf "%05d" $i)
    echo creating ${atlas}_roi_${i_padded}
    fslmaths ${root}/${atlas} -thr ${i} -uthr ${i} ${root}/rois/${atlas}_roi_${i_padded}
  done

done