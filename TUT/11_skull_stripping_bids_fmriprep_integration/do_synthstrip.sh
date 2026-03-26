#!/bin/bash

# --------------- USER DEFINED PARAMETERS ---------------------

root="/dataGUTS2/GUTS/sample_data/bids"
T1w_ses="ses-01"

# --------------- USER DEFINED PARAMETERS ---------------------


# e.g. $1=sub-gutsaumc0002
sub=$1


# It is assumed that a bids structure is already available with the T1w image in the /anat folder.
# We will first cp the whole /anat folder to an /anat_ORIG, where we will retain the original, 
# non skull-stripped T1w.
# We aim for the following structure:
#
# sub-gutsaumc0002
# └── ses-01
#     ├── anat
#     │   ├── sub-gutsaumc0002_ses-01_acq-ses01_T1w.json
#     │   ├── sub-gutsaumc0002_ses-01_acq-ses01_T1w.nii.gz
#     │   └── sub-gutsaumc0002_ses-01_acq-ses01_T1w_MRGNCY.nii.gz  (backup for testing)
#     ├── anat_ORIG
#     │   ├── sub-gutsaumc0002_ses-01_acq-ses01_ORIG_T1w.nii.gz
#     │   ├── sub-gutsaumc0002_ses-01_acq-ses01_ORIG_T1w_brain.nii.gz
#     │   └── sub-gutsaumc0002_ses-01_acq-ses01_ORIG_T1w_mask.nii.gz
#
# Then we will carry out synthstrip on the anat_ORIG/*ORIG_T1w, 
# thereby obtaining anat_ORIG/*ORIG_T1w_brain.
# Finally we will overwrite the anat/*T1w.nii.gz with the anat_ORIG/*ORIG_T1w_brain
# which will allow us to run fmriprep forcing no skullstrip.
#
# Importantly, this intermediate step will allow us to refine the skull strip
# in case synthstrip fails, before running the whole fmriprep


anat_root="${root}/${sub}/${T1w_ses}/anat"
anat_ORIG_root="${root}/${sub}/${T1w_ses}/anat_ORIG"

# mkdir the anat_ORIG iff it's not there already
if [ ! -d "${anat_ORIG_root}" ]; then

  mkdir "${anat_ORIG_root}"
  
  # Get the T1w file and extract filename
  T1w_file=$(ls ${anat_root}/*T1w.nii.gz)
  T1w_basename=$(basename ${T1w_file})
  
  # # Make an MRGNCY backup of the initial anat/*T1w.nii.gz for testing
  # T1w_MRGNCY="${T1w_basename/T1w.nii.gz/T1w_MRGNCY.nii.gz}"
  # cp "${T1w_file}" "${anat_root}/${T1w_MRGNCY}"
  # echo "Created emergency backup: ${anat_root}/${T1w_MRGNCY}"
  
  # Create ORIG_T1w filename by replacing T1w with ORIG_T1w
  ORIG_T1w_basename="${T1w_basename/T1w/ORIG_T1w}"
  cp "${T1w_file}" "${anat_ORIG_root}/${ORIG_T1w_basename}"
  echo "Created original copy: ${anat_ORIG_root}/${ORIG_T1w_basename}"

fi


# run synthstrip
ORIG_T1w_file=$(ls ${anat_ORIG_root}/*ORIG_T1w.nii.gz)
echo "Running synthstrip on: ${ORIG_T1w_file}"

time ./synthstrip-docker \
  -i ${ORIG_T1w_file} \
  -o ${ORIG_T1w_file/ORIG_T1w/ORIG_T1w_brain} \
  -m ${ORIG_T1w_file/ORIG_T1w/ORIG_T1w_mask} \
  -t 10 \
  --no-csf


# Overwrite the original T1w in anat with the skull-stripped version
ORIG_T1w_brain=$(ls ${anat_ORIG_root}/*ORIG_T1w_brain.nii.gz)
T1w_file=$(ls ${anat_root}/*T1w.nii.gz)
cp "${ORIG_T1w_brain}" "${T1w_file}"

echo "Done! Skull-stripped brain copied to ${T1w_file}"
