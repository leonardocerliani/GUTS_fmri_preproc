#!/usr/bin/env python3

"""
Extract mean time series per atlas label (FSL-style --label)

Inputs:
- fmri: base filename of 4D fMRI (WITHOUT .nii.gz)
- atlas: base filename of 3D label image (WITHOUT .nii.gz)
- labels: TSV file with at least two columns: index, name

Output:
- CSV file in same directory as fmri
- One column per label, one row per timepoint

Usage:
    python extract_meants.py \
        --fmri /path/to/fmri \
        --atlas /path/to/atlas \
        --labels labels.txt

Optional:
    --suffix meants   → output: fmri_meants.csv

Example:
    python extract_meants.py \
        --fmri data/sub01_bold \
        --atlas atlases/schaefer100 \
        --labels schaefer_labels.txt \
        --suffix ts
"""

import argparse
import sys
import numpy as np
import nibabel as nib
import pandas as pd
from pathlib import Path


def main(fmri_base, atlas_base, label_file, suffix):

    fmri_path = Path(fmri_base + ".nii.gz")
    atlas_path = Path(atlas_base + ".nii.gz")

    if not fmri_path.exists():
        raise FileNotFoundError(f"Missing fMRI file: {fmri_path}")
    if not atlas_path.exists():
        raise FileNotFoundError(f"Missing atlas file: {atlas_path}")

    fmri = nib.load(fmri_path).get_fdata()
    atlas = nib.load(atlas_path).get_fdata()

    if fmri.shape[:3] != atlas.shape:
        raise ValueError("FMRI and atlas dimensions do not match")

    # load labels (expects columns: index, name, ...)
    df_labels = pd.read_csv(label_file, sep="\t")

    data = {}

    for idx, name in zip(df_labels["index"], df_labels["name"]):
        mask = atlas == idx
        if not np.any(mask):
            print(f"Warning: label {idx} not found")
            continue

        data[name] = fmri[mask].mean(axis=0)

    df = pd.DataFrame(data)

    # build output filename
    out_dir = fmri_path.parent
    base_name = Path(fmri_base).name

    if suffix:
        out_name = f"{base_name}_{suffix}.csv"
    else:
        out_name = f"{base_name}.csv"

    out_path = out_dir / out_name
    df.to_csv(out_path, index=False)

    print(f"Saved: {out_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Extract mean time series per atlas label",
        epilog="""
Example:
  python extract_meants.py \
    --fmri data/sub01_bold \
    --atlas atlases/schaefer100 \
    --labels schaefer_labels.txt \
    --suffix ts
""",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument("--fmri", required=True, help="fMRI base filename (no .nii.gz)")
    parser.add_argument("--atlas", required=True, help="atlas base filename (no .nii.gz)")
    parser.add_argument("--labels", required=True, help="label TSV file (index, name)")
    parser.add_argument("--suffix", default=None, help="optional suffix for output CSV")

    # show help if no arguments provided
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(1)

    args = parser.parse_args()

    main(args.fmri, args.atlas, args.labels, args.suffix)