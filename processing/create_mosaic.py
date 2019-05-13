#!/usr/bin/env python
#
# XX
#
# USAGE:
#   ${SCT_DIR}/python/bin/python XX
#
#   Example:
#   ${SCT_DIR}/python/bin/python create_mosaic.py -p t2_unf.nii.gz,t2_milan.nii.gz -c t2 -ax_sag 4 -n 3
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
        # Todo: add possibility to input the name of the colums (instead of 001, 002...etc.)
        new_filename = str(i).zfill(2)
        sct.copy(f, os.path.join(tmp_folder_path, new_filename+'.nii.gz'))
        path_tmp_dct[new_filename] = {'im': new_filename+'.nii.gz'}
    tmp_folder.chdir()

    # detect centerline
    for f in path_tmp_dct.keys():
        ctr_fname = f+'_ctr.nii.gz'
        ctr = detect_centerline(Image(path_tmp_dct[f]['im']), contrast)
        ctr.save(ctr_fname)
        path_tmp_dct[f]['ctr'] = ctr_fname
    print(path_tmp_dct)


def get_parameters():
    parser = argparse.ArgumentParser(
        description='Create a mosaic of images from different 3D data (param: -p), \
                    with axial or sagittal view (param: -ax_sag).')
    parser.add_argument('-i', '--input',
                        required=True,
                        help='List of paths to 3D images, separated by comma.')
    parser.add_argument('-s', '--segmentation',
                        required=False,
                        help='List of paths to the segmentations, separeted by comma (required if plane is ax)')
    parser.add_argument('-c', '--contrast',
                        required=True,
                        choices=['t2', 't2s', 't1'],
                        help='Contrast-like of the input images.')
    parser.add_argument('-p', '--plane',
                        required=False,
                        default='ax',
                        choices=['ax', 'sag'],
                        help='Define the visualisation plane of the samples:\
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
    path_im_lst = args.input.split(',')
    contrast = args.contrast
    plane = args.plane
    if plane == 'ax':
        path_seg_lst = args.segmentation.split(',')
        if len(path_im_lst) != len(path_seg_lst):
            raise Exception("Number of segmentations provided is not the same as the number of images")
        n_slice = args.n_slice
    else:
        n_slice = 1
    main()
