#!/bin/bash

# Simple bash script to generate a self-contained html with transparent brain mask overlays
# over t1w images out of the fmriprep derivatives. See below for the expected fmriprep/derivatives structure.
#
# Dependencies: fsl overlay and slices; pandoc
#
# Usage: 
# - cd to fmriprep/derivatives directory
# - run ./do_overlay.sh (make sure it's executable, or chmod +x do_overlay.sh)
# - index.html and index.md in ./brain_mask_QC
# 
# If working on a remote server, you can then serve this on a port and view it in your browser
# after opening that ssh port in the connection, e.g.
# [on the server] python -m http.server 9999
# [on your computer] browser -> localhost:9999


export dest="brain_mask_QC"
[ ! -d ${dest} ] && mkdir -p ${dest}

subs=($(ls | grep "sub*"))
# echo ${subs[@]}

create_overlay() {
  local sub=$1
  mask=$(find . -name "${sub}_desc-brain_mask.nii.gz")
  t1=$(find . -name "${sub}_desc-preproc_T1w.nii.gz")

  echo ${t1} ${mask}

  overlay 1 0 \
    ${t1} -A \
    ${mask} 0.99 2 \
    ${dest}/${sub}_overlay.nii.gz
    
  slicer ${dest}/${sub}_overlay.nii.gz -S 10 2000 ${dest}/${sub}_montage.png
  rm ${dest}/${sub}_overlay.nii.gz

}


export -f create_overlay
printf '%s\n' "${subs[@]}" | xargs -n1 -P20 -I{} bash -c 'create_overlay "$@"' _ {}


# Create md with all the images
md="${dest}/index.md"

# start Markdown
echo "# Brain Mask QC" > "$md"

# loop over PNGs
for img in "$dest"/sub-*_montage.png; do
  sub=$(basename "$img" _montage.png)  # extract subject name
  echo "## $sub" >> "$md"
  echo "![$sub]($(basename "$img"))" >> "$md"
  echo >> "$md"  # empty line for spacing
done

echo "Markdown page created: $md"


pandoc "$md" \
  -o "${dest}/index.html" \
  --embed-resources \
  --standalone \
  --css "body { font-family: sans-serif; max-width: 800px; margin: auto; } img { max-width: 100%; height: auto; }"




# # Expected fmriprep/derivatives structure
# sub-11/
# ├── anat
# │   ├── sub-11_desc-brain_mask.nii.gz
# │   ├── sub-11_desc-preproc_T1w.nii.gz
# sub-99/
# ├── anat
# │   ├── sub-99_desc-brain_mask.nii.gz
# │   ├── sub-99_desc-preproc_T1w.nii.gz