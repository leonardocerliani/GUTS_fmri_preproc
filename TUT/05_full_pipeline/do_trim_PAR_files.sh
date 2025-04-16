#!/bin/bash

# This script handles the PAR files from an aborted acquisition, in which therefore the expected number
# of slices does not match the actual number of acquired slices. This is an issue for dcm2niix
#
# The way to deal with this is actually very simple: the PAR file is scanned and the last line starting
# with the provided n_slices (2nd argument) is retained. All the lines below that are removed. A backup with
# the original PAR file is also created (but careful, because it would be overwritten on a second pass).
#
# The two crucial lines that carry out this are:
#  local last_complete_acq_line=$(grep -n "^\s*${n_slices}" "${file}" | tail -n1 | awk -F: '{print $1}')
#  head -n "${last_complete_acq_line}" "${backup}" > "${file}"
# 
# Example usage is displayed when the script is run with no arguments
#
# LC march 2025


# Require user to enter the root directory and the number of slices
if [ "$#" -ne 2 ]; then
    echo
    echo "Usage: $0 <root_directory> <n_slices>"
    echo 
    echo "  <root_directory>  - The path to the root directory containing the .PAR files to be processed."
    echo "  <n_slices>        - The number of slices to search for in the .PAR files. The script will trim all lines"
    echo "                       in the .PAR file up to and including the last line that starts with this number."
    echo
    echo "Example: $0 /path/to/root_directory 40"
    echo 
    exit 1
fi

root_dir="${1%/}"  # Remove trailing slash if present
export n_slices="$2"

# Check if the provided directory exists
if [ ! -d "$root_dir" ]; then
    echo "Error: Directory '$root_dir' does not exist."
    exit 1
fi


# Main function to trim one PAR file
trim_par_file() {
    local file="$1"
    local backup="${file}_OLE"

    # Create a backup
    cp "${file}" "${backup}"
    # echo "Backup created: ${backup}"

    # Find the last line number where the line starts with the specified number of slices
    # Note that usually in the .PAR file the n_slices number is preceded by a space, therefore
    # the regex also matches the beginning of the line followed by any number of spaces : ^\s*
    local last_complete_acq_line=$(grep -n "^\s*${n_slices}" "${file}" | tail -n1 | awk -F: '{print $1}')


    # If no line starts with the specified number of slices, exit without modifying the file
    if [ -z "${last_complete_acq_line}" ]; then
        echo "${file} : No line starting with ${n_slices} found. No changes made."
        echo "${file}" >> PARs_NOT_TRIMMED.txt
        return
    fi

    # Print all the lines until the last line that starts with ${n_slices} into a new file
    # echo "Trimming ${file}"
    head -n "${last_complete_acq_line}" "${backup}" > "${file}"
}

export -f trim_par_file


# Remove existing log file if it exists
[ -f PARs_NOT_TRIMMED.txt ] && rm PARs_NOT_TRIMMED.txt


# Run sequentially (it takes virtually no time)
# MAKE SURE YOU SELECT ONLY BOLD PARs!
for file in $(find "$root_dir" -type f -name "*BOLD*.PAR"); do
    trim_par_file "$file" "$n_slices"
done
