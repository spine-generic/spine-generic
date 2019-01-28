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

# The following global variables are retrieved from parameters.sh but could be
# overwritten here:
# PATH_QC="~/qc"

# Exit if user presses CTRL+C (Linux) or CMD+C (OSX)
trap "echo Caught Keyboard Interrupt within script. Exiting now.; exit" INT

# Retrieve input params
sub=$1
PATH_PROCESSING=$2
PATH_QC=$3

# Go to anat folder where all structural data are located
cd anat/


# MTS
# ==============================================================================
file_t1w_mts="${sub}_acq-T1w_MTS"
file_mton="${sub}_acq-MTon_MTS"
file_mtoff="${sub}_acq-MToff_MTS"
file_t2w="${sub}_acq-T2w"
file_t2s="${sub}_T2star"
file_t1w="${sub}_T1w"
# Check if manual segmentation already exists
if [ -e "${file_t1w}_seg_manual.nii.gz" ]; then
  file_seg="${file_t1w}_seg_manual"
else
  # Segment spinal cord
  sct_deepseg_sc -i ${file_t1w_mts}.nii.gz -c t1 -qc ${PATH_QC}
  file_seg="${file_t1w_mts}_seg"
fi
# Create mask
sct_create_mask -i ${file_t1w_mts}.nii.gz -p centerline,${file_seg}.nii.gz -size 35mm -o ${file_t1w_mts}_mask.nii.gz

# Registrations to T1w MTS :
# Tips: here we only use rigid transformation because both images have very similar sequence parameters. We don't want to use SyN/BSplineSyN to avoid introducing spurious deformations.
# MToff
sct_register_multimodal -i ${file_mtoff}.nii.gz -d ${file_t1w_mts}.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -x spline
# MTon
sct_register_multimodal -i ${file_mton}.nii.gz -d ${file_t1w_mts}.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -x spline
# T2w
sct_register_multimodal -i ${file_t2w}.nii.gz -d ${file_t1w_mts}.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -x spline
# T2star
sct_register_multimodal -i ${file_t2s}.nii.gz -d ${file_t1w_mts}.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -x spline
# T1w
sct_register_multimodal -i ${file_t1w}.nii.gz -d ${file_t1w_mts}.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -x spline



