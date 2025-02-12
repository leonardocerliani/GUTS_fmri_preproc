#!/bin/bash

# Assuming that all the BOLD scans have n_slices slices
# NB: there should be a space in front of the number of slices!
# Check your own PAR file to determine if this holds for you
n_slices=" 40"

[ -f PARs_NOT_TRIMMED.txt ] && rm PARs_NOT_TRIMMED.txt

# Check for input file argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_PAR_file>"
    exit 1
fi

file="$1"
backup="${file}_OLE"

# Create a backup
cp "${file}" "${backup}"
echo "Backup created: ${backup}"

# Find the last line number where the line starts with "40"
last_complete_acq_line=$(grep -n "^${n_slices}" "${file}" | tail -n1 | awk -F: '{print $1}')

# If no line starts with 40, exit without modifying the file
if [ -z "${last_complete_acq_line}" ]; then
    echo "${file} : No line starting with ${n_slices} found. No changes made."
    echo "${file}" >> PARs_NOT_TRIMMED.txt
    exit 0
fi

# Trim the file up to and including the last "40" line
echo "Trimming ${file}"
head -n "${last_complete_acq_line}" "${backup}" > "${file}"

