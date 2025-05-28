## MNI in 3mm

Good that you found templateflow! In order to resample the template to 3mm you can use

```bash
mni_1mm="tpl-MNI152NLin2009cAsym_res-01_T1w.nii.gz"
 
flirt -in ${mni_1mm} -ref ${mni_1mm} -applyisoxfm 3 -out mni_3mm
```

## Slicesdir
This is to verify that the brain extraction and subsequent normalization went well. Don't be scared of the command inside the parenthesis, it's just to find the right files to pass to `slicesdir`

```bash
# Try also removing the -p option
slicesdir -o -p $(find . -path "*/anat/*" -type f -name "sub-*_space-MNI152NLin2009cAsym_res-2_desc*.nii.gz" | sort -r)
```

## Shared directory (at your own discretion)
Instructions [here](https://github.com/leonardocerliani/machines_setup/blob/main/linux_shared_directory.md)

In any case, you should fix the permissions after you run docker (fmriprep/halfpipe/mriqc) otherwise you cannot do anything with the files.

Should be something like the following, but make some test first (I am also learning it now)

```bash
sudo chown -R $USER:$USER /path/to/fmriprep/output
```


## Motion check
Calculate distribution of FD and identify those sub/run/task which are above 1/2 std

## Remove nipype dir 
As soon as possible. It's very heavy


## Run ISFC
Using the python script by ... and then display the results in an interactive HTML page using the papaya widget. Instructions [here](https://github.com/leonardocerliani/GUTS_fmri_preproc/tree/main/TUT/02_papaya_R_nifti_viewer)

