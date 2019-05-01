#!/bin/bash
# Environment variables for the spineGeneric study.

# Set every other path relative to this path for convenience
# Do not add "/" at the end. Path should be absolute (i.e. do not use "~")
export PATH_PARENT="/Users/julien/spineGeneric_multiSubjects"

# Path to the folder site which contains all sites.
# Do not add "/" at the end. Path should be absolute (i.e. do not use "~")
export PATH_DATA="${PATH_PARENT}/data"

# List of subjects to analyse. Comment this variable if you want to analyze all
# sites in the PATH_DATA folder.
#export SITES=(
#	"amu_spineGeneric"
#)

# Paths to where to save the new dataset.
# Do not add "/" at the end. Path should be absolute (i.e. do not use "~")
export PATH_OUTPUT="${PATH_PARENT}/results"
export PATH_QC="${PATH_PARENT}/qc"
export PATH_LOG="${PATH_PARENT}/log"

# Location of manually-corrected segmentations
export PATH_SEGMANUAL="${PATH_PARENT}/seg_manual"

# Number of jobs for parallel processing
export JOBS=20

# Number of jobs for ANTs routine. Set to 1 if ANTs functions crash when CPU saturates.
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
