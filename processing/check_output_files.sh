#!/bin/bash
#
# Check the presence of output files (after running process_data).
#
# Usage:
#   ./check_output_files.sh <SUBJECT> <SITE> <PATH_OUTPUT> <PATH_QC> <PATH_LOG>

# Exit if user presses CTRL+C (Linux) or CMD+C (OSX)
trap "echo Caught Keyboard Interrupt within script. Exiting now.; exit" INT

# Retrieve input params
SUBJECT=$1
SITE=$2
PATH_OUTPUT=$3
PATH_QC=$4
PATH_LOG=$5

# Create BIDS architecture
PATH_IN="`pwd`/${SUBJECT}"

# Verify presence of output files and write log file if error
FILES_TO_CHECK=(
  "$PATH_IN/anat/${SUBJECT}_T1w_seg.nii.gz"
  "$PATH_IN/anat/${SUBJECT}_T1w_seg_labeled.nii.gz"
  "$PATH_IN/anat/${SUBJECT}_T2w_seg.nii.gz"
  "$PATH_IN/anat/${SUBJECT}_T1w_seg_labeled2T2w.nii.gz"
  "$PATH_IN/anat/label_axT1w/template/PAM50_levels.nii.gz"
  "$PATH_IN/anat/mtr.nii.gz"
  "$PATH_IN/anat/mtsat.nii.gz"
  "$PATH_IN/anat/t1map.nii.gz"
  "$PATH_IN/anat/${SUBJECT}_T2star_rms_gmseg.nii.gz"
  "$PATH_IN/anat/${SUBJECT}_T1w_seg_labeled2T2star.nii.gz"
  "$PATH_IN/anat/dti_FA.nii.gz"
  "$PATH_IN/dwi/dti_MD.nii.gz"
  "$PATH_IN/dwi/dti_RD.nii.gz"
  "$PATH_IN/dwi/label/atlas/PAM50_atlas_00.nii.gz"
)
for file in ${FILES_TO_CHECK[@]}; do
  if [ ! -e $file ]; then
    echo "${file} does not exist" >> $PATH_LOG/_error_check_input_files.log
  fi
done
