# Slicing 4D images

location: `data/one_sub`

_I assume that you created a copy of the `orig_data` coming with this repo into a `data`, and then changed directory in there, that is:_

```bash
cp -r orig_data data
cd data/one_sub
```

Sometimes you might need to extract some 3D images from a 4D image. For instance you might want to remove the initial or last $n$ volumes. This is particularly useful in diffusion-weighted images, where you might want to relocated all the $b0$ images to the beginning of the 4D for averaging.

Let's see an example:

```bash
# Show the number of 3D volumes in fmri.nii.gz
# They are now 20
fslinfo fmri

# Extract only the first 18 images
# Run fslroi without arguments to get some docs
# NB: the volumes count start from 0
fslroi fmri fmri_1_18 0 18
fslinfo fmri_1_18


# Extract only the last two volumes
fslroi fmri fmri_18_20 18 2
fslinfo fmri_18_20
```

Note that you do not need to specify the total number of volumes manually, which is good, since it might change across runs / sessions / subjects.

What you can do is to store that in a variable and then use it in the `fslroi` command

```bash
length_fmri=$(fslinfo fmri | grep ^dim4 | awk '{print $2}')
echo ${length_fmri}
```

There is a lot to unpack in the variable assignment above. Try running `fslinfo fmri` alone and ask gpt to explain the full line.

```bash
to_keep=18
fslroi fmri fmri_1_${to_keep}_again 0 ${to_keep}

diff fmri_1_18.nii.gz fmri_1_18_again.nii.gz

to_remove=$((${length_fmri} - ${to_keep}))
echo ${to_remove}
fslroi fmri fmri_${to_keep}_${length_fmri}_again ${to_keep} ${to_remove}

diff fmri_18_20.nii.gz fmri_18_20_again.nii.gz
```

The `diff` command is just to show that the files obtained with either procedures are exactly the same (as expected).


