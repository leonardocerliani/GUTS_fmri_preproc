
# Deface your T1w images with pydeface

## NB: very preliminary version
on the bus...

LC Nov 2025

## Current data structure:
```
data/
├── sub-gutsaumc0002
│   └── sub-gutsaumc0002_ses-01_T1w.nii.gz
├── sub-gutsaumc0005
│   └── sub-gutsaumc0005_ses-01_T1w.nii.gz
├── sub-gutsaumc0006
│   └── sub-gutsaumc0006_ses-01_T1w.nii.gz
├── sub-gutsaumc0007
│   └── sub-gutsaumc0007_ses-01_T1w.nii.gz
├── sub-gutsaumc0008
│   └── sub-gutsaumc0008_ses-01_T1w.nii.gz
├── sub-gutsaumc0010
│   └── sub-gutsaumc0010_ses-01_T1w.nii.gz
├── sub-gutsaumc0011
│   └── sub-gutsaumc0011_ses-01_T1w.nii.gz
├── sub-gutsaumc0012
│   └── sub-gutsaumc0012_ses-01_T1w.nii.gz
├── sub-gutsaumc0014
│   └── sub-gutsaumc0014_ses-01_T1w.nii.gz
├── sub-gutsaumc0015
│   └── sub-gutsaumc0015_ses-01_T1w.nii.gz
└── sub-gutsaumc0017
    └── sub-gutsaumc0017_ses-01_T1w.nii.gz
```


## Create venv and install pydeface

```bash
python -m venv venv_pydeface
source venv_pydeface/bin/activate
pip install pydeface
```

## Basic usage
```bash
pydeface my_t1w.nii.gz
```

This will create a `_defaced` version for each file. For other options just run `pydeface --help`


## Run it in parallel

```bash
find data -name "*.nii.gz" | xargs -P 12 -I {} pydeface {}
```

What happens here:

- `find data -name "*.nii.gz"` : finds all the nii.gz files in the `data` dir and its subdirs, and returns a list with the full path. Try to execute it by itself.

- `|` is the pipe operator. Basically whatever is produced from the previous `find` is passed to what comes next as an argument.

- `-P 12` : process all the elements of the list in blocks of 12 - so 12 elements will be processed in parallel

- `-I {}` : "my command requires an argument!"

- `pydeface {}`: "this is the argument" - i.e. one element of the list returned by `find`



**NB** Afterwards I would recommend to just overwrite the defaced T1w onto the original file, to keep the naming convention simple (and to eliminate the T1w with the face). If for whatever reason it is necessary in the future to reconstruct the original image with the face, it can be done from the PAR/REC file. This can be done e.g. with a simple for loop. Left here as an excercise.



## Running in background for large/massive amount of data

If you need to process dozens, hundreds, thousands of dataset at the same time - or if each processing takes more than the 10' required by pydeface - you better start a process in the background, so that you can be sure that it will run even if you disconnect from the server (e.g. closing the terminal ssh connection)

```bash
nohup find data -name "*.nii.gz" | xargs -P 12 -I {} pydeface {}' > pydeface.log &
```

Here:

- `nohup` makes the command ignore the hangup signal that occurs when the connection with the server is closed

- `> pydeface.log` redirects the messages that would be printed in the terminal to this file, so that you can always check in every moment how many participants have been processed so far.

Note that if you made a mistake and want to kill the process you launched, you can see it in `htop`/`btop`, and you can stop them e.g. with `pkill -9 pydeface`


## Final data structure
```
data
├── sub-gutsaumc0002
│   ├── sub-gutsaumc0002_ses-01_T1w.nii.gz
│   └── sub-gutsaumc0002_ses-01_T1w_defaced.nii.gz
├── sub-gutsaumc0005
│   ├── sub-gutsaumc0005_ses-01_T1w.nii.gz
│   └── sub-gutsaumc0005_ses-01_T1w_defaced.nii.gz
├── sub-gutsaumc0006
│   ├── sub-gutsaumc0006_ses-01_T1w.nii.gz
│   └── sub-gutsaumc0006_ses-01_T1w_defaced.nii.gz
├── sub-gutsaumc0007
│   ├── sub-gutsaumc0007_ses-01_T1w.nii.gz
│   └── sub-gutsaumc0007_ses-01_T1w_defaced.nii.gz
├── sub-gutsaumc0008
│   ├── sub-gutsaumc0008_ses-01_T1w.nii.gz
│   └── sub-gutsaumc0008_ses-01_T1w_defaced.nii.gz
├── sub-gutsaumc0010
│   ├── sub-gutsaumc0010_ses-01_T1w.nii.gz
│   └── sub-gutsaumc0010_ses-01_T1w_defaced.nii.gz
├── sub-gutsaumc0011
│   ├── sub-gutsaumc0011_ses-01_T1w.nii.gz
│   └── sub-gutsaumc0011_ses-01_T1w_defaced.nii.gz
├── sub-gutsaumc0012
│   ├── sub-gutsaumc0012_ses-01_T1w.nii.gz
│   └── sub-gutsaumc0012_ses-01_T1w_defaced.nii.gz
├── sub-gutsaumc0014
│   ├── sub-gutsaumc0014_ses-01_T1w.nii.gz
│   └── sub-gutsaumc0014_ses-01_T1w_defaced.nii.gz
├── sub-gutsaumc0015
│   ├── sub-gutsaumc0015_ses-01_T1w.nii.gz
│   └── sub-gutsaumc0015_ses-01_T1w_defaced.nii.gz
└── sub-gutsaumc0017
    ├── sub-gutsaumc0017_ses-01_T1w.nii.gz
    └── sub-gutsaumc0017_ses-01_T1w_defaced.nii.gz
```