#!/usr/bin/env python3
"""
do_concatenate_fmri_onset_files.py
===================================
Concatenates 10 fMRI runs (ses-01: runs 1-5, ses-02: runs 6-10) and their FSL
3-column onset files for a single subject in the EmoReg BIDS dataset.

Usage
-----
    python do_concatenate_fmri_onset_files.py sub-001

Outputs (in OUTPUT_ROOT/<sub>/)
-------------------------------
    func/<sub>_task-EmoReg_bold.nii.gz        — concatenated 4D fMRI
    beh/<sub>_<predictor>_events.mat           — one file per predictor
    beh/<sub>_run-NN_events.mat               — 10 run-regressor EVs (NN = 01-10)

Dependencies
------------
    numpy   (pip install numpy)
    FSL     (fslmerge, fslinfo must be on PATH)
"""

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

import numpy as np

# ---------------------------------------------------------------------------
# USER-CONFIGURABLE PATHS
# ---------------------------------------------------------------------------
SOURCE_ROOT = Path("/data00/EmoReg_running_analyses/preprocessing_2026/source_data/bids_LC/data")
OUTPUT_ROOT = Path("/data00/leonardo/GUTS_fmri_preproc/people/judit/bids_concat/data")

# ---------------------------------------------------------------------------
# CONSTANTS
# ---------------------------------------------------------------------------
TASK = "task-EmoReg"
SESSIONS = ["ses-01", "ses-02"]
RUNS_PER_SESSION = 5  # each session has 5 fMRI runs

# ses-02 fMRI files are numbered run-01..run-05, but their onset files are
# numbered run-06..run-10. This offset corrects that mismatch.
SES02_ONSET_OFFSET = 5


# ---------------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------------

def fslinfo(fmri_path: Path) -> dict:
    """Return a dict with at least 'dim4' (int) and 'pixdim4' (float) from fslinfo."""
    result = subprocess.run(
        ["fslinfo", str(fmri_path)],
        capture_output=True, text=True, check=True
    )
    info = {}
    for line in result.stdout.splitlines():
        parts = line.split()
        if len(parts) >= 2:
            info[parts[0]] = parts[1]
    return info


def get_run_duration(fmri_path: Path) -> float:
    """Return total run duration in seconds: TR * n_volumes."""
    info = fslinfo(fmri_path)
    n_vols = int(info["dim4"])
    tr = float(info["pixdim4"])
    return tr * n_vols


def load_ev(mat_path: Path) -> np.ndarray:
    """Load a 3-column FSL EV text file; return (N,3) float array."""
    return np.loadtxt(str(mat_path))


def save_ev(mat_path: Path, data: np.ndarray):
    """Save a (N,3) float array as an FSL EV text file (space-delimited, 4 decimal places)."""
    mat_path.parent.mkdir(parents=True, exist_ok=True)
    np.savetxt(str(mat_path), data, fmt="%.4f")


def extract_predictor(filename: str) -> str | None:
    """Extract the <predictor> part from a filename like
       sub-XXX_ses-YY_task-EmoReg_run-NN_desc-<predictor>_events.mat
    Returns None if the pattern is not found."""
    m = re.search(r"_desc-(.+)_events\.mat$", filename)
    return m.group(1) if m else None


# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Concatenate fMRI runs and onset files for one subject."
    )
    parser.add_argument("subject", help="Subject ID, e.g. sub-001")
    args = parser.parse_args()
    sub = args.subject

    print(f"\n{'='*60}")
    print(f"  Processing subject: {sub}")
    print(f"{'='*60}\n")

    # ------------------------------------------------------------------
    # 1. Build the ordered run table
    #    Each entry: (fmri_path, beh_dir, onset_run_label, global_run_idx)
    #    global_run_idx is 1-based (1..10)
    # ------------------------------------------------------------------
    run_table = []
    global_run = 1

    for ses_idx, ses in enumerate(SESSIONS):
        for local_run in range(1, RUNS_PER_SESSION + 1):
            fmri_run_label = f"run-{local_run:02d}"

            # onset run label: ses-01 mirrors fmri run; ses-02 is offset by 5
            onset_run_num = local_run + (SES02_ONSET_OFFSET if ses_idx == 1 else 0)
            onset_run_label = f"run-{onset_run_num:02d}"

            fmri_path = (
                SOURCE_ROOT / sub / ses / "func"
                / f"{sub}_{ses}_{TASK}_{fmri_run_label}_bold.nii.gz"
            )
            beh_dir = SOURCE_ROOT / sub / ses / "beh"

            run_table.append({
                "fmri_path":        fmri_path,
                "beh_dir":          beh_dir,
                "onset_run_label":  onset_run_label,
                "global_run":       global_run,
            })
            global_run += 1

    # ------------------------------------------------------------------
    # 2. Validate: check all fMRI files exist
    # ------------------------------------------------------------------
    missing = [r["fmri_path"] for r in run_table if not r["fmri_path"].exists()]
    if missing:
        print("ERROR: The following fMRI files were not found:")
        for p in missing:
            print(f"  {p}")
        sys.exit(1)

    # ------------------------------------------------------------------
    # 3. Create output directories
    # ------------------------------------------------------------------
    out_func = OUTPUT_ROOT / sub / "func"
    out_beh  = OUTPUT_ROOT / sub / "beh"
    out_func.mkdir(parents=True, exist_ok=True)
    out_beh.mkdir(parents=True, exist_ok=True)

    # ------------------------------------------------------------------
    # 4. Concatenate fMRI with fslmerge -t
    # ------------------------------------------------------------------
    out_fmri = out_func / f"{sub}_{TASK}_bold.nii.gz"
    fmri_files = [str(r["fmri_path"]) for r in run_table]

    print(f"[fMRI] Merging {len(fmri_files)} runs → {out_fmri}")
    cmd = ["fslmerge", "-t", str(out_fmri)] + fmri_files
    subprocess.run(cmd, check=True)
    print("[fMRI] Done.\n")

    # ------------------------------------------------------------------
    # 5. Compute cumulative time offsets for each run
    # ------------------------------------------------------------------
    print("[Offsets] Computing run durations via fslinfo ...")
    offsets = []       # offset[i] = start time of global run i (seconds)
    cumulative = 0.0

    for r in run_table:
        offsets.append(cumulative)
        duration = get_run_duration(r["fmri_path"])
        r["duration"] = duration   # store for run-regressor EVs
        cumulative += duration
        print(f"  Global run {r['global_run']:2d} | offset = {offsets[-1]:.4f} s | "
              f"duration = {duration:.4f} s")

    print()

    # ------------------------------------------------------------------
    # 6. Discover all unique predictors across all runs
    # ------------------------------------------------------------------
    predictor_map: dict[str, list] = {}   # predictor -> list of (global_run_idx, path)

    for r in run_table:
        beh_dir = r["beh_dir"]
        onset_run_label = r["onset_run_label"]

        if not beh_dir.exists():
            print(f"  WARNING: beh dir not found: {beh_dir}")
            continue

        for mat_file in sorted(beh_dir.iterdir()):
            fname = mat_file.name
            # Must match this subject, this run label, and have _desc- tag
            if (fname.startswith(f"{sub}_") and
                    f"_{onset_run_label}_" in fname and
                    fname.endswith("_events.mat")):

                predictor = extract_predictor(fname)
                if predictor is not None:
                    if predictor not in predictor_map:
                        predictor_map[predictor] = []
                    predictor_map[predictor].append({
                        "global_run": r["global_run"],
                        "path":       mat_file,
                        "offset":     offsets[r["global_run"] - 1],
                    })

    print(f"[Onsets] Found {len(predictor_map)} unique predictors.\n")

    # ------------------------------------------------------------------
    # 7. For each predictor: apply offsets, stack rows, write output
    # ------------------------------------------------------------------
    for predictor, entries in sorted(predictor_map.items()):
        stacked_rows = []
        for entry in entries:
            ev = load_ev(entry["path"])
            if ev.ndim == 1:
                ev = ev.reshape(1, -1)   # single-row files
            ev[:, 0] += entry["offset"]  # add cumulative time offset to onset column
            stacked_rows.append(ev)

        concatenated = np.vstack(stacked_rows)
        out_mat = out_beh / f"{sub}_{predictor}_events.mat"
        save_ev(out_mat, concatenated)
        print(f"  [predictor] {predictor} ({len(concatenated)} rows) → {out_mat.name}")

    print()

    # ------------------------------------------------------------------
    # 8. Write run-regressor EV files (one row per run, 3-column FSL format)
    # ------------------------------------------------------------------
    print("[Run EVs] Writing 10 run-regressor EV files ...")
    for r, offset in zip(run_table, offsets):
        global_run = r["global_run"]
        run_label  = f"run-{global_run:02d}"
        duration   = r["duration"]

        ev_data = np.array([[offset, duration, 1.0]])
        out_mat = out_beh / f"{sub}_{run_label}_events.mat"
        save_ev(out_mat, ev_data)
        print(f"  {out_mat.name}  (onset={offset:.4f}, dur={duration:.4f})")

    print()
    print(f"[Done] All outputs written to: {OUTPUT_ROOT / sub}")
    print()


if __name__ == "__main__":
    main()
