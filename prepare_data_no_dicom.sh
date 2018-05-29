#!/bin/bash

# Prepare data for NIfTI files (instead of starting with DICOM)

# Converts DICOM images to NIfTI images
# NIfTI images are placed within the appropriate folder structure

# To run: ./prepare_data FOLDER (with the slash at the end)

# Initialization. Always put "/" at the end.
path_output="/Volumes/duke/projects/generic_spine_procotol/data/"

# Get folder list for subject
folder_subject=$1
source ${folder_subject}folder_list.sh

# Go to output path
cd ${path_output}

# Create output folder
mkdir ${folder_subject}

# Go to output folder
cd ${folder_subject}

# Update path using folder_subject
path_data=${path_data}${folder_subject}

# Loop through folders
for i in ${!list_files[@]}
do
	file=${list_files[$i]}
	folder_standard=${list_standard_folders[$i]}

	# Create contrast folder and go to it
	mkdir ${folder_standard}
    cd ${folder_standard}

    # Copy NIfTI files from data folder and rename it
    cp ${path_data}nii/${file}.nii.gz ./${folder_standard}.nii.gz

    # If diffusion, move bvals/bvecs
	if [ -f ${path_data}nii/${file}.bval ]; then
    	cp ${path_data}nii/${file}.bval ./bvals.txt
    	cp ${path_data}nii/${file}.bvec ./bvecs.txt
    fi

    # If mt, average across echoes and move to single mt folder
    if [[ ${folder_standard} == *mt* ]]; then
    	# Average across echoes
    	sct_maths -i ${folder_standard}.nii.gz -mean t -o ./${folder_standard}.nii.gz
    	# Move to single mt folder
    	mkdir ../mt
    	mv ${folder_standard}.nii.gz ../mt/${folder_standard}.nii.gz
    	#rm -rf ${folder_standard}---Fix this!!!
    fi

    # If GRE-ME, average across echoes
    if [[ ${folder_standard} == *gre-me* ]]; then
    	# Average across echoes
    	sct_maths -i ${folder_standard}.nii.gz -mean t -o ./${folder_standard}.nii.gz
    fi
    # go to parent folder
    cd ..
done