#!/usr/bin/env python
#
# If manual correction files are all located in a flat directory, as was the case at the beginning of the project, this
# script copies each file under the proper derivatives/ directory.
# The directory is found by parsing the file name, and looking for the 'subject' field and the 'contrast' field (to
# decide if a data goes under anat/ or dwi/).
#
# Assumptions:
# - all data are .nii.gz
# - subject name is first prefix separated by "_". Example: sub-tokyo750w_dwi_crop_moco.nii.gz -> sub-tokyo750w
# - output folder is derivatives/
#
# How to run:
# Go to the directory that includes all the manual corrections (they should all be present in the ./ folder) and run:
#   python <PATH_TO_SCRIPT>/populate_derivatives.py <PATH_TO_BIDS_DATASET>
#
# Example:
#   python ~/code/spine-generic/spine-generic/spinegeneric/populate_derivatives.py ~/code/spine-generic/data-single-subject

# Authors: Julien Cohen-Adad


import sys
import os
import glob
import shutil


folder_derivatives = 'derivatives'
path_dataset = sys.argv[1]

files = glob.glob('*.nii.gz')

for file in files:
    # get subject
    subject = file.split('_')[0]
    path_output = os.path.join(path_dataset, folder_derivatives, subject)
    # find subfolder
    contrast = file.split('_')[1]
    if contrast in ['dwi']:
        folder_contrast = 'dwi'
    else:
        folder_contrast = 'anat'
    path_output = os.path.join(path_output, folder_contrast)
    os.makedirs(path_output, exist_ok=True)
    # copy
    file_out = os.path.join(path_output, file)
    print("{} -> {}".format(file, path_output+os.path.sep))
    shutil.copy(file, path_output)
