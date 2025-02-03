In this folder there is a quasi-random collection of small tutorials that can help getting started with processing MRI images, mostly using [FSL](https://fsl.fmrib.ox.ac.uk/fsl/docs/#/). In the future, it might get more organized.

## 00_preliminary.md
- An opinionated short list of the best image viewers out there
- Link to a basic intro about working with the linux shell (which applies also to the WSL for Windows) 
- Setting up an the ole-but-efficient [fslview image viewer using Docker](https://github.com/leonardocerliani/fslview_in_a_box)
- Exploring images in RStudio using papayawidget (see also later in the folder `02_papaya_R_nifti_viewer`)
- Setting up VS code to access to a remote server (e.g. Storm) without username and pw


## 01_slicing_nifti_images.md
A very short example of some basic commands of fsl to extract specific 3D volumes from a 4D volume (e.g. an fMRI acquisition)

## 02_papaya_R_nifti_viewer
If you like working with R, the [`papayaWidget` by the great John Muschelli](https://johnmuschelli.com/papayaWidget/) is a life saver. Not only it enables to programmatically define views with multiple layers of overlay; by means of Rmd (R Markdown) notebooks, it allows you to create HTML pages with a full-fledged interactive 3D viewer (not just single images). This is extremely useful to share results with colleagues. You can open the `papaya_TUT.html` page for an example.

