#!/usr/bin/env python
#
# Copy files from <path-in>/sub-xxx/anat/ to <path-out>/derivatives/labels/sub-xxx/anat/.
#
# For more details, see the help.

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
    parser.add_argument('-path-in', required=True, type=str,
                        help="Path to input BIDS dataset, which contains all the 'sub-' folders.")
    parser.add_argument('-path-out', required=True, type=str,
                        help="Path to output BIDS dataset, which contains all the 'sub-' folders.")
    parser.add_argument('-suffix', dest="suffix", required=True, type=str,
                        help="Suffix of the input file, as in sub-*<suffix>.nii.gz. The program will search for all "
                             "files with .nii.gz extension.")
    return parser


def copy_files(path_in, path_out, suffix):
    """
    Crawl in BIDS directory, and copy files that match suffix
    :param path_in: Path to input BIDS dataset, which contains all the 'sub-' folders.
    :param path_out: Path to output BIDS dataset, which contains all the 'sub-' folders.
    :param suffix:
    :return:
    """
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
    copy_files(args.path_in, args.path_out, args.suffix)


if __name__ == '__main__':
    main()
