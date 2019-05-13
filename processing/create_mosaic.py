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

from spinalcordtoolbox.image import Image
from spinalcordtoolbox.centerline.optic import detect_centerline
import sct_utils as sct


def main():
    # create temporary folder with intermediate results
    tmp_folder = sct.TempFolder(verbose=1)
    tmp_folder_path = tmp_folder.get_path()
    print(tmp_folder_path)
    # copy files to the tmp folder
    path_tmp_dct = {}
    for i, f in enumerate(path_im_lst):
        new_filename = str(i).zfill(2)
        sct.copy(f, os.path.join(tmp_folder_path, new_filename+'.nii.gz'))
        path_tmp_dct[new_filename] = [new_filename+'.nii.gz']
    tmp_folder.chdir()

    # detect centerline
    for f in path_tmp_dct.keys():
        ctr_fname = f+'_ctr.nii.gz'
        ctr = detect_centerline(Image(path_tmp_dct[f][0]), contrast)
        ctr.save(ctr_fname)
        path_tmp_dct[f].append(ctr_fname)
    print(path_tmp_dct)


def get_parameters():
    parser = argparse.ArgumentParser(
        description='Create a mosaic of images from different 3D data (param: -p), \
                    with axial or sagittal view (param: -ax_sag).')
    parser.add_argument('-p', '--path_lst',
                        required=True,
                        help='List of paths to 3D images, separeted by comma.')
    parser.add_argument('-c', '--contrast',
                        required=True,
                        choices=['t2', 't2s', 't1'],
                        help='Contrast-like of the input images.')
    parser.add_argument('-ax_sag', '--ax_sag',
                        required=False,
                        default='ax',
                        choices=['ax','sag'],
                        help='Define the view of the samples:\
                        ax --> axial view ; \
                        sag --> sagittal view')
    parser.add_argument('-n', '--n_slice',
                        required=False,
                        default=1,
                        help='Number of displayed samples. Note that if ax_sag=sag, then n is forced to 1.')
    args = parser.parse_args()
    return args


if __name__ == "__main__":
    args = get_parameters()
    path_im_lst = args.path_lst.split(',')
    contrast = args.contrast
    ax_sag = args.ax_sag
    n_slice = args.n_slice
    main()
