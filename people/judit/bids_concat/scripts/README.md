# EmoReg initial preproc and analysis (5 subject subset)

```bash
# Data location

# Origin
root_orig="/data00/EmoReg_running_analyses/preprocessing_2026"

data_orig="${root_orig}/source_data/bids_LC/data"

onsets_orig="${root_orig}/derivative_1T1w/fsl_events"

# Destination
data_dest="/data00/leonardo/GUTS_fmri_preproc/people/judit/bids_concat/data"
```

FSL onset files - one for each predictor, with `.mat` extension - were created from the acquisition log files using a custom python script.

The format is the 3-column format of fsl predictor files, with columns for `onset time | duration | intensity`

⚠️ **There are 10 fmri acquisitions across two sessions. In this initial exploration, they have been concatenated _without_ registering the scans in the second session to the T1w. This will need to be added later** 

⚠️ **For testing purposes only _linear_ registration has been carried out to save on time, however the files for nonlinear registration are already in place, and one should just switch it on in the `design_example.fsf`** (see below in `1st_level_analysis`)

⚠️ **For testing purposes, prewhitening has been switched off in the `design_example.fsf`. Once we assess that feat succesfully completes all the steps, it should be switched on again - it takes ages, especially with very long time courses like the concatenated ones**

⚠️ **Before running any python script - or shell script that calls a python script - make sure you activated the appropriate venv** which in this case is called `venv_judit` and can be recreated (python 3.10+) using the `requirements.txt` file



## Overview
- **concatenation** : The 10 acquisitions from the two sessions were concatenated in one long file. This is because _events have been randomised across runs_.

- **skull_stripping** : carried out with `synthstrip`. The original T1w was first reoriented to standard orientation and then resampled to 1mm to speed up the registration. The original volume has been preserved

- **1st_level_analysis** : actually here there is both preprocessing and 1st level analysis

There are dedicated README files for concatenation and skull stripping in the corresponding directories, therefore in the following we will focus on the preparation and running of the preprocessing and first level analysis


## 1st level analysis (and preprocessing)
The current design has many predictors (I think 37) and contrasts, which makes it tedious to enter them manually in the Feat GUI - let alone doing it for all subjects - therefore a hybrid approach has been used.

### Initial simplified design in the Feat GUI
The user first opens the Feat GUI for one subject, and enters the information about:
- location of the concatenated fmri file
- location of the skullstripped T1w image
- preprocessing parameters

In addition, the user enters 2-3 predictors and at least one contrast, still in the Feat GUI.

At this point the `design.fsf` can be saved (along with many other `design.*` files which can be deleted)

Then this `design.fsf` is copied in the `scripts/1st_level_analysis` directory as `design_example.fsf`.

It will be used to generate the `design_sub-[sub number].fsf` for all subjects

### Defining predictors and contrasts in text files
Now the user can use a text editor to define two files:

#### list_predictors.csv
Comma-separated file with the predictor name - as it appears in the original .mat file but without the sub-[number] prefix, so that it is the same for all subjects. 

Additionally, there are two other columns:
- the first defines whether that predictor should be included in the design
- the second defines whether the temporal derivative of that predictor should be included in the design

#### list_contrasts.txt
A text file with the definition of the contrast name and the predictors involved. Each line has the following structure:

```
more_pain_more_money : outcome_Conflict_More_pain_events > outcome_Conflict_More_money_events
```

**NB**: one should _only use_ the `>` ("bigger than") sign. In case you want the reverse contrast, just write another line like

```
more_money_more_pain : outcome_Conflict_More_money_events > outcome_Conflict_More_pain_events
```

### Generating the design.fsf file for each subject
Now we can build the final design of interest, and do it for each subject. 

It is important to run this from the `scripts/` directory, which should contain the `list_subj.txt`

```bash
cd scripts/
bash 1st_level_analysis/run_build_design_fsf.sh
```

`run_build_design_fsf.sh` will use the following:
- `build_design_fsf.py`
- `design_example.fsf`
- `list_predictors.csv`
- `list_contrasts.txt`
- `list_subj.txt`

to generate a `design_sub-[sub number].fsf` in the same directory where the concatenated fmri nii.gz is.

Importantly, currenty - for the sake of time restrictions - the location of these files is hardcoded at the top of `build_design_fsf.py`

```bash
DATA_ROOT    = Path("/data00/leonardo/GUTS_fmri_preproc/people/judit/bids_concat/data")
SUBJ_LIST    = SCRIPT_DIR.parent / "list_subj.txt"
EXAMPLE_FSF  = SCRIPT_DIR / "design_example.fsf"
PRED_CSV     = SCRIPT_DIR / "list_predictors.csv"
CONTRAST_TXT = SCRIPT_DIR / "list_contrasts.txt"
```

Other preprocessing- or analysis-specific parameters are also hardcoded there. In the future it would be nice to parametrize all of this when calling the script.

**The obvious advantage of building the fsf programmatically** is that it is very easy to:
- build the design fsf programmatically, even for very complex designs with many predictors like this one
- modify the list of predictors to include and desired contrasts, in order to iterate across analytic choices

Once the designs .fsf files have been created, we can check the main information which vary across subjects by simply running the `run_check_design_fsf.sh` script, which will print a summary on the screen.


⚠️ **For the moment only _linear_ registration has been carried out to save on time, however the files for nonlinear registration are already in place, and one should just switch it on in the `design_example.fsf`** (see below in `1st_level_analysis`), The only thing to do is to make sure that this parameter is set to 1:

```bash
set fmri(regstandard_nonlinear_yn) 1
```

**NB**: admittedly, the `build_design_fsf.py` is probably now overcomplicated, given the very regular structure of the predictor and contrasts definition in the fsl design.fsf file. There is a lot of room for simplification and improvement.

### Running 1st level analysis
Once all the design.fsf are ready and have been checked, we can run feat for all of them in parallel. This is simply achieved using the `run_feat.sh` script.

The resulting `.feat` directories with the results are in the same location as the concatenated fmri file. Inside each `.feat` directory you can open in a browser the `report.html` file to inspect if the process is still running and the completed stages (e.g. registration and fmri preprocessing)

For the moment, 5 feat processes are running in parallel. You can change this, but be careful about your colleagues' computing needs.

**NB** this can take a really long time. If you are just testing that the pipeline concludes sucessfully, you can e.g. switch of prewhitening in the design_example.fsf

```
set fmri(prewhiten_yn) 0
```

Possibly [something else](https://neurostars.org/t/fsl-feat-takes-a-long-time-to-run/4808) can also help.


## Group-level analysis
This can be easily set up and run from the Feat GUI. The first-level contrasts are automatically imported, and the subject-specific first-level .feat results can be easily imported from the output of a `find` in the terminal.

I already prepared and ran the group-level (well, 5 subjects...) analysis. It can be inspected by opening the `Feat` gui from the terminal and loading the `group_design.fsf` file.

The results are in `scripts/group_level_analysis/results_group_level.gfeat/report.html`

