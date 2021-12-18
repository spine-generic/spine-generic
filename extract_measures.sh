#!/bin/bash
#
# Process data.
#
# Usage:
#   ./process_data.sh <SUBJECT>
#
# Manual segmentations or labels should be located under:
# PATH_DATA/derivatives/labels/SUBJECT/<CONTRAST>/
#
# Authors: Julien Cohen-Adad

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





# SCRIPT STARTS HERE
# ==============================================================================
# Display useful info for the log, such as SCT version, RAM and CPU cores available
sct_check_dependencies -short

# Go to folder where data will be copied and processed
cd $PATH_DATA_PROCESSED

# Go to anat folder where all structural data are located
cd ${SUBJECT}/dwi

# Compute FA, MD and RD in LCST between C2 and C5 vertebral levels
sct_extract_metric -i dti_FA.nii.gz -f label/atlas -l 11,17 -vert 2:5 -o ${PATH_RESULTS}/DWI_FA_LCST.csv -append 1 -combine 1
sct_extract_metric -i dti_MD.nii.gz -f label/atlas -l 11,17 -vert 2:5 -o ${PATH_RESULTS}/DWI_MD_LCST.csv -append 1 -combine 1
sct_extract_metric -i dti_RD.nii.gz -f label/atlas -l 11,17 -vert 2:5 -o ${PATH_RESULTS}/DWI_RD_LCST.csv -append 1 -combine 1

# Display useful info for the log
end=`date +%s`
runtime=$((end-start))
echo
echo "~~~"
echo "SCT version: `sct_version`"
echo "Ran on:      `uname -nsr`"
echo "Duration:    $(($runtime / 3600))hrs $((($runtime / 60) % 60))min $(($runtime % 60))sec"
echo "~~~"
