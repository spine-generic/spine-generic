# This script has to be located in the same location as deface_spineGeneric_usingR.py
# This script is based on the issue https://github.com/poldracklab/pydeface/issues/27
# Author: Alexandru Foias
# License MIT

library(RNifti)
library(fslr)
library(extrantsr)
library(argparser, quietly=TRUE)

# Create a parser
p <- arg_parser("Round a floating point number")

# Add command line arguments
p <- add_argument(p, "--input_image", type = "character", help="path to image")
p <- add_argument(p, "--output_image", type = "character", help="path to output image")

# Parse the command line arguments
argv <- parse_args(p)

# Do work based on the passed arguments
print (argv$input_image)
print (argv$output_image)

fname = argv$input_image
img = RNifti::readNifti(fname)
tfname = mni_fname(mm = "1")
face_fname = mni_face_fname(mm = "1")
face = readnii(face_fname)
timg = readnii(tfname)
timg = copyNIfTIHeader(timg, timg[(91-30):(91+30), , 1:70])
face = copyNIfTIHeader(face, face[(91-30):(91+30), , 1:70])

noneck <- double_remove_neck(
  fname, 
  template.file = file.path(fsldir(), 
                            "data/standard", "MNI152_T1_1mm_brain.nii.gz"), 
  template.mask = file.path(fsldir(),
                            "data/standard", "MNI152_T1_1mm_brain_mask.nii.gz"))
reg = registration(
  filename = timg,
  template.file = noneck,
  typeofTransform = "Rigid")
out_img = ants_apply_transforms(moving = 1 - face, 
                            fixed = noneck,
                            transformlist = reg$fwdtransforms,
                            interpolator = "nearestNeighbor")


xx = which(out_img == 1, arr.ind = TRUE)
dim3 = 1:(min(xx[,3]) + floor(  (max(xx[,3]) - min(xx[,3]))/2))
dim2 = min(xx[,2]):dim(out_img)[2]
# eg = expand.grid(dim1 = unique(xx[,1]), 
# dim2 = unique(xx[,2]), dim3 = dim3)
eg = expand.grid(dim1 = unique(xx[,1]),
                 dim2 = dim2, dim3 = dim3)
eg = as.matrix(eg)
new_mask = out_img
new_mask[eg] = 1

new_mask = 1 - new_mask

final_img = img * new_mask
  
outfile = argv$output_image
  
writeNifti(final_img, file = outfile)
