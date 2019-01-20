#!/bin/bash
# Environment variables for the spineGeneric study.

# Set every other path relative to this path for convenience
# Do not add "/" at the end. Path should be absolute (i.e. do not use "~")
export PATH_PARENT="/Users/julien/data"

# Path to the folder site which contains all sites.
# Do not add "/" at the end. Path should be absolute (i.e. do not use "~")
export PATH_DATA="${PATH_PARENT}/spineGeneric_multiSubjects"

# List of subjects to analyse. Comment this variable if you want to analyze all
# sites in the PATH_DATA folder.
#export SITES=(
#	"ucl"
#	"unf"
#)

# Paths to where to process and save results and QC report.
# Do not add "/" at the end. Path should be absolute (i.e. do not use "~")
export PATH_PROCESSING="${PATH_PARENT}/spineGeneric_multiSubjects_results"
export PATH_QC="${PATH_PARENT}/spineGeneric_multiSubjects_qc"
