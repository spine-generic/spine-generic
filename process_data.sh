#!/bin/bash
#
# Process data, modfified version to only create SC segmentations and GM segmentation for T2s. Uses spine-generic-processed as an input.
#
# Usage:
#   ./process_data.sh <SUBJECT>
#
# Manual segmentations or labels should be located under:
# PATH_DATA/derivatives/labels/SUBJECT/<CONTRAST>/
#
# Authors: Julien Cohen-Adad, Sandrine Bédard

# The following global variables are retrieved from the caller sct_run_batch
# but could be overwritten by uncommenting the lines below:
# PATH_DATA_PROCESSED="~/data_processed"
# PATH_RESULTS="~/results"
# PATH_LOG="~/log"
# PATH_QC="~/qc"

# Uncomment for full verbose
set -x

# Immediately exit if error
set -e -o pipefail

# Exit if user presses CTRL+C (Linux) or CMD+C (OSX)
trap "echo Caught Keyboard Interrupt within script. Exiting now.; exit" INT

# Retrieve input params
SUBJECT=$1

# get starting time:
start=`date +%s`


# FUNCTIONS
# ==============================================================================

# Check if manual segmentation already exists. If it does, copy it locally. If
# it does not, perform seg.
segment_if_does_not_exist(){
  local file="$1"
  local contrast="$2"
  # Find contrast
  if [[ $contrast == "dwi" ]]; then
    folder_contrast="dwi"
  else
    folder_contrast="anat"
  fi
  # Update global variable with segmentation file name
  FILESEG="${file}_seg"
  FILESEGMANUAL="${PATH_DATA}/derivatives/labels/${SUBJECT}/${folder_contrast}/${FILESEG}-manual.nii.gz"
  echo
  echo "Looking for manual segmentation: $FILESEGMANUAL"
  if [[ -e $FILESEGMANUAL ]]; then
    echo "Found! Using manual segmentation."
    rsync -avzh $FILESEGMANUAL ${FILESEG}.nii.gz
    sct_qc -i ${file}.nii.gz -s ${FILESEG}.nii.gz -p sct_deepseg_sc -qc ${PATH_QC} -qc-subject ${SUBJECT}
  else
    echo "Not found. Proceeding with automatic segmentation."
    # Segment spinal cord
    sct_deepseg_sc -i ${file}.nii.gz -c $contrast -qc ${PATH_QC} -qc-subject ${SUBJECT}
  fi
}

# Check if manual segmentation already exists. If it does, copy it locally. If
# it does not, perform seg.
segment_gm_if_does_not_exist(){
  local file="$1"
  local contrast="$2"
  # Update global variable with segmentation file name
  FILESEG="${file}_gmseg"
  FILESEGMANUAL="${PATH_DATA}/derivatives/labels/${SUBJECT}/anat/${FILESEG}-manual.nii.gz"
  echo "Looking for manual segmentation: $FILESEGMANUAL"
  if [[ -e $FILESEGMANUAL ]]; then
    echo "Found! Using manual segmentation."
    rsync -avzh $FILESEGMANUAL ${FILESEG}.nii.gz
    sct_qc -i ${file}.nii.gz -s ${FILESEG}.nii.gz -p sct_deepseg_gm -qc ${PATH_QC} -qc-subject ${SUBJECT}
  else
    echo "Not found. Proceeding with automatic segmentation."
    # Segment spinal cord
    sct_deepseg_gm -i ${file}.nii.gz -qc ${PATH_QC} -qc-subject ${SUBJECT}
  fi
}


# SCRIPT STARTS HERE
# ==============================================================================
# Display useful info for the log, such as SCT version, RAM and CPU cores available
sct_check_dependencies -short

# Go to folder where data will be copied and processed
cd $PATH_DATA_PROCESSED
# Copy list of participants in processed data folder
if [[ ! -f "participants.tsv" ]]; then
  rsync -avzh $PATH_DATA/participants.tsv .
fi
# Copy list of participants in results folder (used by spine-generic scripts)
if [[ ! -f $PATH_RESULTS/"participants.tsv" ]]; then
  rsync -avzh $PATH_DATA/participants.tsv $PATH_RESULTS/"participants.tsv"
fi
# Copy source images
rsync -avzh $PATH_DATA/$SUBJECT .
# Go to anat folder where all structural data are located
cd ${SUBJECT}/anat/


# T1w
# ------------------------------------------------------------------------------
file_t1="${SUBJECT}_T1w"
# Segment spinal cord (only if it does not exist)
segment_if_does_not_exist $file_t1 "t1"


# T2w
# ------------------------------------------------------------------------------
file_t2="${SUBJECT}_T2w"
# Segment spinal cord (only if it does not exist)
segment_if_does_not_exist $file_t2 "t2"


# MTS
# ------------------------------------------------------------------------------
file_t1w="${SUBJECT}_acq-T1w_MTS"
file_mton="${SUBJECT}_acq-MTon_MTS"

segment_if_does_not_exist $file_t1w "t1" 
segment_if_does_not_exist $file_mton "t2s"


# T2s
# ------------------------------------------------------------------------------
file_t2s="${SUBJECT}_T2star"

# Segment spinal cord (only if it does not exist)
segment_if_does_not_exist $file_t2s "t2s"

# Segment gray matter (only if it does not exist)
segment_gm_if_does_not_exist $file_t2s "t2s"


# DWI
# ------------------------------------------------------------------------------
cd ../dwi
file_dwi_mean="${SUBJECT}_rec-average_dwi"

# Segment spinal cord (only if it does not exist)
segment_if_does_not_exist ${file_dwi_mean} "dwi"

# Go back to parent folder
cd ..

# Verify presence of output files and write log file if error
# ------------------------------------------------------------------------------
FILES_TO_CHECK=(
  "anat/${SUBJECT}_T1w_seg.nii.gz"
  "anat/${SUBJECT}_T2w_seg.nii.gz"
  "anat/${SUBJECT}_acq-T1w_MTS_seg.nii.gz"
  "anat/${SUBJECT}_acq-MTon_MTS_seg.nii.gz"
  "anat/${SUBJECT}_T2star_seg.nii.gz"
  "anat/${SUBJECT}_T2star_gmseg.nii.gz"
  "dwi/${SUBJECT}_rec-average_dwi_seg.nii.gz"
)
for file in ${FILES_TO_CHECK[@]}; do
  if [[ ! -e $file ]]; then
    echo "${SUBJECT}/${file} does not exist" >> $PATH_LOG/_error_check_output_files.log
  fi
done

# Display useful info for the log
end=`date +%s`
runtime=$((end-start))
echo
echo "~~~"
echo "SCT version: `sct_version`"
echo "Ran on:      `uname -nsr`"
echo "Duration:    $(($runtime / 3600))hrs $((($runtime / 60) % 60))min $(($runtime % 60))sec"
echo "~~~"
