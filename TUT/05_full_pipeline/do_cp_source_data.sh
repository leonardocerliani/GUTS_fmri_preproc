#!/bin/bash

source="/data06/EmoReg/Data_collection/source_data"
dest="/data00/leonardo/GUTS_fmri_preproc/TUT/05_full_pipeline"

[ ! -d ${dest} ] && mkdir ${dest}

for sub in $(cat list_subj.txt); do 
    echo "Copying " ${sub}

    for ses in $(find ${source}/${sub} -type d -name "ses*" | awk -F'/' '{print $NF}'); do

        mkdir -p ${dest}/${sub}/${ses}
        find ${source}/${sub}/${ses} -type f -exec cp {} ${dest}/${sub}/${ses}/ \;

    done
done



# EOF

