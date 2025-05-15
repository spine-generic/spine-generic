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
# - output folder is derivatives/labels/
#
# How to run:
# Go to the directory that includes all the manual corrections (they should all be present in the ./ folder) and run:
#   sg_populate_derivatives <PATH_TO_BIDS_DATASET>

# Authors: Julien Cohen-Adad


import os
import glob
import shutil
import argparse

import spinegeneric as sg
import spinegeneric.utils


def get_parser():
    """
    parser function
    """
    parser = argparse.ArgumentParser(
        description="R|If manual correction files are all located in a flat directory, as was the case at the "
        "beginning of the project, this script copies each file under the proper derivatives/labels/ "
        'directory. The directory is found by parsing the file name, and looking for the "subject" field '
        'and the "contrast" field (to decide if a data goes under anat/ or dwi/).'
        "Assumptions:"
        "- all data are .nii.gz"
        '- subject name is first prefix separated by "_". Example: sub-tokyo750w_dwi_crop_moco.nii.gz -> sub-tokyo750w'
        "- output folder is derivatives/labels/"
        "How to run:"
        "Go to the directory that includes all the manual corrections (they should all be present in the "
        "./ folder) and run:",
        formatter_class=sg.utils.SmartFormatter,
        prog=os.path.basename(__file__).rstrip(".py"),
    )
    parser.add_argument(
        "-path-out",
        metavar=sg.utils.Metavar.folder,
        required=True,
        help="Path to the BIDS dataset where the derivatives will be copied.",
    )
    return parser


def main():

    # Parse the command line arguments
    parser = get_parser()
    args = parser.parse_args()

    folder_derivatives = os.path.join("derivatives", "labels")
    path_dataset = args.path_out

    files = glob.glob("*.nii.gz")

    for file in files:
        # get subject
        subject = file.split("_")[0]
        path_output = os.path.join(path_dataset, folder_derivatives, subject)
        # find subfolder
        contrast = file.split("_")[1]
        if contrast in ["dwi"]:
            folder_contrast = "dwi"
        else:
            folder_contrast = "anat"
        path_output = os.path.join(path_output, folder_contrast)
        os.makedirs(path_output, exist_ok=True)
        # copy
        print("{} -> {}".format(file, path_output + os.path.sep))
        shutil.copy(file, path_output)


if __name__ == "__main__":
    main()
