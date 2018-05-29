#!/bin/bash

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
echo "$PWD"

# Create output folder
mkdir ${folder_subject}

# Go to output folder
cd ${folder_subject}
echo "$PWD"

# Update path using folder_subject
path_data=${path_data}${folder_subject}
echo "${path_data}"
# Loop through folders
for i in ${!list_folders[@]}
do
	folder=${list_folders[$i]}
	folder_standard=${list_standard_folders[$i]}

	# Create contrast folder and go to it
	mkdir ${folder_standard}
    cd ${folder_standard}

    echo "Converting: ${folder}"
	# Flag -m merges multiecho data
	dcm2niix -f ${folder_standard} -o ./ -z i -m y ${path_data}${folder}

	# If diffusion, move bvals/bvecs
	if [ -f ${path_data}{folder}.bval ]; then
    	mv ${path_data}{folder}.bval ./bvals.txt
    	mv ${path_data}{folder}.bvec ./bvecs.txt
    fi

    # If mt, average across echoes and move to single mt folder
    if [[ ${folder_standard} == *mt* ]]; then
    	# Average across echoes
    	sct_maths -i ${folder_standard}.nii.gz -mean t -o ./${folder_standard}.nii.gz
    	# Move to single mt folder
    	mkdir ../mt
    	mv ${folder_standard}.nii.gz ../mt/${folder_standard}.nii.gz
    	rm -rf ${folder_standard}
    fi

    # If GRE-ME, average across echoes
    if [[ ${folder_standard} == *gre-me* ]]; then
    	# Average across echoes
    	sct_maths -i ${folder_standard}.nii.gz -mean t -o ./${folder_standard}.nii.gz
    fi
    # go to parent folder
    cd ..
done