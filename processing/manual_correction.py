#!/usr/bin/env python
#
# Script for manual correction of spinal cord and gray matter segmentation and vertebral labeling
#
# Run this script in results/data folder
#
# USAGE:
# Create a files.yml file that list the files to manually correct, for the spinal cord segmentation (FILES_SEG_SC),
# gray matter segmentation (FILES_SEG_GM) and vertebral labeling (FILES_LABEL), as per the example below:
#
#FILES_SEG_SC:
#- sub-amu01_T1w_RPI_r.nii.gz
#- sub-amu01_T1w_RP_r.nii
#- sub-amu01_T2w_RPI_r.nii.gz
#- sub-cardiff02_dwi_crop_moco_dwi_mean.nii.gz
#FILES_SEG_GM:
#- sub-amu01_T2star_rms.nii.gz
#FILES_LABEL:
#- sub-amu01
#- sub-amu02
#
# THEN RUN:
#       PATH_TO_SPINEGENERIC/processing/manual_correction.py -i files.yml -o ~/seg_manual
#
# Authors: Julien Cohen-Adad, Jan Valosek

import os
import sys
import re

import argparse
import yaml

class ManualCorrection():

    def __init__(self):
        pass

    def main(self):

        # Get parser args
        parser = self.get_parser()
        self.arguments = parser.parse_args()

        # Check if input yml file exists
        if os.path.isfile(self.arguments.i):
            fname_yml = self.arguments.i
        else:
            sys.exit("ERROR: Input yml file {} does not exist or path is wrong.".format(self.arguments.i))

        # Read input yml file as dict
        with open(fname_yml, 'r') as stream:
            try:
                dict_yml = yaml.safe_load(stream)
            except yaml.YAMLError as exc:
                print(exc)

        path_segmanual = self.arguments.o

        self.spinal_cord_correction(dict_yml, path_segmanual)
        self.gray_matter_correction(dict_yml, path_segmanual)
        self.labels_correction(dict_yml, path_segmanual)

    def spinal_cord_correction(self, dict_yml, path_segmanual):
        """
        Function for manual correction of spinal cord segmentation
        """
        # Loop across spinal cord segmentation files
        for file_sc in dict_yml["FILES_SEG_SC"]:

            # extract subject using first delimiter '_'
            subject = file_sc.split("_", 1)[0]

            # check if file is under dwi/ or anat/ folder and get fname_data
            if "dwi" in file_sc:
                fname_data = os.path.join(subject,"dwi",file_sc)
            else:
                fname_data = os.path.join(subject,"anat",file_sc)

            # get fname_seg and fname_seg_dest
            fname_seg = re.sub(r'.nii.gz','_seg.nii.gz',fname_data)
            fname_seg_dest = os.path.join(path_segmanual,re.sub(r'.nii.gz','_seg-manual.nii.gz',fname_data))

            print(fname_seg, fname_seg_dest)

    def gray_matter_correction(self, dict_yml, path_segmanual):
        """
        Function for manual correction of gray matter segmentation
        """
        # Loop across gray matter segmentation files
        for file_gm in dict_yml["FILES_SEG_GM"]:
            print(file_gm)

    def labels_correction(self, dict_yml, path_segmanual):
        """
        Function for manual correction of vertebral labeling
        """
        # Loop across gray matter segmentation files
        for subject in dict_yml["FILES_LABEL"]:
            print(subject)

    def get_parser(self):
        """
        parser function
        """
        parser = argparse.ArgumentParser(
            description="Manual correction of spinal cord and gray matter segmentation and vertebral labeling.",
            add_help=False,
            prog=os.path.basename(__file__).strip(".py")
        )

        mandatory = parser.add_argument_group("\nMANDATORY ARGUMENTS")
        mandatory.add_argument(
            "-i",
            required=True,
            metavar="<input yml file>",
            help="Filename of yml file containing segmentation and vertebral labeling for manual correction."
        )

        optional = parser.add_argument_group("\nOPTIONAL ARGUMENTS")
        optional.add_argument(
            "-o",
            metavar="<output folder>",
            help="Path to output folder where manual segmentation and labels will be saved. Default = ../../seg_manual",
            default="../../seg_manual"
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