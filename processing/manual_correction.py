#!/usr/bin/env python
#
# Script to perform manual correction of segmentations and vertebral labeling.
#
# For usage, type: python manual_correction.py -h
#
# Authors: Jan Valosek, Julien Cohen-Adad

# TODO: impose py3.6 because of this: https://github.com/neuropoly/spinalcordtoolbox/issues/2782
# TODO: check if fsleyes is installed


import os
import sys
import shutil
from textwrap import dedent
import argparse
import yaml

from utils import Metavar, SmartFormatter
from bids import get_subject, get_contrast

# Folder where to output manual labels, at the root of a BIDS dataset.
FOLDER_DERIVATIVES = os.path.join('derivatives', 'labels')


def get_parser():
    """
    parser function
    """
    parser = argparse.ArgumentParser(
        description='Manual correction of spinal cord and gray matter segmentation and vertebral labeling. '
                    'Manually corrected files are saved under derivatives/ folder (BIDS standard).',
        formatter_class=SmartFormatter,
        prog=os.path.basename(__file__).strip('.py')
    )
    parser.add_argument(
        '-config',
        metavar=Metavar.file,
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
            - sub-amu01
            - sub-amu02\n
            """)
    )
    parser.add_argument(
        '-path-in',
        metavar=Metavar.folder,
        help='Path to the processed data. Example: ~/spine-generic/results/data',
        default='./'
    )
    parser.add_argument(
        '-path-out',
        metavar=Metavar.folder,
        help="Path to the BIDS dataset where the corrected labels will be generated. Note: if the derivatives/ folder "
             "does not already exist, it will be created."
             "Example: ~/data-spine-generic"
    )

    return parser


def add_suffix(fname, suffix):
    """
    Add suffix between end of file name and extension.

    :param fname: absolute or relative file name. Example: t2.nii
    :param suffix: suffix. Example: _mean
    :return: file name with suffix. Example: t2_mean.nii

    Examples:

    - add_suffix(t2.nii, _mean) -> t2_mean.nii
    - add_suffix(t2.nii.gz, a) -> t2a.nii.gz
    """
    def _splitext(fname):
        """
        Split a fname (folder/file + ext) into a folder/file and extension.

        Note: for .nii.gz the extension is understandably .nii.gz, not .gz
        (``os.path.splitext()`` would want to do the latter, hence the special case).
        """
        dir, filename = os.path.split(fname)
        for special_ext in ['.nii.gz', '.tar.gz']:
            if filename.endswith(special_ext):
                stem, ext = filename[:-len(special_ext)], special_ext
                return os.path.join(dir, stem), ext
        # If no special case, behaves like the regular splitext
        stem, ext = os.path.splitext(filename)
        return os.path.join(dir, stem), ext

    stem, ext = _splitext(fname)
    return os.path.join(stem + suffix + ext)


def correct_segmentation(file, path_data, path_out, type_seg='spinalcord'):
    """
    Open fsleyes with input file and copy saved file in path_out.
    :param file:
    :param path_data:
    :param path_out:
    :param type_seg: {'spinalcord', 'graymatter'}
    :return:
    """
    def _suffix_seg(type_seg):
        return '_seg' if type_seg == 'spinalcord' else '_gmseg'

    # build file names
    fname = os.path.join(path_data, get_subject(file), get_contrast(file), file)
    fname_seg = add_suffix(fname, _suffix_seg(type_seg))
    fname_seg_out = os.path.join(
        path_out, get_subject(file), get_contrast(file), add_suffix(file, _suffix_seg(type_seg)))
    # copy to output path
    os.makedirs(os.path.join(path_out, get_subject(file), get_contrast(file)), exist_ok=True)
    shutil.copy(fname_seg, fname_seg_out)
    # launch FSLeyes
    print("In FSLeyes, click on 'Edit mode', correct the segmentation, then save it with the same name (overwrite).")
    os.system('fsleyes -yh ' + fname + ' ' + fname_seg_out + ' -cm red')


def correct_vertebral_labeling(file, path_data, path_out):
    """
    Open SCT label utils to manually label vertebral levels.
    :param file:
    :param path_data:
    :param path_out:
    :return:
    """
    def _suffix_seg(type_seg):
        return '_seg' if type_seg == 'spinalcord' else '_gmseg'

    # build file names
    fname = os.path.join(path_data, get_subject(file), get_contrast(file), file)
    fname_label = os.path.join(
        path_out, get_subject(file), get_contrast(file), add_suffix(file, '_labels-manual'))
    # create output path
    os.makedirs(os.path.join(path_out, get_subject(file), get_contrast(file)), exist_ok=True)
    # launch SCT label utils
    message = "Click inside the spinal cord, at C3 and C5 mid-vertebral levels, then click 'Save and Quit'."
    os.system('sct_label_utils -i {} -create-viewer 3,5 -o {} -msg {}'.format(fname, fname_label, message))


def check_files_exist(dict_files, path_data):
    """
    Check if all files listed in the input dictionary exist
    :param dict_files:
    :param path_data: folder where BIDS dataset is located
    :return: missing_files
    """
    missing_files = []
    for task, files in dict_files.items():
        for file in files:
            fname = os.path.join(path_data, get_subject(file), get_contrast(file), file)
            if not os.path.exists(fname):
                missing_files.append(fname)
    return missing_files


def check_output_folder(path_bids):
    """
    Make sure path exists, has writing permissions, and create derivatives folder if it does not exist.
    :param path_bids:
    :return: path_bids_derivatives
    """
    if path_bids is None:
        get_parser().error("-path-out should be provided.")
    if not os.path.exists(path_bids):
        sys.exit("Output path does not exist: {}".format(path_bids))
    path_bids_derivatives = os.path.join(path_bids, FOLDER_DERIVATIVES)
    os.makedirs(path_bids_derivatives, exist_ok=True)
    return path_bids_derivatives


def main(argv):
    """
    Main function
    :param argv:
    :return:
    """
    # Parse the command line arguments
    parser = get_parser()
    args = parser.parse_args(argv if argv else ['--help'])

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
    missing_files = check_files_exist(dict_yml, args.path_in)
    # TODO: move the exception below in check_files_exist
    if missing_files:
        sys.exit("The following files listed in the yml file are missing: \n{}. \nPlease check that the files listed "
                 "in the yml file and the input path are correct.".format(missing_files))

    # check that output folder exists and has write permission
    path_out_deriv = check_output_folder(args.path_out)

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


if __name__ == "__main__":
    main(sys.argv[1:])
