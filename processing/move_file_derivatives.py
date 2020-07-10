#!/usr/bin/env python
#
# Copy files from dir/sub-xxx/anat folder to dir/derivatives/labels/sub-xxx/anat folder.
# All copied files should share a common suffix as in sub-xxx_SUFFIX.nii.gz (e.g., T1w_RPI_r_seg_labeled). 
# If the derivatives folder does not exist, this function will create it before moving the file.
# The function will print the number of moved files at the end. 

import os
import shutil
import argparse

import utils


def get_parser():
    parser = argparse.ArgumentParser(
        description="Copy files from <path-in>/sub-xxx/anat/ to <path-out>/derivatives/labels/sub-xxx/anat/. All "
                    "copied files should share a common suffix as in sub-xxx_SUFFIX.nii.gz (e.g., "
                    "T1w_RPI_r_seg_labeled). If the derivatives folder does not exist, it will be created",
        formatter_class=utils.SmartFormatter,
        prog=os.path.basename(__file__).strip('.py')
        )
    parser.add_argument("-p", "--path", dest="path", required=True, type=str,
                        help="Path to results folder")
    parser.add_argument("-s", "--suffix", dest="suffix", required=True, type=str,
                        help="Suffix of the input file as in sub-xxx_suffix.nii.gz (e.g., _T2w)")
    return parser


def move_files(path, suffix):
    os.chdir(path)  # go to results folder
    list_folder = os.listdir("./")
    derivatives = "derivatives/labels/" 
    c = 0
    for x in list_folder:
        path_tmp = x + "/anat/" + x + "_" + suffix + ".nii.gz"
        # Check if file exists. 
        if os.path.isfile(path_tmp):
            c += 1
            path_out = derivatives + path_tmp
            os.makedirs(path_out, exist_ok=True)
            shutil.copy(path_tmp, path_out)
    print("%i files moved" % (c))


def main():
    parser = get_parser()
    args = parser.parse_args()
    path_files = args.path
    chosen_suffix = args.suffix
    move_files(path_files, chosen_suffix)


if __name__=='__main__':
    main()
