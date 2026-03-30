# FSL FEAT 1st-Level Analysis

This folder contains the scripts and configuration files to build per-subject
FEAT design files and run the 1st-level GLM analysis on the 10-run concatenated
fMRI data produced by the `concatenation/` pipeline.

---

## File inventory

| File | Purpose |
|------|---------|
| `design_example.fsf` | Reference FSF created in the FEAT GUI for sub-001 — provides all global settings (registration, filtering, etc.). The EV and contrast sections are **ignored** at runtime. |
| `list_predictors.csv` | One row per EV: `name, include (0/1), temporal_derivative (0/1)`. Edit to add/remove EVs or toggle derivatives. |
| `list_contrasts.txt` | One contrast per line: `name : pos_EV > neg_EV`. Edit to change contrasts. |
| `build_design_fsf.py` | Python script — reads the three files above and writes `design_<sub>.fsf` for every subject. |
| `run_build_design_fsf.sh` | Shell wrapper — activates venv and calls `build_design_fsf.py`. |
| `run_feat.sh` | Shell script — launches `feat` for all subjects in parallel (nohup-safe). |
| `run_check_designs.sh` | Shell script — prints and validates key FSF parameters against the actual fMRI file (npts, totalVoxels). |
| `do_test_cropped_fmri_data.sh` | Interactive copy-paste blocks for quickly testing the FEAT pipeline (backup, crop, run, restore). |
| `mini_list_subj.txt` | Short subject list for quick testing. |

---

## Data layout expected by FEAT

```
bids_concat/data/<sub>/
├── func/
│   └── <sub>_task-EmoReg_bold.nii.gz          ← 4D input (all 10 runs)
├── anat/
│   └── <sub>_ses-01_..._1mm_T1w_brain.nii.gz  ← skull-stripped structural
└── beh/
    ├── <sub>_<predictor>_events.mat            ← one per condition (3-col FSL format)
    └── <sub>_run-0N_events.mat                 ← 10 run-regressor nuisance EVs
```

---

## Customising the design

### Add / remove EVs
Edit `list_predictors.csv` — set `include` to `1` to include, `0` to exclude.  
Set `temporal_derivative` to `1` to add a temporal derivative, `0` for none.

> ⚠️ Do **NOT** include `fixation_ISI` or `fixation_ITI` — these are the
> implicit baseline and should not be modelled.

### Add / modify contrasts
Edit `list_contrasts.txt`. One contrast per line:
```
name : positive_EV_name > negative_EV_name
```
EV names are matched case-insensitively; the `_events` suffix is optional.

---

## Running the analysis

### Step 1 — generate per-subject design files

```bash
cd /data00/leonardo/GUTS_fmri_preproc/people/judit/bids_concat/scripts
bash 1st_level_analysis/run_build_design_fsf.sh
```

### Step 2 — (optional) validate design files

```bash
bash 1st_level_analysis/run_check_designs.sh
```

Prints for each subject:
- `outputdir`, `npts`, `regstandard`, `reg nonlinear`, `totalVoxels`, `feat_files(1)`, `highres_files(1)`
- Cross-checks `npts` and `totalVoxels` against `fslinfo` → reports `CORRECT` / `WRONG`

### Step 3 — run FEAT

```bash
# All subjects — nohup (survives connection drops):
nohup bash 1st_level_analysis/run_feat.sh > logs/feat.log 2>&1 &

# Custom subject list:
nohup bash 1st_level_analysis/run_feat.sh 1st_level_analysis/mini_list_subj.txt \
    > logs/feat_mini.log 2>&1 &
```

### Monitor progress

```bash
# Outer script log (shows "Starting FEAT…" / "FEAT done." per subject):
tail -f logs/feat.log

# Per-subject FEAT internal log (actual errors live here):
cat .../data/sub-001/func/sub-001_task-EmoReg_bold.feat/logs/feat2

# All subjects at once:
tail -n 20 /data00/leonardo/GUTS_fmri_preproc/people/judit/bids_concat/data/sub-*/func/*.feat/logs/feat2
```

> **Note:** `feat` logs its own output to `.feat/logs/feat2` (and `feat3`, `feat4` for
> subsequent stages), not to our nohup log. If a subject shows "Starting FEAT…" but
> never "FEAT done.", check `.feat/logs/feat2` for the error.

---

## What each script does

### `build_design_fsf.py` (called by `run_build_design_fsf.sh`)
- Reads global FEAT settings from `design_example.fsf`
- Reads the EV list from `list_predictors.csv`
- Reads contrasts from `list_contrasts.txt`
- Computes `npts` and `totalVoxels` from the actual fMRI NIfTI header via nibabel
- Writes `design_<sub>.fsf` to `.../data/<sub>/func/`

### `run_feat.sh`
- Reads subject list from `list_subj.txt` (or custom list passed as argument)
- Calls `feat design_<sub>.fsf` for each subject, up to **5 jobs in parallel**
- Reduce `N_PARALLEL` inside the script if the machine is RAM-constrained

---

## Re-generating design files only (without running FEAT)

```bash
bash 1st_level_analysis/run_build_design_fsf.sh
# or directly:
source venv_judit/bin/activate
python3 1st_level_analysis/build_design_fsf.py
```

---

## Quick pipeline test (copy-paste blocks)

See `do_test_cropped_fmri_data.sh` for interactive blocks:

| Block | Action |
|-------|--------|
| **0** | Remove any existing `.feat` directories |
| **1** | Backup full files + crop to 100 volumes (parallel) |
| **2** | Rebuild FSFs + launch FEAT in background |
| **3** | Restore full fMRI files (parallel) |

> ⚠️ The cropped-data approach only works for **preprocessing-only** FSFs
> (`stats_yn = 0`). With the full GLM enabled, FEAT aborts immediately
> because 100 TRs leave near-zero degrees of freedom.

---

## FEAT output location

```
bids_concat/data/<sub>/func/<sub>_task-EmoReg_bold.feat/
```
