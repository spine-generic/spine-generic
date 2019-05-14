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
from skimage.exposure import equalize_adapthist

from spinalcordtoolbox.image import Image
import spinalcordtoolbox.reports.slice as qcslice
import sct_utils as sct


def equalized(a):
    """
    Perform histogram equalization using CLAHE.

    Note: function copied/pasted from spinalcordtoolbox.reports.qc
    """
    winsize = 16
    min_, max_ = a.min(), a.max()
    b = (np.float32(a) - min_) / (max_ - min_)
    b[b >= 1] = 1  # 1+eps numerical error may happen (#1691)

    h, w = b.shape
    h1 = (h + (winsize - 1)) // winsize * winsize
    w1 = (w + (winsize - 1)) // winsize * winsize
    if h != h1 or w != w1:
        b1 = np.zeros((h1, w1), dtype=b.dtype)
        b1[:h, :w] = b
        b = b1
    c = equalize_adapthist(b, kernel_size=(winsize, winsize))
    if h != h1 or w != w1:
        c = c[:h, :w]
    return np.array(c * (max_ - min_) + min_, dtype=a.dtype)


def main():
    for x in os.walk(i_folder):
        for file in glob.glob(os.path.join(x[0],"*"+im_suffixe)):
            file_seg = file.split('.nii.gz')[0]+'_'+seg_suffixe

            # load data
            if plane == 'ax':
                qcslice_cur = qcslice.Axial([Image(file), Image(file_seg)])
                center_x_lst, center_y_lst = qcslice_cur.get_center()  # find seg center of mass
                mid_slice_idx = int(qcslice_cur.get_dim(qcslice_cur._images[0]) // 2)  # find index of the mid slice
                mid_slice = qcslice_cur.get_slice(qcslice_cur._images[0].data, mid_slice_idx)  # get the mid slice
                # crop image around SC seg
                mid_slice = qcslice_cur.crop(mid_slice,
                                            int(center_x_lst[mid_slice_idx]), int(center_y_lst[mid_slice_idx]),
                                            40, 40)
            else:
                qcslice_cur = qcslice.Sagittal([Image(file)])
                mid_slice_idx = int(qcslice_cur.get_dim(qcslice_cur._images[0]) // 2)  # find index of the mid slice
                mid_slice = qcslice_cur.get_slice(qcslice_cur._images[0].data, mid_slice_idx)  # get the mid slice

            # histogram equalization using CLAHE
            slice_cur = equalized(mid_slice)

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
