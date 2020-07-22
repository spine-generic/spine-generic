#!/usr/bin/env python
#
# Script to perform manual correction of segmentations and vertebral labeling.
#
# For usage, type: python manual_correction.py -h
#
# Authors: Jan Valosek, Julien Cohen-Adad


import argparse
import coloredlogs
import json
import os
import sys
import shutil
from textwrap import dedent
import time
import yaml

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
        description='Manual correction of spinal cord and gray matter segmentation and vertebral labeling. '
                    'Manually corrected files are saved under derivatives/ folder (BIDS standard).',
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
            - sub-amu02_T1w_RPI_r.nii.gz
            NAME:
            - John Doe\n
            """)
    )
    parser.add_argument(
        '-path-in',
        metavar=sg.utils.Metavar.folder,
        help='Path to the processed data. Example: ~/spine-generic/results/data',
        default='./'
    )
    parser.add_argument(
        '-path-out',
        metavar=sg.utils.Metavar.folder,
        help="Path to the BIDS dataset where the corrected labels will be generated. Note: if the derivatives/ folder "
             "does not already exist, it will be created."
             "Example: ~/data-spine-generic",
        default='./'
    )
    parser.add_argument(
        '-v', '--verbose',
        help="Full verbose (for debugging)",
        action='store_true'
    )

    return parser


def correct_segmentation(file, path_data, path_out, type_seg='spinalcord', name_rater='Anonymous'):
    """
    Open fsleyes with input file and copy saved file in path_out.
    :param file:
    :param path_data:
    :param path_out:
    :param type_seg: {'spinalcord', 'graymatter'}
    :param name_rater: str: Name of the expert rater
    :return:
    """
    def _suffix_seg(type_seg):
        return '_seg' if type_seg == 'spinalcord' else '_gmseg'

    # build file names
    fname = os.path.join(path_data, sg.bids.get_subject(file), sg.bids.get_contrast(file), file)
    fname_seg = sg.utils.add_suffix(fname, _suffix_seg(type_seg))
    fname_seg_out = os.path.join(
        path_out, sg.bids.get_subject(file), sg.bids.get_contrast(file),
        sg.utils.add_suffix(file, '{}-manual'.format(_suffix_seg(type_seg))))
    # copy to output path
    os.makedirs(os.path.join(path_out, sg.bids.get_subject(file), sg.bids.get_contrast(file)), exist_ok=True)
    shutil.copy(fname_seg, fname_seg_out)
    # launch FSLeyes
    print("In FSLeyes, click on 'Edit mode', correct the segmentation, then save it with the same name (overwrite).")
    os.system('fsleyes -yh ' + fname + ' ' + fname_seg_out + ' -cm red')
    create_json(fname_seg_out, name_rater)


def correct_vertebral_labeling(file, path_data, path_out, name_rater='Anonymous'):
    """
    Open SCT label utils to manually label vertebral levels.
    :param file:
    :param path_data:
    :param path_out:
    :param name_rater: str: Name of the expert rater
    :return:
    """
    # build file names
    fname = os.path.join(path_data, sg.bids.get_subject(file), sg.bids.get_contrast(file), file)
    fname_label = os.path.join(
        path_out, sg.bids.get_subject(file), sg.bids.get_contrast(file), sg.utils.add_suffix(file, '_labels-manual'))
    # create output path
    os.makedirs(os.path.join(path_out, sg.bids.get_subject(file), sg.bids.get_contrast(file)), exist_ok=True)
    # launch SCT label utils
    message = "Click inside the spinal cord, at C3 and C5 mid-vertebral levels, then click 'Save and Quit'."
    os.system('sct_label_utils -i {} -create-viewer 3,5 -o {} -msg {}'.format(fname, fname_label, message))
    create_json(fname_label, name_rater)


def create_json(fname_nifti, name_rater):
    """
    Create json sidecar with meta information
    :param fname_nifti: str: File name of the nifti image to associate with the json sidecar
    :param name_rater: str: Name of the expert rater
    :return:
    """
    metadata = {'Author': name_rater, 'Date': time.strftime('%Y-%m-%d %H:%M:%S')}
    fname_json = fname_nifti.rstrip('.nii').rstrip('.nii.gz') + '.json'
    with open(fname_json, 'w') as outfile:
        json.dump(metadata, outfile, indent=4)


def main():
    # Parse the command line arguments
    parser = get_parser()
    args = parser.parse_args()

    # Logging level
    if args.verbose:
        coloredlogs.install(fmt='%(message)s', level='DEBUG')
    else:
        coloredlogs.install(fmt='%(message)s', level='INFO')

    if not sg.utils.check_software_installed():
        sys.exit("Some required software are not installed. Exit program.")

    # check if input yml file exists
    if os.path.isfile(args.config):
        fname_yml = args.config
    else:
        sys.exit("ERROR: Input yml file {} does not exist or path is wrong.".format(args.config))

    # fetch input yml file as dict
    with open(fname_yml, 'r') as stream:
        try:
            dict_yml = yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            print(exc)

    # check for missing files before starting the whole process
    sg.utils.check_files_exist(dict_yml, args.path_in)

    # check that output folder exists and has write permission
    path_out_deriv = sg.utils.check_output_folder(args.path_out, FOLDER_DERIVATIVES)

    # Get name of expert rater
    name_rater = input("Enter your name (Firstname Lastname). It will be used to generate a json sidecar with each "
                       "corrected file: ")

    # Perform manual corrections
    for task, files in dict_yml.items():
        for file in files:
            if task == 'FILES_SEG':
                correct_segmentation(file, args.path_in, path_out_deriv, name_rater=name_rater)
            elif task == 'FILES_GMSEG':
                correct_segmentation(file, args.path_in, path_out_deriv, type_seg='graymatter', name_rater=name_rater)
            elif task == 'FILES_LABEL':
                correct_vertebral_labeling(file, args.path_in, path_out_deriv, name_rater=name_rater)
            else:
                sys.exit('Task not recognized from yml file: {}'.format(task))


if __name__ == '__main__':
    main()
