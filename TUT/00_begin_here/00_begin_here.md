# Preliminary information

## An opinionated list of the best MRI viewer

- [MRIcroGL](https://github.com/rordenlab/MRIcroGL) : probably the best for creating beautiful 2D images

- [Mango](https://mangoviewer.com/) : very good choice for a hassle-free interaction between 2D views and surface renderings. It also produces shareable HTML pages with an embedded viewer.

- [Surfice](https://www.nitrc.org/projects/surfice/) : great fancy rendering of surfaces (although the projection of blobs/activations look better in Mango IMHO)

- [itk-SNAP](http://www.itksnap.org/pmwiki/pmwiki.php) : pro-graded image viewer with easy access to lots of information about the image


## basic intro to linux terminal
- [a true gem from the good'ole times : bash scripting tutorial by early FSL people](https://open.win.ox.ac.uk/pages/fslcourse/lectures/scripting/all.htm)
- by [TechByCosta](https://www.youtube.com/watch?v=V_G2_uCE8ug)

## setting up your account to work with fsl
I don't know whether we will really manage to make a tutorial. For the moment, this is (aims to be) a collection of short snippets for dealing with focused issues.

Most of what is done with nii images here will be in bash using FSL - and occasionally ANTs. In order to use fsl on storm you need to add a few lines to the `~/.bash_profile` in your home directory (that's what the `~` stands for). If this file does not yet exists, just create it. Then add the following lines.

```bash
# FSL Setup
FSLDIR=/usr/local/fsl

PATH=${FSLDIR}/share/fsl/bin:${PATH}
export FSLDIR PATH
. ${FSLDIR}/etc/fslconf/fsl.sh
```

This adds fsl to the path, and runs a few environmental variables used by fsl.

To check that now fsl is available for you to play with, open a new terminal or `source .bash_profile` and type `fslmaths`. If you see lots of text coming out, congratulations. You are ready to go.

## fslview in a box (i.e. Docker)
Since you work with brain images, you need to have a program to inspect them.

fsl nowadays comes equipped with an image viewer called fsleyes. However on storm (and apparently on this Ubuntu version) fsleyes does not want to work.

The solution I devised was to create a docker with a previous lightweight viewer, called fslview. 

To use it, you need to be part of the docker group on storm (ask me). Once that is taken care of, proceed as follows:

- open an X environment - e.g. access storm using x2goclient
- go to the folder where the image you want to visualize is present
- type in a terminal `fslview_MNI.sh [myimage]` replacing of course myimage with the actual name of the image you want to visualize (can be a nii or nii.gz, you don't need to specify the extension)

If you want to use this on your local computer - provided that you have Docker installed - just clone my [repo](https://github.com/leonardocerliani/fslview_in_a_box) and follow the instructions. (NB: not tested on windoze)


## sample data
The examples I will make are based on some sample data provided in the directory `orig_data`. I suggest you to duplicate this directory into another one called `data`, so that you keep a clean copy of the original data if you want to start anew.

I will assume that the directory from which I launch the scripts / commands contains the images.

If the sample data becomes too big to be put on github, we will see what to do.


## exploring brain images in RStudio (yes, really)
Having to switch all the time between terminal / VS code and x2goclient to inspect the images can be annoying. 

Recently I discovered that you can open a viewer inside RStudio! Check the documentation [here](https://johnmuschelli.com/papayaWidget/). At some point I will put some demo R code.

NB: this method does _not_ produce a simple static image, it opens a _full-fledged image browser_, and _that_ is why it is cool. 

## accessing storm from VS code (and w/out password)
Please refer to [this page](https://github.com/leonardocerliani/machines_setup/blob/main/VS_code_ssh_port_fw.md). 

This is particularly useful also to know how to use RStudio, Jupyter lab/notebooks and other services running on storm _in your local browser_.

**Important note**: accessing storm in the way described in that page - instead of your dear x2goclient - is not just _'cool'_: remote desktops like x2goclient need to download _a lot_ of data every second - i.e. the entire screen - even if you are just moving the mouse around on the remote desktop.

This means a sluggish (to say the least) user experience and pointless stress on the server, which results - to use an expression of our days - in a huge carbon footprint.

On the other hand the ssh port:localhost:port methods described in the page above need to transfer a tiny fraction of the data with respect to remote desktop, and provide a great lag-free user experience.

Finally, the password-less method is also more secure - exactly because you do not need to enter your password. Indeed it's the only way you can use GitHub nowadays.

The choice is yours.








