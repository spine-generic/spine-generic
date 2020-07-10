#!/usr/bin/env python
#
# Copy files from <path-in>/sub-xxx/anat/ to <path-out>/derivatives/labels/sub-xxx/anat/.
#
# For more details, see the help.

# TODO: add possibility to add suffix to output file

import os
import argparse
import coloredlogs

import utils

FOLDER_DERIVATIVES = os.path.join('derivatives', 'labels')


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
    parser.add_argument('-v', '--verbose', action='store_true',
        help="Full verbose (for debugging)")
    return parser


def main():

    # Parse input arguments
    parser = get_parser()
    args = parser.parse_args()

    # Logging level
    if args.verbose:
        coloredlogs.install(fmt='%(message)s', level='DEBUG')
    else:
        coloredlogs.install(fmt='%(message)s', level='INFO')

    utils.copy_files_that_match_suffix(args.path_in, args.suffix, args.path_out, FOLDER_DERIVATIVES)


if __name__ == '__main__':
    main()
