#!/usr/bin/env python
#
# Script to package data for manual correction.
#
# For usage, type: python package_for_correction.py -h
#
# Author: Julien Cohen-Adad


import os
import sys
import shutil
from textwrap import dedent
import argparse
import yaml
import coloredlogs

import spinegeneric as sg
import spinegeneric.utils
import spinegeneric.bids


# Folder where to output manual labels, at the root of a BIDS dataset.
# TODO: make it an input argument (with default value)
FOLDER_DERIVATIVES = os.path.join('derivatives', 'labels')


def get_parser():
    """
    parser function
    """
    parser = argparse.ArgumentParser(
        description='Package data for manual correction. In case processing is ran on a remote cluster, it it '
                    'convenient to generate a package of the files that need correction to be able to only copy these '
                    'files locally, instead of copying the ~20GB of total processed files.',
        formatter_class=sg.utils.SmartFormatter,
        prog=os.path.basename(__file__).strip('.py')
    )
    parser.add_argument(
        '-config',
        metavar=sg.utils.Metavar.file,
        required=True,
        help=
        "R|Config yaml file listing images that require manual corrections for segmentation and vertebral "
        "labeling. 'FILES_SEG' lists images associated with spinal cord segmentation, 'FILES_GMSEG' lists images "
        "associated with gray matter segmentation and 'FILES_LABEL' lists images associated with vertebral labeling. "
        "You can validate your yaml file at this website: http://www.yamllint.com/. Below is an example yaml file:\n"
        + dedent(
            """
            FILES_SEG:
            - sub-amu01_T1w_RPI_r.nii.gz
            - sub-amu01_T2w_RPI_r.nii.gz
            - sub-cardiff02_dwi_moco_dwi_mean.nii.gz
            FILES_GMSEG:
            - sub-amu01_T2star_rms.nii.gz
            FILES_LABEL:
            - sub-amu01_T1w_RPI_r.nii.gz
            - sub-amu02_T1w_RPI_r.nii.gz\n
            """)
    )
    parser.add_argument(
        '-path-in',
        metavar=sg.utils.Metavar.folder,
        help='Path to the processed data. Example: ~/spine-generic/results/data',
        default='./'
    )
    parser.add_argument(
        '-o',
        metavar=sg.utils.Metavar.folder,
        help="Zip file that contains the packaged data. Default: data_to_correct.zip",
        default='data_to_correct.zip'
    )
    parser.add_argument(
        '-v', '--verbose',
        help="Full verbose (for debugging)",
        action='store_true'
    )

    return parser


def main():
    # Parse the command line arguments
    parser = get_parser()
    args = parser.parse_args()

    # Logging level
    if args.verbose:
        coloredlogs.install(fmt='%(message)s', level='DEBUG')
    else:
        coloredlogs.install(fmt='%(message)s', level='INFO')

    # Check if input yml file exists
    if os.path.isfile(args.config):
        fname_yml = args.config
    else:
        sys.exit("ERROR: Input yml file {} does not exist or path is wrong.".format(args.config))

    # Fetch input yml file as dict
    with open(fname_yml, 'r') as stream:
        try:
            dict_yml = yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            print(exc)

    # Check for missing files before starting the whole process
    sg.utils.check_files_exist(dict_yml, args.path_in)

    # Create temp folder



    # Perform manual corrections
    for task, files in dict_yml.items():
        for file in files:
            if task == 'FILES_SEG':
                correct_segmentation(file, args.path_in, path_out_deriv)
            elif task == 'FILES_GMSEG':
                correct_segmentation(file, args.path_in, path_out_deriv, type_seg='graymatter')
            elif task == 'FILES_LABEL':
                correct_vertebral_labeling(file, args.path_in, path_out_deriv)
            else:
                sys.exit('Task not recognized from yml file: {}'.format(task))


if __name__ == '__main__':
    main()
