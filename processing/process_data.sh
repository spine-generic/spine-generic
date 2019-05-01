#!/bin/bash
#
# Process data. This script should be run within the subject's folder.
#
# Usage:
#   ./process_data.sh <subject_ID>
#
# Where subject_ID refers to the subject ID according to the BIDS format.
#
# Example:
#   ./process_data.sh sub-03
#
# Authors: Julien Cohen-Adad, Stephanie Alley

# The following global variables are retrieved from parameters.sh but could be
# overwritten here:
# PATH_QC="~/qc"

# Uncomment for full verbose
set -v

# Immediately exit if error
set -e

# Exit if user presses CTRL+C (Linux) or CMD+C (OSX)
trap "echo Caught Keyboard Interrupt within script. Exiting now.; exit" INT

# Retrieve input params
SUBJECT=$1
SITE=$2
PATH_OUTPUT=$3
PATH_QC=$4
PATH_LOG=$5


# FUNCTIONS
# ==============================================================================

# Check if manual label already exists. If it does, copy it locally. If it does
# not, perform labeling.
label_if_does_not_exist(){
  local file="$1"
  local file_seg="$2"
  # Update global variable with segmentation file name
  FILELABEL="${file}_labels"
  if [ -e "${PATH_SEGMANUAL}/${SITE}/${file}_labels-manual.nii.gz" ]; then
    rsync -avzh "${PATH_SEGMANUAL}/${SITE}/${file}_labels-manual.nii.gz" ${FILELABEL}.nii.gz
  else
    # Generate labeled segmentation
    sct_label_vertebrae -i ${file}.nii.gz -s ${file_seg}.nii.gz -c t1 -qc ${PATH_QC}
    # Create labels in the cord at C2 and C5 mid-vertebral levels (only if it does not exist)
    sct_label_utils -i ${file_seg}_labeled.nii.gz -vert-body 2,5 -o ${FILELABEL}.nii.gz
  fi
}

# Check if manual segmentation already exists. If it does, copy it locally. If
# it does not, perform seg.
segment_if_does_not_exist(){
  local file="$1"
  local contrast="$2"
  # Update global variable with segmentation file name
  FILESEG="${file}_seg"
  if [ -e "${PATH_SEGMANUAL}/${SITE}/${FILESEG}-manual.nii.gz" ]; then
    rsync -avzh "${PATH_SEGMANUAL}/${SITE}/${FILESEG}-manual.nii.gz" ${FILESEG}.nii.gz
  else
    # Segment spinal cord
    sct_deepseg_sc -i ${file}.nii.gz -c $contrast -qc ${PATH_QC} -qc-dataset ${SITE} -qc-subject ${SUBJECT}
  fi
}


# SCRIPT STARTS HERE
# ==============================================================================

# Go to anat folder where all structural data are located
cd ${SUBJECT}/anat/

# T1w
# ------------------------------------------------------------------------------
file_t1="${SUBJECT}_T1w"
# Reorient to RPI and resample to 1mm iso (supposed to be the effective resolution)
sct_image -i ${file_t1}.nii.gz -setorient RPI -o ${file_t1}_RPI.nii.gz
sct_resample -i ${file_t1}_RPI.nii.gz -mm 1x1x1 -o ${file_t1}_RPI_r.nii.gz
file="${file_t1}_RPI_r"
# Segment spinal cord (only if it does not exist)
segment_if_does_not_exist $file_t1 "t1"
file_t1_seg=$FILESEG
# Create labels in the cord at C2 and C5 mid-vertebral levels (only if it does not exist)
label_if_does_not_exist ${file_t1} ${file_t1_seg}
file_label=$FILELABEL
# Register to PAM50 template
sct_register_to_template -i ${file_t1}.nii.gz -s ${file_t1_seg}.nii.gz -l labels_vert.nii.gz -c t1 -param step=1,type=seg,algo=centermassrot:step=2,type=seg,algo=syn,slicewise=1,smooth=0,iter=5:step=3,type=im,algo=syn,slicewise=1,smooth=0,iter=3 -qc ${PATH_QC}
# Rename warping fields for clarity
mv warp_template2anat.nii.gz warp_template2T1w.nii.gz
mv warp_anat2template.nii.gz warp_T1w2template.nii.gz
# Warp template without the white matter atlas (we don't need it at this point)
sct_warp_template -d ${file_t1}.nii.gz -w warp_template2T1w.nii.gz -a 0 -ofolder label_T1w
# Flatten scan along R-L direction (to make nice figures)
sct_flatten_sagittal -i ${file_t1}.nii.gz -s ${file_t1_seg}.nii.gz
# Compute average cord CSA between C2 and C3
sct_process_segmentation -i ${file_t1_seg}.nii.gz -vertfile ${file_t1_seg}_labeled.nii.gz -vert 2:3 -o ${PATH_OUTPUT}/csa-SC_T1w.csv -append 1

# T2
# ------------------------------------------------------------------------------
file_t2="${SUBJECT}_T2w"
# Reorient to RPI and resample to 0.8mm iso (supposed to be the effective resolution)
sct_image -i ${file_t2}.nii.gz -setorient RPI -o ${file_t2}_RPI.nii.gz
sct_resample -i ${file_t2}_RPI.nii.gz -mm 0.8x0.8x0.8 -o ${file_t2}_RPI_r.nii.gz
file_t2="${file_t2}_RPI_r"
# Segment spinal cord (only if it does not exist)
segment_if_does_not_exist $file_t2 "t2"
file_t2_seg=$FILESEG
# Flatten scan along R-L direction (to make nice figures)
sct_flatten_sagittal -i ${file_t2}.nii.gz -s ${file_t2_seg}.nii.gz
# Bring vertebral level into T2 space
sct_register_multimodal -i ${file_t1_seg}_labeled.nii.gz -d ${file_t2_seg}.nii.gz -o ${file_t1_seg}_labeled2${file_t2}.nii.gz -identity 1 -x nn
# Compute average cord CSA between C2 and C3
sct_process_segmentation -i ${file_t2_seg}.nii.gz -vert 2:3 -vertfile ${file_t1_seg}_labeled2${file_t2}.nii.gz -o ${PATH_OUTPUT}/csa-SC_T2w.csv -append 1

# MTS
# ------------------------------------------------------------------------------
file_t1w="${SUBJECT}_acq-T1w_MTS"
file_mton="${SUBJECT}_acq-MTon_MTS"
file_mtoff="${SUBJECT}_acq-MToff_MTS"
# Segment spinal cord (only if it does not exist)
segment_if_does_not_exist $file_t1w "t1"
file_t1w_seg=$FILESEG
# Create mask
sct_create_mask -i ${file_t1w}.nii.gz -p centerline,${file_t1w_seg}.nii.gz -size 35mm -o ${file_t1w}_mask.nii.gz
# Crop data for faster processing
sct_crop_image -i ${file_t1w}.nii.gz -m ${file_t1w}_mask.nii.gz -o ${file_t1w}_crop.nii.gz
file_t1w="${file_t1w}_crop"
# Register PD->T1w
# Tips: here we only use rigid transformation because both images have very similar sequence parameters. We don't want to use SyN/BSplineSyN to avoid introducing spurious deformations.
sct_register_multimodal -i ${file_mtoff}.nii.gz -d ${file_t1w}.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -x spline
file_mtoff="${file_mtoff}_reg"
# Register MT->T1w
sct_register_multimodal -i ${file_mton}.nii.gz -d ${file_t1w}.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -x spline
file_mton="${file_mton}_reg"
# Register template->T1w_ax (using template-T1w as initial transformation)
sct_register_multimodal -i $SCT_DIR/data/PAM50/template/PAM50_t1.nii.gz -iseg $SCT_DIR/data/PAM50/template/PAM50_cord.nii.gz -d ${file_t1w}.nii.gz -dseg ${file_t1w_seg}.nii.gz -param step=1,type=seg,algo=slicereg,metric=MeanSquares,smooth=2:step=2,type=im,algo=bsplinesyn,metric=MeanSquares,iter=5,gradStep=0.5 -initwarp warp_template2T1w.nii.gz -initwarpinv warp_T1w2template.nii.gz
# Rename warping field for clarity
mv warp_PAM50_t12${file_t1w}.nii.gz warp_template2axT1w.nii.gz
mv warp_${file_t1w}2PAM50_t1.nii.gz warp_axT1w2template.nii.gz
# Warp template
sct_warp_template -d ${file_t1w}.nii.gz -w warp_template2axT1w.nii.gz -ofolder label_axT1w
# Compute MTR
sct_compute_mtr -mt0 ${file_mtoff}.nii.gz -mt1 ${file_mton}.nii.gz
# Compute MTsat
sct_compute_mtsat -mt ${file_mton}.nii.gz -pd ${file_mtoff}.nii.gz -t1 ${file_t1w}.nii.gz -trmt 57 -trpd 57 -trt1 15 -famt 9 -fapd 9 -fat1 15
# Extract MTR, MTsat and T1 in WM between C2 and C5 vertebral levels
sct_extract_metric -i mtr.nii.gz -f label_axT1w/atlas -l 51 -vert 2:5 -vertfile label_axT1w/template/PAM50_levels.nii.gz -o ${PATH_OUTPUT}/MTR.csv -append 1
sct_extract_metric -i mtsat.nii.gz -f label_axT1w/atlas -l 51 -vert 2:5 -vertfile label_axT1w/template/PAM50_levels.nii.gz -o ${PATH_OUTPUT}/MTsat.csv -append 1
sct_extract_metric -i t1map.nii.gz -f label_axT1w/atlas -l 51 -vert 2:5 -vertfile label_axT1w/template/PAM50_levels.nii.gz -o ${PATH_OUTPUT}/T1.csv -append 1

# t2s
# ------------------------------------------------------------------------------
file_t2s="${SUBJECT}_T2star"
# Compute root-mean square across 4th dimension (if it exists), corresponding to all echoes in Philips scans.
sct_maths -i ${file_t2s}.nii.gz -rms t -o ${file_t2s}_rms.nii.gz
file_t2s="${file_t2s}_rms"
# Segment spinal cord (only if it does not exist)
segment_if_does_not_exist $file_t2s "t2s"
file_t2s_seg=$FILESEG
# Bring vertebral level into T2s space
sct_register_multimodal -i ${file_t1_seg}_labeled.nii.gz -d ${file_t2s_seg}.nii.gz -o ${file_t1_seg}_labeled2${file_t2s}.nii.gz -identity 1 -x nn
# Compute the gray matter CSA between C3 and C4 levels
# NB: Here we set -no-angle 1 because we do not want angle correction: it is too
# unstable with GM seg, and t2s data were acquired orthogonal to the cord anyways.
sct_process_segmentation -i ${file_t2s_seg}.nii.gz -angle-corr 0 -vert 3:4 -vertfile ${file_t1_seg}_labeled2${file_t2s}.nii.gz -o ${PATH_OUTPUT}/csa-GM_T2s.csv -append 1

# DWI
# ------------------------------------------------------------------------------
cd ../dwi
# Separate b=0 and DW images
sct_dmri_separate_b0_and_dwi -i ${SUBJECT}_dwi.nii.gz -bvec ${SUBJECT}_dwi.bvec
# Segment cord (1st pass -- just to get rough centerline)
sct_propseg -i ${SUBJECT}_dwi_dwi_mean.nii.gz -c dwi
# Create mask to help motion correction and for faster processing
sct_create_mask -i ${SUBJECT}_dwi_dwi_mean.nii.gz -p centerline,${SUBJECT}_dwi_dwi_mean_seg.nii.gz -size 30mm
# Crop data for faster processing
sct_crop_image -i ${SUBJECT}_dwi.nii.gz -m mask_${SUBJECT}_dwi_dwi_mean.nii.gz -o ${SUBJECT}_dwi_crop.nii.gz
# Motion correction
sct_dmri_moco -i ${SUBJECT}_dwi_crop.nii.gz -bvec ${SUBJECT}_dwi.bvec -x spline
file_dwi=${SUBJECT}_dwi_crop_moco
file_dwi_mean=${SUBJECT}_dwi_crop_moco_dwi_mean
# Segment spinal cord (only if it does not exist)
segment_if_does_not_exist ${file_dwi_mean} "dwi"
file_dwi_seg=$FILESEG
# Register template->dwi (using template-T1w as initial transformation)
sct_register_multimodal -i $SCT_DIR/data/PAM50/template/PAM50_t1.nii.gz -iseg $SCT_DIR/data/PAM50/template/PAM50_cord.nii.gz -d ${file_dwi_mean}.nii.gz -dseg ${file_dwi_seg}.nii.gz -param step=1,type=seg,algo=slicereg,metric=MeanSquares,smooth=2:step=2,type=im,algo=bsplinesyn,metric=MeanSquares,iter=5,gradStep=0.5 -initwarp ../anat/warp_template2T1w.nii.gz -initwarpinv ../anat/warp_T1w2template.nii.gz
# Rename warping field for clarity
mv warp_PAM50_t12${file_dwi_mean}.nii.gz warp_template2dwi.nii.gz
mv warp_${file_dwi_mean}2PAM50_t1.nii.gz warp_dwi2template.nii.gz
# Warp template
sct_warp_template -d ${file_dwi_mean}.nii.gz -w warp_template2dwi.nii.gz
# Create mask around the spinal cord (for faster computing)
sct_maths -i ${file_dwi_seg}.nii.gz -dilate 3,3,3 -o ${file_dwi_seg}_dil.nii.gz
# Compute DTI using RESTORE
sct_dmri_compute_dti -i ${file_dwi}.nii.gz -bvec ${SUBJECT}_dwi.bvec -bval ${SUBJECT}_dwi.bval -method restore -m ${file_dwi_seg}_dil.nii.gz
# Compute FA, MD and RD in WM between C2 and C5 vertebral levels
sct_extract_metric -i dti_FA.nii.gz -f label/atlas -l 51 -vert 2:5 -o ${PATH_OUTPUT}/DWI_FA.csv -append 1
sct_extract_metric -i dti_MD.nii.gz -f label/atlas -l 51 -vert 2:5 -o ${PATH_OUTPUT}/DWI_MD.csv -append 1
sct_extract_metric -i dti_RD.nii.gz -f label/atlas -l 51 -vert 2:5 -o ${PATH_OUTPUT}/DWI_RD.csv -append 1
# Go back to parent folder
cd ..
