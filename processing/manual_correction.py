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

        print("Done")

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
            required=False,
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