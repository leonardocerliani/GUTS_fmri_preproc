#!/usr/bin/env python3
"""
build_design_fsf.py
===================
Builds a per-subject FEAT 1st-level design.fsf for every subject in list_subj.txt.

Inputs (all in the same directory as this script):
  design_example.fsf   global FEAT settings from the GUI (EV & contrast sections ignored)
  list_predictors.csv  header + columns: EV_name, include, temporal_derivative
  list_contrasts.txt   one contrast per line: name : pos_EV > neg_EV

Output:
  {DATA_ROOT}/{sub}/func/design_{sub}.fsf   for each subject

Usage (from the scripts/ root):
  python3 1st_level_analysis/build_design_fsf.py
"""

import re
import sys
from pathlib import Path
import nibabel as nib

# ─────────────────────────────────────────────────────────────
# Paths
# ─────────────────────────────────────────────────────────────
SCRIPT_DIR   = Path(__file__).parent.resolve()
DATA_ROOT    = Path("/data00/leonardo/GUTS_fmri_preproc/people/judit/bids_concat/data")
SUBJ_LIST    = SCRIPT_DIR.parent / "list_subj.txt"
EXAMPLE_FSF  = SCRIPT_DIR / "design_example.fsf"
PRED_CSV     = SCRIPT_DIR / "list_predictors.csv"
CONTRAST_TXT = SCRIPT_DIR / "list_contrasts.txt"

# EV parameters — taken from design_example.fsf
EV_SHAPE          = 3   # Custom 3-column format
EV_CONVOLVE       = 2   # Gamma HRF
EV_CONVOLVE_PHASE = 0
EV_TEMPFILT       = 1
EV_GAMMASIGMA     = 3
EV_GAMMADELAY     = 6


# ─────────────────────────────────────────────────────────────
# 0.  Compute totalVoxels from NIfTI header
# ─────────────────────────────────────────────────────────────
def get_nii_info(nii_path: Path) -> tuple[int, int]:
    """Returns (totalVoxels, npts) from the NIfTI header (no data load)."""
    img = nib.load(str(nii_path))
    d = img.header.get_data_shape()
    return int(d[0] * d[1] * d[2] * d[3]), int(d[3])


# ─────────────────────────────────────────────────────────────
# 1.  Parse the example FSF (global settings only)
# ─────────────────────────────────────────────────────────────
def parse_example_global(fsf_path: Path):
    """
    Returns (global_text, feat_path, highres_path).

    global_text : everything from the start of the file up to (but not
                  including) the first '# EV 1 title' comment.
    feat_path   : value of feat_files(1) for sub-001.
    highres_path: value of highres_files(1) for sub-001.
    """
    text = fsf_path.read_text()

    # Cut just before the first EV block
    m = re.search(r'^# EV 1 title\s*$', text, re.MULTILINE)
    global_text = text[: m.start()] if m else text

    m_feat = re.search(r'set feat_files\(1\)\s+"([^"]*)"', global_text)
    m_high = re.search(r'set highres_files\(1\)\s+"([^"]*)"', global_text)
    feat_path  = m_feat.group(1) if m_feat else ""
    high_path  = m_high.group(1) if m_high else ""

    return global_text, feat_path, high_path


# ─────────────────────────────────────────────────────────────
# 2.  Parse list_predictors.csv
# ─────────────────────────────────────────────────────────────
def parse_predictors(csv_path: Path):
    """
    Returns ordered list of dicts for included (include == 1) predictors:
      {'name': str, 'deriv': int}   (deriv = temporal_derivative column)
    """
    evs = []
    with open(csv_path) as f:
        for raw in f:
            line = raw.strip()
            if not line:
                continue
            parts = [p.strip() for p in line.split(',')]
            try:
                include = int(parts[1])
                deriv   = int(parts[2]) if len(parts) > 2 else 1
            except (ValueError, IndexError):
                continue  # header or malformed line
            if include == 1:
                evs.append({'name': parts[0], 'deriv': deriv})
    return evs


# ─────────────────────────────────────────────────────────────
# 3.  Parse list_contrasts.txt
# ─────────────────────────────────────────────────────────────
def parse_contrasts(contrast_path: Path, ev_list: list):
    """
    Parses 'name : pos_EV > neg_EV' lines (name is optional).
    EV names are matched case-insensitively; the _events suffix is optional.
    Returns list of {name, pos (1-based orig index), neg (1-based orig index)}.
    """
    ev_names = [ev['name'] for ev in ev_list]

    def _norm(s: str) -> str:
        return s.strip().lower().removesuffix('_events')

    def find_ev(token: str):
        tok = _norm(token)
        for i, name in enumerate(ev_names):
            if _norm(name) == tok:
                return i + 1
        return None

    contrasts = []
    with open(contrast_path) as f:
        for raw in f:
            line = raw.strip()
            if not line or line.startswith('#'):
                continue

            if ':' in line:
                con_name, rest = line.split(':', 1)
                con_name = con_name.strip()
            else:
                con_name, rest = None, line

            if '>' not in rest:
                print(f"WARNING: skipping malformed contrast: {line!r}", file=sys.stderr)
                continue

            pos_str, neg_str = [s.strip() for s in rest.split('>', 1)]
            pos_idx = find_ev(pos_str)
            neg_idx = find_ev(neg_str)

            if pos_idx is None:
                print(f"WARNING: EV '{pos_str}' not found in predictor list", file=sys.stderr)
                continue
            if neg_idx is None:
                print(f"WARNING: EV '{neg_str}' not found in predictor list", file=sys.stderr)
                continue

            if con_name is None:
                con_name = f"{_norm(pos_str)}_gt_{_norm(neg_str)}"

            contrasts.append({'name': con_name, 'pos': pos_idx, 'neg': neg_idx})
    return contrasts


# ─────────────────────────────────────────────────────────────
# 4.  Real-EV position map
# ─────────────────────────────────────────────────────────────
def real_ev_positions(evs: list):
    """
    Returns (positions, evs_real).
    positions[i] = real-EV start index (1-based) for orig EV i+1.
    evs_real      = total number of real EVs.
    """
    positions = []
    pos = 1
    for ev in evs:
        positions.append(pos)
        pos += 2 if ev['deriv'] else 1
    return positions, pos - 1


# ─────────────────────────────────────────────────────────────
# 5.  Build FSF content for one subject
# ─────────────────────────────────────────────────────────────
def build_fsf(sub: str, evs: list, contrasts: list,
              global_tmpl: str, feat_tmpl: str, high_tmpl: str) -> str:

    evs_orig           = len(evs)
    real_pos, evs_real = real_ev_positions(evs)
    ncon               = len(contrasts)

    # ── Patch global settings ────────────────────────────────
    gs = global_tmpl.replace('sub-001', sub)

    feat_sub  = feat_tmpl.replace('sub-001', sub)
    outputdir = feat_sub + ".feat"

    # Update totalVoxels and npts from the actual fMRI file
    nii = Path(feat_sub + ".nii.gz")
    if nii.exists():
        total_voxels, npts = get_nii_info(nii)
        gs = re.sub(r'(set fmri\(totalVoxels\))\s*\d+',
                    rf'\g<1> {total_voxels}', gs)
        gs = re.sub(r'(set fmri\(npts\))\s*\d+',
                    rf'\g<1> {npts}', gs)
    else:
        print(f"  WARNING: fMRI not found, keeping totalVoxels/npts from example: {nii}",
              file=sys.stderr)
    gs = re.sub(r'set fmri\(outputdir\)\s*"[^"]*"',
                f'set fmri(outputdir) "{outputdir}"', gs)
    gs = re.sub(r'(set fmri\(evs_orig\))\s*\d+',       rf'\g<1> {evs_orig}',  gs)
    gs = re.sub(r'(set fmri\(evs_real\))\s*\d+',       rf'\g<1> {evs_real}',  gs)
    gs = re.sub(r'(set fmri\(evs_vox\))\s*\d+',        r'\g<1> 0',            gs)
    gs = re.sub(r'(set fmri\(ncon_orig\))\s*\d+',      rf'\g<1> {ncon}',      gs)
    gs = re.sub(r'(set fmri\(ncon_real\))\s*\d+',      rf'\g<1> {ncon}',      gs)
    gs = re.sub(r'(set fmri\(nftests_orig\))\s*\d+',   r'\g<1> 0',            gs)
    gs = re.sub(r'(set fmri\(nftests_real\))\s*\d+',   r'\g<1> 0',            gs)

    out = [gs]

    # ── EV blocks ────────────────────────────────────────────
    beh_root = DATA_ROOT / sub / "beh"
    for i, ev in enumerate(evs):
        n   = i + 1
        nm  = ev['name']
        d   = ev['deriv']
        beh = str(beh_root / f"{sub}_{nm}.mat")

        out += [
            f"\n# EV {n} title\n",
            f'set fmri(evtitle{n}) "{nm}"\n',
            f"\n# Basic waveform shape (EV {n})\n",
            f'set fmri(shape{n}) {EV_SHAPE}\n',
            f"\n# Convolution (EV {n})\n",
            f'set fmri(convolve{n}) {EV_CONVOLVE}\n',
            f"\n# Convolve phase (EV {n})\n",
            f'set fmri(convolve_phase{n}) {EV_CONVOLVE_PHASE}\n',
            f"\n# Apply temporal filtering (EV {n})\n",
            f'set fmri(tempfilt_yn{n}) {EV_TEMPFILT}\n',
            f"\n# Add temporal derivative (EV {n})\n",
            f'set fmri(deriv_yn{n}) {d}\n',
            f"\n# Custom EV file (EV {n})\n",
            f'set fmri(custom{n}) "{beh}"\n',
            f"\n# Gamma sigma (EV {n})\n",
            f'set fmri(gammasigma{n}) {EV_GAMMASIGMA}\n',
            f"\n# Gamma delay (EV {n})\n",
            f'set fmri(gammadelay{n}) {EV_GAMMADELAY}\n',
            "\n",
        ]
        # Orthogonalisation row (EV n vs EVs 0..evs_orig)
        for j in range(evs_orig + 1):
            out.append(f'set fmri(ortho{n}.{j}) 0\n')

    # ── Contrast mode ─────────────────────────────────────────
    out += [
        '\n# Contrast & F-tests mode\n',
        '# real : control real EVs\n',
        '# orig : control original EVs\n',
        'set fmri(con_mode_old) orig\n',
        'set fmri(con_mode) orig\n',
    ]

    # ── con_real blocks ───────────────────────────────────────
    for ci, con in enumerate(contrasts):
        c   = ci + 1
        vec = [0.0] * evs_real
        vec[real_pos[con['pos'] - 1] - 1] =  1.0
        vec[real_pos[con['neg'] - 1] - 1] = -1.0

        out += [
            f'\n# Display images for contrast_real {c}\n',
            f'set fmri(conpic_real.{c}) 1\n',
            f'\n# Title for contrast_real {c}\n',
            f'set fmri(conname_real.{c}) "{con["name"]}"\n',
            '\n',
        ]
        for ri, val in enumerate(vec):
            out.append(f'set fmri(con_real{c}.{ri+1}) {val}\n')

    # ── con_orig blocks ───────────────────────────────────────
    for ci, con in enumerate(contrasts):
        c   = ci + 1
        vec = [0.0] * evs_orig
        vec[con['pos'] - 1] =  1.0
        vec[con['neg'] - 1] = -1.0

        out += [
            f'\n# Display images for contrast_orig {c}\n',
            f'set fmri(conpic_orig.{c}) 1\n',
            f'\n# Title for contrast_orig {c}\n',
            f'set fmri(conname_orig.{c}) "{con["name"]}"\n',
            '\n',
        ]
        for oi, val in enumerate(vec):
            out.append(f'set fmri(con_orig{c}.{oi+1}) {val}\n')

    # ── conmask section ───────────────────────────────────────
    out.append('\n# Contrast masking - use >0 instead of thresholding?\n')
    out.append('set fmri(conmask_zerothresh_yn) 0\n')
    for i in range(1, ncon + 1):
        for j in range(1, ncon + 1):
            if i != j:
                out.append(f'set fmri(conmask{i}_{j}) 0\n')
    out.append('\n# Do contrast masking at all?\n')
    out.append('set fmri(conmask1_1) 0\n')

    # ── Trailing options ──────────────────────────────────────
    out += [
        '\n##########################################################\n',
        '# Now options that don\'t appear in the GUI\n\n',
        'set fmri(alternative_mask) ""\n',
        'set fmri(init_initial_highres) ""\n',
        'set fmri(init_highres) ""\n',
        'set fmri(init_standard) ""\n',
        'set fmri(overwrite_yn) 0\n',
    ]

    return ''.join(out)


# ─────────────────────────────────────────────────────────────
# 6.  Pretty report
# ─────────────────────────────────────────────────────────────
def print_report(sub: str, evs: list, contrasts: list,
                 fsf_path: Path, feat_path: str, high_path: str):
    _, evs_real = real_ev_positions(evs)
    feat_sub = feat_path.replace('sub-001', sub)
    high_sub = high_path.replace('sub-001', sub)

    print(f"  ┌─────────────────────────────────────────────────────────────")
    print(f"  │  Subject    : {sub}")
    print(f"  │  Design FSF : {fsf_path}")
    print(f"  │  Output dir : {feat_sub}.feat")
    print(f"  │  fMRI data  : {feat_sub}")
    print(f"  │  Structural : {high_sub}")
    print(f"  │  EVs        : {len(evs)} orig  |  {evs_real} real")
    print(f"  ├─────────────────────────────────────────────────────────────")
    print(f"  │  Contrasts ({len(contrasts)}):")
    for i, con in enumerate(contrasts):
        pos_name = evs[con['pos'] - 1]['name'].removesuffix('_events')
        neg_name = evs[con['neg'] - 1]['name'].removesuffix('_events')
        print(f"  │    c{i+1:<2d} : {con['name']:<28s}  "
              f"[{pos_name}(+1) > {neg_name}(-1)]")
    print(f"  └─────────────────────────────────────────────────────────────\n")


# ─────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────
def main():
    # Load subjects (optional CLI arg overrides default list_subj.txt)
    subj_list_path = Path(sys.argv[1]) if len(sys.argv) > 1 else SUBJ_LIST
    subjects = [s.strip() for s in subj_list_path.read_text().splitlines() if s.strip()]

    # Parse inputs
    evs      = parse_predictors(PRED_CSV)
    contrasts = parse_contrasts(CONTRAST_TXT, evs)
    global_tmpl, feat_tmpl, high_tmpl = parse_example_global(EXAMPLE_FSF)

    _, evs_real = real_ev_positions(evs)

    print(f"\n{'═'*60}")
    print(f"  build_design_fsf.py")
    print(f"{'═'*60}")
    print(f"  Included EVs : {len(evs)} orig | {evs_real} real")
    print(f"  Contrasts    : {len(contrasts)}")
    print(f"  Subjects     : {', '.join(subjects)}")
    print(f"{'═'*60}\n")

    for sub in subjects:
        out_dir  = DATA_ROOT / sub / "func"
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path = out_dir / f"design_{sub}.fsf"

        content = build_fsf(sub, evs, contrasts, global_tmpl, feat_tmpl, high_tmpl)
        out_path.write_text(content)

        print_report(sub, evs, contrasts, out_path, feat_tmpl, high_tmpl)

    print(f"Done. To launch FEAT:\n  bash 1st_level_analysis/run_feat.sh\n")


if __name__ == '__main__':
    main()
