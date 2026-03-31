# fMRI + Onset Concatenation

`do_concatenate_fmri_onset_files.py` concatenates the 10 fMRI runs of a single subject
(5 from `ses-01`, 5 from `ses-02`) into one 4D NIfTI file using `fslmerge -t`, and produces
one FSL 3-column EV file per predictor with onset times correctly shifted to be relative to
the start of the concatenated timeseries. It also writes 10 run-regressor EV files to use
as nuisance regressors in FEAT to account for between-run baseline shifts.

⚠️ The concatenation done here is very blunt - just concat the original fmri nii.gz. For a proper concatenation you should first (at least) register to the T1w the runs which were acquired in a session where the T1w image was not acquired. I suggest _not_ to carry out preprocessing of the single runs because the outcome will not substantially differ wrt preprocessing the concatenated dataset (and it would make the pipeline unnecessarily more complicated).

---

## Run in parallel (all subjects)

```bash
cd /data00/leonardo/GUTS_fmri_preproc/people/judit/bids_concat/scripts
mkdir -p logs

source venv_judit/bin/activate

while read subj; do
    nohup python concatenation/do_concatenate_fmri_onset_files.py "$subj" \
        > logs/${subj}_concat.log 2>&1 &
done < list_subj.txt
```

## Run for a single subject

```bash
subj=sub-001
python concatenation/do_concatenate_fmri_onset_files.py "$subj"
```

---

## Output structure

```
bids_concat/data/<sub>/
├── func/
│   └── <sub>_task-EmoReg_bold.nii.gz      ← all 10 runs concatenated
└── beh/
    ├── <sub>_<predictor>_events.mat        ← one file per predictor
    └── <sub>_run-01_events.mat … run-10    ← run-regressor EVs
```

---

## Functions

### `fslinfo(fmri_path)`
Calls the FSL command `fslinfo` on a NIfTI file and returns its header fields as a
dictionary.

```python
def fslinfo(fmri_path: Path) -> dict:
    result = subprocess.run(["fslinfo", str(fmri_path)], capture_output=True, text=True, check=True)
    info = {}
    for line in result.stdout.splitlines():
        parts = line.split()
        if len(parts) >= 2:
            info[parts[0]] = parts[1]
    return info
```

Used internally by `get_run_duration()` to retrieve `dim4` (number of volumes) and
`pixdim4` (TR in seconds).

---

### `get_run_duration(fmri_path)`
Returns the total duration of a run in seconds: `TR × n_volumes`.

```python
def get_run_duration(fmri_path: Path) -> float:
    info = fslinfo(fmri_path)
    n_vols = int(info["dim4"])
    tr = float(info["pixdim4"])
    return tr * n_vols
```

Called for every run to build the cumulative time-offset table.

---

### `load_ev(mat_path)` / `save_ev(mat_path, data)`
Load and save FSL 3-column EV files (plain text, space-delimited, 4 decimal places).

```python
def load_ev(mat_path: Path) -> np.ndarray:
    return np.loadtxt(str(mat_path))          # returns (N, 3) float array

def save_ev(mat_path: Path, data: np.ndarray):
    np.savetxt(str(mat_path), data, fmt="%.4f")
```

---

### `extract_predictor(filename)`
Extracts the predictor name from a BIDS-style onset filename using a regex.

```python
def extract_predictor(filename: str) -> str | None:
    m = re.search(r"_desc-(.+)_events\.mat$", filename)
    return m.group(1) if m else None
```

Example:  
`sub-001_ses-01_task-EmoReg_run-03_desc-valid_keypress_events.mat`  
→ `"valid_keypress"`

---

### `main()` — overall orchestration

**1. Build the run table**  
Constructs an ordered list of 10 entries mapping each fMRI file to its onset run label.
The critical asymmetry is handled here: `ses-02` fMRI files are numbered `run-01…05`
but their onset files are numbered `run-06…10`.

```python
onset_run_num = local_run + (SES02_ONSET_OFFSET if ses_idx == 1 else 0)
# SES02_ONSET_OFFSET = 5
```

**2. Merge fMRI**  
All 10 runs are concatenated in one call:

```python
cmd = ["fslmerge", "-t", str(out_fmri)] + fmri_files
subprocess.run(cmd, check=True)
```

**3. Compute cumulative time offsets**  
Offsets accumulate across runs so that onset times from each run can be expressed
relative to the start of the full concatenated timeseries:

```python
offsets = []
cumulative = 0.0
for r in run_table:
    offsets.append(cumulative)
    cumulative += get_run_duration(r["fmri_path"])
```

**4. Concatenate onset files per predictor**  
For each predictor, onset times (column 0) are shifted by the run's cumulative offset,
then all runs are vertically stacked:

```python
ev[:, 0] += entry["offset"]   # shift onsets; durations & intensities unchanged
stacked_rows.append(ev)
concatenated = np.vstack(stacked_rows)
```

**5. Write run-regressor EVs**  
One EV file per run (3-column FSL format, single row): `onset  duration  1.0`

```python
ev_data = np.array([[offset, duration, 1.0]])
save_ev(out_beh / f"{sub}_{run_label}_events.mat", ev_data)
```

---

## Dependencies

| Package | Purpose |
|---|---|
| `numpy` | array operations on onset matrices |
| FSL (`fslmerge`, `fslinfo`) | fMRI merge and header parsing |

```bash
pip install numpy
```
