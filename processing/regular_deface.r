library(RNifti)
library(fslr)
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
out = face_removal_mask(fname)
out_img = readnii(out)
  
xx = which(out_img == 0, arr.ind = TRUE)
try(1:(min(xx[,3]) + floor(  (max(xx[,3]) - min(xx[,3]))/2)))
dim3 = 1:(min(xx[,3]) + floor(  (max(xx[,3]) - min(xx[,3]))/2))
dim2 = min(xx[,2]):dim(out_img)[2]
eg = expand.grid(dim1 = unique(xx[,1]),
                dim2 = dim2, dim3 = dim3)
eg = as.matrix(eg)
new_mask = out_img
new_mask[eg] = 0
final_img = img * new_mask
  
outfile = argv$output_image
  
writeNifti(final_img, file = outfile)
