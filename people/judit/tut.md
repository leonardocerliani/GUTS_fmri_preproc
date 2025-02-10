# Basics of bash


```bash
# useful commands to know by heart 

# check the running processes
btop
# if not installed:
sudo apt install btop

# list all files (including hidden)
ls -lha

# create an alias (to be put in ~/.bashrc)
alias l="ls -lha" 

# view the tree of subdir
tree 

# self-explanatory
mkdir 
rm 
mv 
cp
cp -r


# find all the files with a given pattern/extension
find . -type f -name "*.PAR"

# get the size of a dir
du -sh [dir]




# for all the rest there are LLMs...
# for instance: removing the last 4 - uninformative - chars at the end of the nii.gz files
find nii -type f -name "*.nii.gz" | while read file; do
    new_name=$(echo "$file" | sed -E 's/_[0-9]+_[0-9]+\.nii\.gz$/\.nii\.gz/')
    if [[ "$file" != "$new_name" ]]; then
        mv "$file" "$new_name"
    fi
done




# create local and environmental variables
mypath="/data00/leonardo/GUTS_fmri_preproc/people/judit"
export mypath="/data00/leonardo/GUTS_fmri_preproc/people/judit"
sub_list="${root}/preproc/00_PARREC_2_NIFTI/sub_list.txt" # full path to the subject list file.

```