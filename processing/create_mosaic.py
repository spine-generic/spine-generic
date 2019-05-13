#!/usr/bin/env python
#
# XX
#
# USAGE:
#   ${SCT_DIR}/python/bin/python XX
#
#   Example:
#   ${SCT_DIR}/python/bin/python XX
#
# DEPENDENCIES:
#   SCT
#

import os
import argparse
import sys
import numpy as np
import matplotlib.pyplot as plt


def get_parameters():
    parser = argparse.ArgumentParser(
        description='Create a mosaic of images from different 3D data (param: -p), \
                    with axial or sagittal view (param: -ax_sag).')
    parser.add_argument('-p', '--path',
                        required=True,
                        help='List of paths to 3D images, separeted by comma.')
    parser.add_argument('-ax_sag', '--ax_sag',
                        required=False,
                        default='ax',
                        help='Define the view of the samples:\
                        \n\t- ax: axial view\
                        \n\t- sag: sagittal view')
    parser.add_argument('-n', '--n_slice',
                        required=False,
                        default=1,
                        help='Number of displayed samples.')  
    args = parser.parse_args()
    return args


if __name__ == "__main__":
    args = get_parameters()
    path_im_lst = args.path_lst
    ax_sag = args.ax_sag
    n_slice = args.n_slice
    main()