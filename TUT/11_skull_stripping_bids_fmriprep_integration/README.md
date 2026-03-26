# Skullstrip with synthstrip and integration with fmriprep

LC 2026-02-26

Sometimes the skull strip carried out by `fmriprep` - which uses `ANTs` internally - gives suboptimal results, especially with a peculiar dataset. 

[`synthstrip`](https://surfer.nmr.mgh.harvard.edu/docs/synthstrip/) ([docker hub](https://hub.docker.com/r/freesurfer/synthstrip) and [nipreps](https://github.com/nipreps/synthstrip)) appears to give very good results in most cases, and can be therefore used as an alternative to ANTs inside fmriprep. This means
- first carrying out the skullstrip using synthstrip
- then carrying of fmriprep preprocessing using the result of synthstrip

In `fmriprep` it is not possible - at least for now - to inform about a specific pre-calculated brain mask. However it is possible to force `fmriprep` _not_ to carry out skull stripping. 

However in this case the data structure turns out to be confusing for the user, since the `*T1w.nii.gz` file (and its associated `json` sidecar) actually refer to the _already skull stripped T1w_. 

In addition, we want to keep the original (not skull stipped) T1w image for later processing with `fsl`, as the elastic (`fnirt`) registration to the MNI expects the original image with the skull in addition to the skull stripped image.

One solution is to adopt the following data structure

```bash
anat
├── sub-gutsaumc0005_ses-01_T1w.json
└── sub-gutsaumc0005_ses-01_T1w.nii.gz
anat_ORIG
├── sub-gutsaumc0005_ses-01_ORIG_T1w.nii.gz
├── sub-gutsaumc0005_ses-01_ORIG_T1w_brain.nii.gz
└── sub-gutsaumc0005_ses-01_ORIG_T1w_brain_mask.nii.gz
```

In which 
- the`anat_ORIG` image contains the ORIGinal non skull stripped image `*_ORIG_T1w.nii.gz` as well as the one after skull stripping (`_brain`) and the binary mask (`_brain_mask`) 
- `*_T1w.nii.gz` and `*_ORIG_T1w_brain.nii.gz` are actually _the same skull stripped image image_
- in addition, a `.bidsignore` text file must be provided in order for fmriprep to ignore the `anat_ORIG`

The `.bidsignore` file will contain the following:
```bash
**/anat_ORIG/**
**ORIG**
```

Optionally, before carrying out `synthstrip`, we will can do one pass of inhomogeneity correction on the original T1w image, using `N4BiasFieldCorrection` provided by `ANTs`. This might not be necessary (e.g. if you do not have `ANTs` installed on your server/computer), but it's for sure not harmful.  

**Importantly**, we will create the `anat_ORIG` _before_ launching synthstrip, so that the function we will create to run the skull strip is technically pure, i.e. it can be run on the same initial input (e.g. by mistake on a structure where skull strip has already been carried out) without risk of running on the wrong files or producing an output different from what expected.


## `do_synthstrip.sh`
The example provided here is in the bash script `do_synthstrip.sh`. In order to run this it is necessary to already have the `synthstrip-docker` bash script. 

### Requirements to run `synthstrip-docker`

- Make sure you have docker installed on your system and you are part of the docker group. I assume you are on a linux machine, and you can check if you are part of the docker group with `id [your username]` from the terminal.

- The freesurfer website where the documenation and the original synthstrip-docker is provided is actually down, but the copy in this repo works well. If the [synthstrip docker image](https://hub.docker.com/r/freesurfer/synthstrip) is not already present, it will be downloaded while running the `synthstrip-docker` script.

- If your files are mounted from a windoze server, you need to make a small modification to the `synthstrip-docker` script (already present in the version provided here):

```bash
# Set UID and GID to avoid output files owned by root
# user = '-u %s:%s' % (os.getuid(), os.getgid())
user = ""  # instead of '-u %s:%s' % (os.getuid(), os.getgid())
```

### Procedure to integrate synthstrip with fmriprep
The comments in `do_synthstrip.sh` should be pretty self explanatory. Here are the main steps:

We use the following data structure:
```
# sub-gutsaumc0002
# └── ses-01
#     ├── anat
#     │   ├── sub-gutsaumc0002_ses-01_acq-ses01_T1w.json
#     │   ├── sub-gutsaumc0002_ses-01_acq-ses01_T1w.nii.gz
#     ├── anat_ORIG
#     │   ├── sub-gutsaumc0002_ses-01_acq-ses01_ORIG_T1w.nii.gz
```

- synthstrip is run on the `anat_ORIG/ORIG_T1w.nii.gz` file which is actually a copy of the original `anat/T1w.nii.gz` file created by the bidscoiner

- the script first checks if the `anat_ORIG` directory is present, otherwise it creates it and copies the original T1w in `/anat`

- synthstrips creates the files `anat_ORIG/ORIG_T1w_brain.nii.gz` and `anat_ORIG/ORIG_T1w_brain_mask.nii.gz` files

- finally, the `anat_ORIG/ORIG_T1w_brain.nii.gz` is written onto the `anat/T1w_brain.nii.gz` file. This is the skull-stripped T1w image that will be fed into fmriprep


### `.bidsignore`
Since we created this new `ORIG_anat` folder, we need to instruct the fmrivalidator/fmriprep to ignore it. This can be achieved by creating a text file called `.bidsignore` in the main `bids` folder (<-- location to check).

```
**/anat_ORIG/**
**ORIG**
```

If later we wish to create other files which are not included in the original bids folder - for instance a `T1w_MRGNCY.nii.gz` to save the original file in the `/anat` directory - we can also add them to the `.bidsignore` file.


## Launching the procedure in parallel
In order to run this in parallel, a `subject_list.txt` with the subjects' ids should be prepared like the one in the present repo.

Then, it is as simple as 

```bash
cat ${subject_list} | xargs -P 3 -I{} ./do_synthstrip.sh {} &
```

where `-P 3` is the number of processes that one wants to run in parallel.

The process should take about 15-20 seconds per T1w image.

All this is contained in the `launch_synthstrip.sh` script, which also quckly creates an HTML page with an overview of the results for all subjects, accessible in the directory `slicesdir`.

A different method for creating the overlay to inspect the results of the segmentation is described in the `do_overlay.sh` script [in this repo](https://github.com/leonardocerliani/GUTS_fmri_preproc/tree/main/TUT/10_skull_stripping)
