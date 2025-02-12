#!/bin/bash

# Directory where to search the PAR files
export root="PARREC"
# export root="tmp"

# Pattern to search for filenames to trim (bold acquisitions)
export pattern="BOLD" # If no pattern is passed, it defaults to "BOLD"

# Define number of slices (NB: space before the number!)
export n_slices=" 40"

# --- DO NOT TOUCH BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING --


# Remove old list of untrimmed files (clear the file if it exists)
NOT_TRIMMED="NOT_TRIMMED.txt"
> "$NOT_TRIMMED"  # This clears the file without race conditions

# Find all files containing the specified pattern in their name
mapfile -t files < <(find ${root} -type f -name "*$pattern*.PAR")

# Show all the files
printf "%s\n" "${files[@]}" | xargs -n 1

# Ask for confirmation
read -p "Do you want to proceed with trimming these files? (y/N): " confirmation

# If the user types "y", proceed; otherwise, exit
if [[ "$confirmation" != "y" ]]; then
    echo "Aborted. No files will be processed."
    exit 0
fi

# If no files are found, exit
if [ "${#files[@]}" -eq 0 ]; then
    echo "No files found matching pattern '$pattern'. Exiting."
    exit 0
fi

# Function to trim the PAR file
trim_par_file() {
    local file="$1"
    local backup="${file}_ORIGINAL"

    # Create a backup
    cp "${file}" "${backup}"
    # echo "Backup created: ${backup}"

    # Find the last line number where the line starts with the defined number of slices
    last_complete_acq_line=$(grep -n "^${n_slices}" "${file}" | tail -n1 | cut -d: -f1)

    # If no line starts with the specified pattern, skip the file and log it
    if [ -z "${last_complete_acq_line}" ]; then
        echo "${file} : No line starting with ${n_slices} found. No changes made."
        echo "${file}" >> "$NOT_TRIMMED"
        return
    fi

    # Trim the file up to and including the last ${n_slices} line
    echo "Trimming ${file}"
    head -n "${last_complete_acq_line}" "${backup}" > "${file}"
}

export -f trim_par_file  # Make the function available to xargs

# Process all files in parallel using xargs
echo
echo "Processing ${#files[@]} files matching pattern '$pattern'..."

Serial
for file in "${files[@]}"; do
    trim_par_file "$file"
done


# # Parallel
# printf "%s\n" "${files[@]}" | xargs -n 1 -P 4 -I {} bash -c 'trim_par_file "$@"' _ {}


echo "Processing complete. Untrimmed files (if any) logged in '$NOT_TRIMMED'."



