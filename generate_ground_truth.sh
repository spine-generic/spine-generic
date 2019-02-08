#!/bin/bash
#
# Generate segmentation and co-register all multimodal data.
#
# Usage:
#   ./generate_ground_truth.sh <subject_ID>
#
# Where subject_ID refers to the subject ID according to the BIDS format.
#
# Example:
#   ./generate_ground_truth.sh sub-03
#

# Exit if user presses CTRL+C (Linux) or CMD+C (OSX)
trap "echo Caught Keyboard Interrupt within script. Exiting now.; exit" INT

# Retrieve input params
sub=$1

dir=`pwd`

# Create BIDS architecture
mkdir -p derivatives/labels/${sub}/anat
ofolder="${dir}/derivatives/labels/${sub}/anat"

# Go to anat folder where all structural data are located
pwd
cd ${sub}/anat


# Filenames
# ==============================================================================
file_t1w_mts="${sub}_acq-T1w_MTS"
file_mton="${sub}_acq-MTon_MTS"
file_mtoff="${sub}_acq-MToff_MTS"
file_t2w="${sub}_T2w"
file_t2s="${sub}_T2star"
file_t1w="${sub}_T1w"
# Check if manual segmentation already exists
if [ -e "${file_t1w}_seg_manual.nii.gz" ]; then
  file_seg="${file_t1w}_seg_manual"
else
  # Segment spinal cord
  sct_deepseg_sc -i ${file_t1w_mts}.nii.gz -c t1  -ofolder ${ofolder}
  file_seg="${file_t1w_mts}_seg"
fi

# Create mask
sct_create_mask -i ${file_t1w_mts}.nii.gz -p centerline,"${ofolder}/${file_seg}.nii.gz" -size 35mm -o ${file_t1w_mts}_mask.nii.gz

# Registrations to T1w MTS :
# Tips: here we only use rigid transformation because both images have very similar sequence parameters. We don't want to use SyN/BSplineSyN to avoid introducing spurious deformations.
# MToff
sct_register_multimodal -i ${file_mtoff}.nii.gz -d ${file_t1w_mts}.nii.gz  -m ${file_t1w_mts}_mask.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -x spline -ofolder ${ofolder}
# MTon
sct_register_multimodal -i ${file_mton}.nii.gz -d ${file_t1w_mts}.nii.gz  -m ${file_t1w_mts}_mask.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -x spline -ofolder ${ofolder}
# T2w
sct_register_multimodal -i ${file_t2w}.nii.gz -d ${file_t1w_mts}.nii.gz  -m ${file_t1w_mts}_mask.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -x spline -ofolder ${ofolder}
# T2star
sct_register_multimodal -i ${file_t2s}.nii.gz -d ${file_t1w_mts}.nii.gz  -m ${file_t1w_mts}_mask.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -x spline -ofolder ${ofolder}
# T1w
sct_register_multimodal -i ${file_t1w}.nii.gz -d ${file_t1w_mts}.nii.gz  -m ${file_t1w_mts}_mask.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -x spline -ofolder ${ofolder}

# Delete useless images
rm "${file_t1w_mts}_mask.nii.gz"
rm *image_in_RPI_resampled*
rm ${ofolder}/*warp* #delete warping fields
rm ${ofolder}/"${file_t1w_mts}_reg.nii.gz" #delete the t1w MTS registered to the last image (here T1w)
