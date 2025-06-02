
# Script to compute tSNR for all .nii.gz files using 20 parallel workers
# Outputs are saved in the current directory (${PWD})

# Remember to change the ownership at the end
# sudo chown -R "$USER:$USER" /path/to/dir

compute_tsnr() {
    input_file="$1"

    # Skip if it's already a tSNR file
    if [[ "$input_file" == *_tsnr.nii.gz ]]; then
        exit 0
    fi

    base=$(basename "$input_file" .nii.gz)
    mean_file="${PWD}/${base}_mean.nii.gz"
    std_file="${PWD}/${base}_std.nii.gz"
    tsnr_file="${PWD}/${base}_tsnr.nii.gz"

    # Skip if tSNR already exists
    if [[ -f "$tsnr_file" ]]; then
        echo "Skipping $input_file (tSNR already exists)"
        exit 0
    fi

    echo "Processing $input_file"
    fslmaths "$input_file" -Tmean "$mean_file"
    fslmaths "$input_file" -Tstd "$std_file"
    fslmaths "$mean_file" -div "$std_file" "$tsnr_file"

    # Clean up
    rm -f "$mean_file" "$std_file"
}

export -f compute_tsnr

preproc_data_dir="/data00/leonardo/GUTS_fmri_preproc/people/francisca/preproc_data_MNI"

find ${preproc_data_dir} -name "*preproc_bold.nii.gz" | xargs -n 1 -P 20 -I {} bash -c 'compute_tsnr "$@"' _ {}


# EOF