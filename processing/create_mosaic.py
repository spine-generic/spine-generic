#!/usr/bin/env python
#
# XX
#
# USAGE:
#   ${SCT_DIR}/python/bin/python XX
#
#   Example:
#     XX
#
# DEPENDENCIES:
#   SCT
#

import os
import glob
import argparse
import sys
import numpy as np
import matplotlib.pyplot as plt

from spinalcordtoolbox.image import Image
import sct_utils as sct


def main():

    pass


def get_parameters():
    parser = argparse.ArgumentParser(
        description='Create a mosaic of images from different 3D data')
    parser.add_argument('-i', '--input',
                        required=True,
                        help='Suffixe of the input data.')
    parser.add_argument('-ifolder', '--input_folder',
                        required=True,
                        help='Folder with BIDS format.')
    parser.add_argument('-s', '--segmentation',
                        required=False,
                        help='Suffixe of the segmentation data. Required if plane is ax.')
    parser.add_argument('-p', '--plane',
                        required=False,
                        default='ax',
                        choices=['ax', 'sag'],
                        help='Define the visualisation plane of the samples:\
                        ax --> axial view ; \
                        sag --> sagittal view')
    args = parser.parse_args()
    return args


if __name__ == "__main__":
    args = get_parameters()
    im_suffixe = args.input
    i_folder = args.input_folder
    seg_suffixe = args.segmentation
    plane = args.plane
    main()
