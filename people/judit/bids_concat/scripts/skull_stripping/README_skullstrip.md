# Skull Stripping

We use [synthstrip](https://surfer.nmr.mgh.harvard.edu/docs/synthstrip/) as so far we have experienced it to outperform ANTs and fsl bet, especially in peculiar datasets. It is also much faster.

- `do_skullstrip.sh` copies each subject's T1w scan from the source BIDS tree into the
destination BIDS-concat tree, then runs a three-step preprocessing pipeline:
reorientation to standard space, resampling to 1 mm isotropic resolution, and
skull stripping with [SynthStrip](https://surfer.nmr.mgh.harvard.edu/docs/synthstrip/)
(via Docker). All subjects in `list_subj.txt` are processed in parallel.

- `do_synthstrip.sh` is **NOT USED** and just left here for reference about the schematics of the pipeline.

- make sure you have `synthstrip-docker` in this directory. **Note that this is a modified version** of the one shipped on the [synthstrip](https://surfer.nmr.mgh.harvard.edu/docs/synthstrip/) page, to accommodate for our network-mounted windoze disks (`user = ""`). 


---

## Run (all subjects, in parallel)

```bash
cd /data00/leonardo/GUTS_fmri_preproc/people/judit/bids_concat/scripts
bash skull_stripping/do_skullstrip.sh
```

The script is self-contained: it reads `list_subj.txt` automatically and launches
one job per subject using `xargs`. You can adjust the `-P 5` to run more than 5 subjects at the time (be considerate!)

---

## Pipeline overview

Besides (and before) doing skullstripping, I decided to reorient the T1w to a standard orientation (to help the registration algorithm and for visualization) and to resample it to 1mm (to make registration faster). This is carried out at the beginning of `do_skullstrip.sh`. The original T1w image is preserved for posterity.

```
do_skullstrip.sh
│
├── PATHS (hardcoded at top)
│   ├── orig_root  = .../bids_LC/data          ← source
│   └── dest_root  = .../bids_concat/data       ← output
│
└── process_subject()  [called once per subject in parallel]
    │
    ├── 0. mkdir -p  dest/<sub>/anat/
    │
    ├── 1. cp  orig/<sub>/ses-01/anat/*_T1w.nii.gz
    │         → dest/<sub>/anat/
    │
    ├── 2. fslreorient2std
    │         *_T1w.nii.gz  →  *_T1w_reorient.nii.gz
    │
    ├── 3. flirt -applyisoxfm 1
    │         *_T1w_reorient.nii.gz  →  *_1mm_T1w.nii.gz
    │
    └── 4. synthstrip-docker
              *_1mm_T1w.nii.gz  →  *_1mm_T1w_brain.nii.gz
                                    *_1mm_T1w_brain_mask.nii.gz
```

---

## Output structure (per subject)

```
bids_concat/data/<sub>/anat/
├── <sub>_ses-01_acq-WIPacqMPRAGE_rec-EmoReg_T1w.nii.gz            ← copied
├── <sub>_ses-01_acq-WIPacqMPRAGE_rec-EmoReg_T1w_reorient.nii.gz
├── <sub>_ses-01_acq-WIPacqMPRAGE_rec-EmoReg_1mm_T1w.nii.gz
├── <sub>_ses-01_acq-WIPacqMPRAGE_rec-EmoReg_1mm_T1w_brain.nii.gz
└── <sub>_ses-01_acq-WIPacqMPRAGE_rec-EmoReg_1mm_T1w_brain_mask.nii.gz
```

---

## How parallelism works

```bash
# Inside do_skullstrip.sh:
export -f process_subject          # make function visible to child bash processes
xargs -a list_subj.txt \
      -n 1 \                       # one subject per invocation
      -P 5 \                       # up to 5 jobs running simultaneously
      bash -c 'process_subject "$@"' _
```

`-n 1` ensures each subject gets its own bash process.  
`-P 5` caps the concurrency at 5 (matching the number of subjects).

---

## SynthStrip options used

| Flag | Meaning |
|---|---|
| `-t 10` | use 10 threads |
| `--no-csf` | exclude CSF from the brain mask (tighter mask) |

SynthStrip is run via the local `synthstrip-docker` wrapper in this directory,
which calls the pre-pulled Docker image.

---

## Checking results with slicesdir

After the run, verify the brain masks visually. Note: `slicesdir` crashes on
long filenames — copy files to a shorter-named directory first.

```bash
root="/data00/leonardo/GUTS_fmri_preproc/people/judit/bids_concat/data"
imlist=$(find "$root" \( -name "*1mm_T1w.nii.gz" -o -name "*1mm_T1w_brain.nii.gz" \) | sort)
time slicesdir -o -e -0.1 ${imlist}
# then open slicesdir/index.html
```

**NB: slicesdir does not like long filenames**, therefore if you encounter an error, just cp the files in 
`${imlist}` somewhere else (e.g. `~/mytmpdir`), then go there and run:
```bash
slicesdir -o -e -0.1 `ls`
```

A simple way to inspect the results is by running an http server with `python -m http.server 9999`, then opening the port 9999 on the server (e.g. in VS code) and finally opening a local browser at `localhost:9999`.

