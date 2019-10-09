#!/bin/bash
#
# Process data. This script should be run within the subject's folder.
#
# Usage:
#   ./process_data.sh <SUBJECT> <PATH_RESULTS> <PATH_QC> <PATH_LOG>
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
FILEPARAM=$2

# Thresholds to test deepseg
# THR=('0.0' '0.1' '0.2' '0.3' '0.4' '0.5' '0.6' '0.7' '0.8' '0.9')
THR=('0.5')

# FUNCTIONS
# ==============================================================================

# If there is an additional b=0 scan, add it to the main DWI data and update the
# bval and bvec files.
concatenate_b0_and_dwi(){
  local file_b0="$1"  # does not have extension
  local file_dwi="$2"  # does not have extension
  if [ -e ${file_b0}.nii.gz ]; then
    echo "Found additional b=0 scans: $file_b0.nii.gz They will be concatenated to the DWI scans."
    sct_dmri_concat_b0_and_dwi -i ${file_b0}.nii.gz ${file_dwi}.nii.gz -bval ${file_dwi}.bval -bvec ${file_dwi}.bvec -order b0 dwi -o ${file_dwi}_concat.nii.gz -obval ${file_dwi}_concat.bval -obvec ${file_dwi}_concat.bvec
    # Update global variable
    FILE_DWI="${file_dwi}_concat"
  else
    echo "No additional b=0 scans was found."
    FILE_DWI="${file_dwi}"
  fi
}

# Get specific field from json file
get_field_from_json(){
  local file="$1"
  local field="$2"
  echo `grep $field $file | sed 's/[^0-9]*//g'`
}


# SCRIPT STARTS HERE
# ==============================================================================
# Load environment variables
source $FILEPARAM
# Go to results folder, where most of the outputs will be located
cd $PATH_RESULTS
# Copy source images
mkdir -p data
cd data
cp -r $PATH_DATA/$SUBJECT .
# Go to anat folder where all structural data are located
cd ${SUBJECT}/anat/

# T1w
# ------------------------------------------------------------------------------
file_t1="${SUBJECT}_T1w"
file_t2s="${SUBJECT}_T2star"
# Reorient to RPI and resample to 1mm iso (supposed to be the effective resolution)
sct_image -i ${file_t1}.nii.gz -setorient RPI -o ${file_t1}_RPI.nii.gz
sct_resample -i ${file_t1}_RPI.nii.gz -mm 1x1x1 -o ${file_t1}_RPI_r.nii.gz
file_t1="${file_t1}_RPI_r"
# Segment spinal cord (first pass, to get labeled seg)
sct_deepseg_sc -i ${file_t1}.nii.gz -c t1 -thr 0.5
# Generate labeled segmentation
sct_label_vertebrae -i ${file_t1}.nii.gz -s ${file_t1}_seg.nii.gz -c t1 -qc ${PATH_QC} -qc-subject ${SUBJECT}
# Loop across thresholds
for thr in ${THR[@]}; do
  # T1w
  sct_deepseg_sc -i ${file_t1}.nii.gz -c t1 -thr ${thr}
  sct_process_segmentation -i ${file_t1}_seg.nii.gz -vert 2:4 -vertfile ${file_t1}_seg_labeled.nii.gz -o ${PATH_RESULTS}/csa-T1_${thr}.csv -append 1
done

# T2
# ------------------------------------------------------------------------------
file_t2="${SUBJECT}_T2w"
segment_if_does_not_exist $file_t2 "t2"
# Bring vertebral level into T2 space
sct_register_multimodal -i ${file_t1}_seg_labeled.nii.gz -d ${file_t2}.nii.gz -x nn -identity 1 -o ${file_t2}_seg_labeled.nii.gz
# Segment with variable thresholds
for thr in ${THR[@]}; do
  sct_deepseg_sc -i ${file_t2}.nii.gz -c t2 -thr ${thr}
  sct_process_segmentation -i ${file_t2}_seg.nii.gz -vert 2:4 -vertfile ${file_t2}_seg_labeled.nii.gz -o ${PATH_RESULTS}/csa-T2_${thr}.csv -append 1
done

# MTS
# ------------------------------------------------------------------------------
file_t1w="${SUBJECT}_acq-T1w_MTS"
file_mton="${SUBJECT}_acq-MTon_MTS"
# Bring vertebral level into MTS space
sct_register_multimodal -i ${file_t1}_seg_labeled.nii.gz -d ${file_t1w}.nii.gz -x nn -identity 1 -o ${file_t1w}_seg_labeled.nii.gz
# Segment with variable thresholds
for thr in ${THR[@]}; do
  sct_deepseg_sc -i ${file_t1w}.nii.gz -c t1 -thr ${thr}
  sct_process_segmentation -i ${file_t1w}_seg.nii.gz -vert 2:4 -vertfile ${file_t1w}_seg_labeled.nii.gz -o ${PATH_RESULTS}/csa-T1w_${thr}.csv -append 1
  sct_deepseg_sc -i ${file_mton}.nii.gz -c t2 -thr ${thr}
  sct_process_segmentation -i ${file_mton}_seg.nii.gz -vert 2:4 -vertfile ${file_t1w}_seg_labeled.nii.gz -o ${PATH_RESULTS}/csa-MTon_${thr}.csv -append 1
done

# T2s
# ------------------------------------------------------------------------------
file_t2s="${SUBJECT}_T2star"
# Compute root-mean square across 4th dimension (if it exists), corresponding to all echoes in Philips scans.
sct_maths -i ${file_t2s}.nii.gz -rms t -o ${file_t2s}_rms.nii.gz
file_t2s="${file_t2s}_rms"
# Bring vertebral level into T2s space
sct_register_multimodal -i ${file_t1}_seg_labeled.nii.gz -d ${file_t2s}.nii.gz -x nn -identity 1 -o ${file_t2s}_seg_labeled.nii.gz
# Segment with variable thresholds
for thr in ${THR[@]}; do
  sct_deepseg_sc -i ${file_t2s}.nii.gz -c t2s -thr ${thr}
  sct_process_segmentation -i ${file_t2s}_seg.nii.gz -vert 2:4 -vertfile ${file_t2s}_seg_labeled.nii.gz -o ${PATH_RESULTS}/csa-T2s_${thr}.csv -append 1
done

# DWI
# ------------------------------------------------------------------------------
file_dwi="${SUBJECT}_dwi"
cd ../dwi
# If there is an additional b=0 scan, add it to the main DWI data
concatenate_b0_and_dwi "${SUBJECT}_acq-b0_dwi" $file_dwi
file_dwi=$FILE_DWI
file_bval=${file_dwi}.bval
file_bvec=${file_dwi}.bvec
# Separate b=0 and DW images
sct_dmri_separate_b0_and_dwi -i ${file_dwi}.nii.gz -bvec ${file_bvec}
file_dwi=${file_dwi}_dwi_mean
# Bring vertebral level into DWI space
sct_register_multimodal -i ${file_t1}_seg_labeled.nii.gz -d ${file_dwi}.nii.gz -x nn -identity 1 -o ${file_dwi}_seg_labeled.nii.gz
# Segment with variable thresholds
for thr in ${THR[@]}; do
  sct_deepseg_sc -i ${file_dwi}.nii.gz -c dwi -thr ${thr}
  sct_process_segmentation -i ${file_dwi}_seg.nii.gz -vert 2:4 -vertfile ${file_dwi}_seg_labeled.nii.gz -o ${PATH_RESULTS}/csa-DWI_${thr}.csv -append 1
done

# Go back to parent folder
cd ..
