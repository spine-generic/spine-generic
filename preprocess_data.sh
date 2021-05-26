#!/bin/bash
#
# Preprocess data. 
#     For T1w and T2w : From raw images, proceeds to resampling and reorientation to RPI.
#     For T2s : Compute root-mean square across 4th dimension (if it exists)
#     For dwi : Generate mean image after motion correction.
#
# Usage:
#   ./preprocess_data.sh <SUBJECT>
#
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


# FUNCTIONS
# ==============================================================================

# If there is an additional b=0 scan, add it to the main DWI data and update the
# bval and bvec files.
concatenate_b0_and_dwi(){
  local file_b0="$1"  # does not have extension
  local file_dwi="$2"  # does not have extension
  if [[ -e ${file_b0}.nii.gz ]]; then
    echo "Found additional b=0 scans: $file_b0.nii.gz They will be concatenated to the DWI scans."
    sct_dmri_concat_b0_and_dwi -i ${file_b0}.nii.gz ${file_dwi}.nii.gz -bval ${file_dwi}.bval -bvec ${file_dwi}.bvec -order b0 dwi -o ${file_dwi}_concat.nii.gz -obval ${file_dwi}_concat.bval -obvec ${file_dwi}_concat.bvec
    # Update global variable
    FILE_DWI="${file_dwi}_concat"
  else
    echo "No additional b=0 scans was found."
    FILE_DWI="${file_dwi}"
  fi
}


# T1w
# ------------------------------------------------------------------------------
file_t1="${SUBJECT}_T1w"
# Rename the raw image
mv ${file_t1}.nii.gz ${file_t1}_raw.nii.gz
file_t1="${file_t1}_raw"

# Reorient to RPI and resample to 1mm iso (supposed to be the effective resolution)
sct_image -i ${file_t1}.nii.gz -setorient RPI -o ${file_t1}_RPI.nii.gz
sct_resample -i ${file_t1}_RPI.nii.gz -mm 1x1x1 -o ${file_t1}_RPI_r.nii.gz
file_t1="${file_t1}_RPI_r"

# Rename _RPI_r file
mv ${file_t1}.nii.gz ${SUBJECT}_T1w.nii.gz

# Delete raw and reoriented to RPI images
rm -f ${SUBJECT}_T1w_raw.nii.gz ${SUBJECT}_T1w_raw_RPI.nii.gz


# T2
# ------------------------------------------------------------------------------
file_t2="${SUBJECT}_T2w"
# Rename raw file
mv ${file_t2}.nii.gz ${file_t2}_raw.nii.gz
file_t2="${file_t2}_raw"

# Reorient to RPI and resample to 0.8mm iso (supposed to be the effective resolution)
sct_image -i ${file_t2}.nii.gz -setorient RPI -o ${file_t2}_RPI.nii.gz
sct_resample -i ${file_t2}_RPI.nii.gz -mm 0.8x0.8x0.8 -o ${file_t2}_RPI_r.nii.gz
file_t2="${file_t2}_RPI_r"

# Rename _RPI_r file
mv ${file_t2}.nii.gz ${SUBJECT}_T2w.nii.gz

# Delete raw, reoriented to RPI images
rm -f ${SUBJECT}_T2w_raw.nii.gz ${SUBJECT}_T2w_raw_RPI.nii.gz


# T2s
# ------------------------------------------------------------------------------
file_t2s="${SUBJECT}_T2star"
# Rename raw file
mv ${file_t2s}.nii.gz ${file_t2s}_raw.nii.gz
file_t2s="${file_t2s}_raw"

# Compute root-mean square across 4th dimension (if it exists), corresponding to all echoes in Philips scans.
sct_maths -i ${file_t2s}.nii.gz -rms t -o ${file_t2s}_rms.nii.gz
file_t2s="${file_t2s}_rms"

# Rename _rms file
mv ${file_t2s}.nii.gz ${SUBJECT}_T2star.nii.gz

# Delete raw images
rm -f ${SUBJECT}_T2star_raw.nii.gz


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
# Get centerline
sct_get_centerline -i ${file_dwi}_dwi_mean.nii.gz -c dwi -qc ${PATH_QC} -qc-subject ${SUBJECT}
# Create mask to help motion correction and for faster processing
sct_create_mask -i ${file_dwi}_dwi_mean.nii.gz -p centerline,${file_dwi}_dwi_mean_centerline.nii.gz -size 30mm
# Motion correction
sct_dmri_moco -i ${file_dwi}.nii.gz -bvec ${file_dwi}.bvec -m mask_${file_dwi}_dwi_mean.nii.gz -x spline

# Rename _moco_dwi_mean file
mv ${FILE_DWI}_moco_dwi_mean.nii.gz ${SUBJECT}_rec-average_dwi.nii.gz

# Remove intermediate files
if [[ -e ${SUBJECT}_acq-b0_dwi.nii.gz ]]; then
    rm -f mask_${FILE_DWI}_dwi_mean.nii.gz moco_params.tsv moco_params_x.nii.gz moco_params_y.nii.gz ${FILE_DWI}.bval ${FILE_DWI}.bvec ${FILE_DWI}.nii.gz ${FILE_DWI}_b0.nii.gz ${FILE_DWI}_b0_mean.nii.gz ${FILE_DWI}_dwi.nii.gz ${FILE_DWI}_dwi_mean.nii.gz ${FILE_DWI}_dwi_mean_centerline.nii.gz ${FILE_DWI}_moco.nii.gz ${FILE_DWI}_moco_b0_mean.nii.gz ${FILE_DWI}_dwi_mean_centerline.csv
else
    rm -f mask_${FILE_DWI}_dwi_mean.nii.gz moco_params.tsv moco_params_x.nii.gz moco_params_y.nii.gz ${FILE_DWI}_b0.nii.gz ${FILE_DWI}_b0_mean.nii.gz ${FILE_DWI}_dwi.nii.gz ${FILE_DWI}_dwi_mean.nii.gz ${FILE_DWI}_dwi_mean_centerline.nii.gz ${FILE_DWI}_moco.nii.gz ${FILE_DWI}_moco_b0_mean.nii.gz ${FILE_DWI}_dwi_mean_centerline.csv
fi

# Go back to parent folder
cd ..

# Verify presence of output files and write log file if error
# ------------------------------------------------------------------------------
FILES_TO_CHECK=(
  "anat/${SUBJECT}_T1w.nii.gz"
  "anat/${SUBJECT}_T2w.nii.gz"
  "anat/${SUBJECT}_T2star.nii.gz"
  "dwi/${SUBJECT}_rec-average_dwi.nii.gz"
)
pwd
for file in ${FILES_TO_CHECK[@]}; do
  if [[ ! -e $file ]]; then
    echo "${SUBJECT}/anat/${file} does not exist" >> $PATH_LOG/_error_check_output_files.log
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
