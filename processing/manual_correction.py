#!/usr/bin/env python
#
# Script for manual correction of spinal cord and gray matter segmentation and vertebral labeling
#
# USAGE:
#       manual_correction.py -i files.yml -o ~/seg_manual
#
# Authors: Julien Cohen-Adad, Jan Valosek

import os
import sys

import argparse

class ManualCorrection():

    def __init__(self):
        pass

    def main(self):

        # Get parser args
        parser = self.get_parser()
        self.arguments = parser.parse_args()

        # Check if input yml file exists
        if os.path.isfile(self.arguments.i):
            input_yml = self.arguments.i


    def get_parser(self):

        parser = argparse.ArgumentParser(
            description="Manual correction of spinal cord and gray matter segmentation and vertebral labeling",
            add_help=False,
            prog=os.path.basename(__file__).strip(".py")
        )

        mandatory = parser.add_argument_group("\nMANDATORY ARGUMENTS")
        mandatory.add_argument(
            "-i",
            required=True,
            metavar="<input yml file>",
            help="Filename of yml file containing segmentation and vertebral labeling for manual correction"
        )
        mandatory.add_argument(
            "-o",
            required=True,
            metavar="<output folder>",
            help="Path to output folder where manual segmentation and labels will be saved",
        )

        optional = parser.add_argument_group("\nOPTIONAL ARGUMENTS")
        optional.add_argument(
            "-h",
            help="Help",
            nargs="*"
        )
        return parser


if __name__ == "__main__":
    manual_correction = ManualCorrection()
    manual_correction.main()