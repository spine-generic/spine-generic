#!/usr/bin/env python
#
# Script to perform manual correction of segmentations and vertebral labeling.
#
# For usage, type: python manual_correction.py -h
#
# Authors: Jan Valosek, Julien Cohen-Adad

import os
import sys
import shutil
import re

import argparse
import yaml

class ManualCorrection():

    def __init__(self):
        self.folder_derivatives = 'derivatives'

    def main(self):

        # get parser args
        parser = self.get_parser()
        self.arguments = parser.parse_args()

        # check if input yml file exists
        if os.path.isfile(self.arguments.i):
            fname_yml = self.arguments.i
        else:
            sys.exit("ERROR: Input yml file {} does not exist or path is wrong.".format(self.arguments.i))

        # fetch input yml file as dict
        with open(fname_yml, 'r') as stream:
            try:
                dict_yml = yaml.safe_load(stream)
            except yaml.YAMLError as exc:
                print(exc)

        # path to BIDS folder (optional arg, otherwise ./)
        if self.arguments.ifolder is not None:
            if os.path.isdir(self.arguments.ifolder):
                path_bids = self.arguments.ifolder
            else:
                sys.exit("ERROR: BIDS folder \'{}\' does not exist or path is wrong.".format(self.arguments.ifolder))

        # check if working directory path_bids (./ or passed by -ifolder flag) contains subjects' data
        if not any(fname.startswith('sub-') for fname in os.listdir(path_bids)):
            sys.exit("ERROR: Working directory \'{}\' does not contain data of any subject. Run this script in "
                     "results/data folder or specify this folder by -ifolder flag.".format(path_bids))

        self.segmentation_correction(dict_yml, path_bids)
        self.labels_correction(dict_yml, path_bids)

    def segmentation_correction(self, dict_yml, path_bids):
        """
        Manual spinal cord and gray matter segmentation correction
        Function copy SC or GM segmentation into derivatives/ folder and open FSLeyes for manual correction
        :param dict_yml - dictionary with input segmentation files to correct
        :param path_bids - path to input folder with BIDS dataset (default = ./)
        """
        # Loop across segmentation files
        for file in dict_yml["FILES_SEG"]:

            # extract subject using first delimiter '_'
            subject = file.split('_', 1)[0]

            # check if file is under dwi/ or anat/ folder and get fname_data and create path_output
            if 'dwi' in file:
                fname_data = os.path.join(path_bids, subject, 'dwi', file)
                path_output = os.path.join(path_bids, self.folder_derivatives, subject, 'dwi')
            else:
                fname_data = os.path.join(path_bids, subject, 'anat', file)
                path_output = os.path.join(path_bids, self.folder_derivatives, subject, 'anat')

            # distinguish between gray matter and spinal cord segmentation
            if 'T2star' in fname_data:
                # get fname_seg
                fname_seg = os.path.join(path_bids, re.sub(r'.nii.gz','_gmseg.nii.gz',fname_data))
                # create fname_seg_dest in derivatives folder
                fname_seg_dest = os.path.join(path_bids, self.folder_derivatives,
                                              re.sub(r'.nii.gz','_gmseg-manual.nii.gz',fname_data))
            else:
                # get fname_seg
                fname_seg = os.path.join(path_bids, re.sub(r'.nii.gz', '_seg.nii.gz', fname_data))
                # create fname_seg_dest in derivatives folder
                fname_seg_dest = os.path.join(path_bids, self.folder_derivatives,
                                              re.sub(r'.nii.gz', '_seg-manual.nii.gz', fname_data))

            # check if segmentation file exist, i.e., passed filename is correct
            if os.path.isfile(fname_seg):
                # create bids folder if not exist
                os.makedirs(path_output, exist_ok=True)
                # copy *_seg.nii.gz file -> *_seg-manual.nii.gz
                shutil.copy(fname_seg, fname_seg_dest)
                # launch FSLeyes
                print('In FSLeyes, click on \'Edit mode\', correct the segmentation, then save it with the same '
                      'name (overwrite).')
                arglist = '-yh ' + fname_data + ' ' + fname_seg_dest + ' -cm red'
                os.system('fsleyes ' + arglist)
            else:
                print('File {} does not exist. Please verity if you entered filename correctly.'.format(file))

    def labels_correction(self, dict_yml, path_bids):
        """
        Manual vertebral labeling correction
        Function copy vertebral labeling file into derivatives/ folder and launch sct_label_utils GUI for manual
        correction
        :param dict_yml - dictionary with input segmentation files to correct
        :param path_bids - path to input folder with BIDS dataset (default = ./)
        """
        # Loop across vertebral labeling files
        for subject in dict_yml["FILES_LABEL"]:

            # get fname_label (original T1w image where labeling was performed on)
            fname_label = os.path.join(path_bids, subject, 'anat', (subject + '_T1w_RPI_r.nii.gz'))
            # create destination fname_label_dest in derivatives/ folder
            fname_label_dest = os.path.join(path_bids, self.folder_derivatives, subject, 'anat',
                                            (subject + '_T1w_RPI_r_labels-manual.nii.gz'))

            # check if vertebral labeling file exist, i.e., passed filename is correct
            if os.path.isfile(fname_label):
                # launch sct_label_utils GUI for manual labeling
                print('In sct_label_utils GUI, select C3 and C5, then click \'Save and Quit\'.')
                arglist = '-i ' + fname_label + ' -create-viewer 3,5 -o ' + fname_label_dest
                os.system('sct_label_utils ' + arglist)
            else:
                print('File {} does not exist. Please verity if you entered subject ID correctly.'.format(fname_label))

    def get_parser(self):
        """
        parser function
        """
        parser = argparse.ArgumentParser(
            description='Manual correction of spinal cord and gray matter segmentation and vertebral labeling. '
                        'Manually corrected files are saved under derivatives/ folder (BIDS standard).',
            add_help=False,
            prog=os.path.basename(__file__).strip('.py')
        )
        mandatory = parser.add_argument_group('\nMANDATORY ARGUMENTS')
        mandatory.add_argument(
            '-i',
            required=True,
            metavar='<in-yml file>',
            help="File, in yml format, listing segmentation and vertebral labeling that require manual correction. "
                 "Segmentation files are listed under the 'FILES_SEG' key while vertebral labels are listed under the "
                 "FILES_LABEL key. Below is an example of a yml file:\n"
                 ""
                 "FILES_SEG:\n"
                 "- sub-amu01_T1w_RPI_r.nii.gz"
                 "- sub-amu01_T1w_RP_r.nii"
                 "- sub-amu01_T2w_RPI_r.nii.gz"
                 "- sub-cardiff02_dwi_crop_moco_dwi_mean.nii.gz"
                 "- sub-amu01_T2star_rms.nii.gz"
                 "FILES_LABEL:"
                 "- sub-amu01"
                 "- sub-amu02"
        )
        optional = parser.add_argument_group("\nOPTIONAL ARGUMENTS")
        optional.add_argument(
            '-ifolder',
            metavar='<in-folder>',
            help='Path to input folder with BIDS dataset. Example = ~/spine-generic/results/data',
            default='./'
        )

        optional.add_argument(
            "-h",
            "--help",
            action="help",
            help="Show this help message and exit."
        )
        return parser


if __name__ == "__main__":
    manual_correction = ManualCorrection()
    manual_correction.main()
