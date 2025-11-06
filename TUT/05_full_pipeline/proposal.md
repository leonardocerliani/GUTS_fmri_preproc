# Proposal for a full preprocessing pipeline

LC Nov 2025

Very schematic work in progress.

## Architecture
I believe it is very important to use isolated, reproducible computing environments, therefore:
- whatever can be done in a docker container will be done in a docker container
- for processes requiring python, a venv will be created and frozen in a `requirements_[processName].txt`. Once all the python processes have been determined, we can try to see if it is possible to have only one global requirements.txt

## Bidscoin
This will bring the data in bids structure, so that one can easily apply bidsapps on it like MRIqc or fmriprep

## Keep an eye on computational resources
It is extremely important that guardrails are imposed on resource-greedy processes like ANTs. These are not setup by default, since most people still run them on their own laptop (!)

## Keep fmriprep minimal, decide confounds later
fmriprep allows to actually get preprocessed images, however this means that if the choices of the e.g. confounds to be used change later on, fmriprep has to be run again.

Instead, the idea is to use fmriprep _exclusively_ to get the following ouput:
- tsv of confounds
- transformation matrices and warpfields between fmri <-> T1w <-> MNI
- intensity-normalized T1w and T1w brain mask estimated by ANTs 

After fmriprep has finished (run in parallel for n subs), we can then discard all the temporary files (which are enormous) and maintain a very light diskspace footprint.

At this point, we can have a single small bash script that does only one thing: regress the confouds from the native raw data (fsl_regfilt). Then the rest can be done in fsl (see below)

## Preprocessing in fsl
fsl will be fed with:
- intensity-normalized T1w and T1w_brain
- raw fmri data - after confound regression

The motivation behind using fsl is that it has an integrated data structure which makes easy to:
- monitor the log and the ouput of all the steps in an html / text file log
- go back and forth between native fmri and MNI space
- carry out group analyses

The last one is key. Most of the time is actually spent in preprocessing the data, while group-level analyses (at least the simple ones like a GLM) take little time. By isolating the confound regression from the rest of the preprocessing and the native-space from group-level analyses, we can decide to change the confound regression / preprocessing choices and run again the whole group-level analysis in a resonable amount of time. For instance:

**Medium dataset and medium preprocessing / first level time / computing resources : ~ 20hrs**
- dataset: 400 runs (e.g. 400 participants with 1 run each or 100 with 4 runs each) 
- running 20 runs at once
- 60 minutes for each run


**Large dataset and long preprocessing / first level time / computing resources - ~ 40 hrs**
- dataset: 1000 runs (e.g. 1000 participants with 1 run each or 250 with 4 runs each) 
- running 50 runs at once
- 120 minutes for each run



