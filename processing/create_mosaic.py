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
import spinalcordtoolbox.reports.slice as qcslice
from spinalcordtoolbox.reports.qc.QcImage import equalized
import sct_utils as sct


def main():
    for x in os.walk(i_folder):
        for file in glob.glob(os.path.join(x[0],"*"+im_suffixe)):
            file_seg = file.split('.nii.gz')[0]+'_'+seg_suffixe
            if plane == 'ax':
                qcslice_cur = qcslice.Axial([Image(file), Image(file_seg)])
                center_x_lst, center_y_lst = qcslice_cur.get_center()
                mid_slice_idx = int(qcslice_cur.get_dim(qcslice_cur._images[0]) // 2)
                mid_slice = qcslice_cur.get_slice(qcslice_cur._images[0].data, mid_slice_idx)
                mid_slice = qcslice_cur.crop(mid_slice,
                                            int(center_x_lst[mid_slice_idx]), int(center_y_lst[mid_slice_idx]),
                                            40, 40)
           else:
                qcslice_cur = qcslice.Axial([Image(file)])
                mid_slice_idx = int(qcslice_cur.get_dim(qcslice_cur._images[0]) // 2)
                mid_slice = qcslice_cur.get_slice(qcslice_cur._images[0].data, mid_slice_idx)

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
