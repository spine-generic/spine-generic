#!/bin/bash
# Environment variables for the spineGeneric study.

# Path to the folder site which contains all sites.
# Do not add "/" at the end. Path should be absolute (i.e. do not use "~")
export PATH_DATA="/Users/julien/Desktop/spineGeneric_multiSubjects"

# List of subjects to analyse. Comment this variable if you want to analyze all
# sites in the PATH_DATA folder.
export SITES=(
	"ucl"
	"unf"
)

# List of subjects to analyse. Comment this variable if you want to analyze all
# subjects in each site folder.
# export SUBJECTS=(
# 	"sub-01"
# 	"sub-02"
# 	"sub-03"
# 	"sub-04"
# 	"sub-05"
# 	"sub-06"
# )

# Paths to where to process and save results and QC report.
# Do not add "/" at the end. Path should be absolute (i.e. do not use "~")
export PATH_PROCESSING="/Users/julien/data/spineGeneric_multiSubject/results"
export PATH_QC="/Users/julien/data/spineGeneric_multiSubject/qc"
