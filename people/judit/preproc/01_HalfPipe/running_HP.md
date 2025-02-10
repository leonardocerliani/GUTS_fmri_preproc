# Running HalfPipe (HP)

[please also see this tutorial](https://github.com/leonardocerliani/GUTS_fmri_preproc/blob/main/TUT/03_preproc_FSL_HalfPipe/03_preproc_FSL_HalfPipe.md)

Useful to get:
- accurate T1w brain masks 
- confounds .tsv file
- visual reports that can inspected in the browser

Drawbacks: it generates a lot of data (~ 30 times the size of the original data)

Therefore we run it, get what we need, and delete the rest

How to run HP:
- define the dir where your data are
- launch the docker (make sure your storm user is in the docker group)

```bash
cd /data00/leonardo/GUTS_fmri_preproc/people/judit/data
mkdir HP_output
cd HP_output 

data_folder="/data00/leonardo/GUTS_fmri_preproc/people/judit/data/nii"

docker run -it \
    --cpuset-cpus="0-9" \
    -v ${data_folder}:/ext \
    --name HP_judit_1 halfpipe/halfpipe
```

NB: make sure you use a recognizable name for the container you are running, e.g. HP_judit_1, so that if it goes wrong you can safely stop it and remove it without interferring with other people's running containers.

You can check the running/stopped container with:

```bash
docker ps -a
docker stop HP_judit_1  # stop the container
docker rm HP_judit_1    # remove the container
```

**NB:** the container will run for a while to preprocess all the images. You can: 
- **detach** from the container using `Ctrl-P-Q` to get back to your local terminal

- **reattach** to the container (if you need to) using `docker attach <containerID>`, however, I cannot imagine a situation where you might want to do this. Instead, I suggest you just check from time to time whether HP has finished the execution using `docker ps`

You will notice that HP creates a plethora of files and directories in the location where your raw data files are. The output is detailed on the [relevant section of the github repo](https://github.com/HALFpipe/HALFpipe?tab=readme-ov-file#outputs)

