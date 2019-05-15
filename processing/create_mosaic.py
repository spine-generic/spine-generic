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
import nibabel as nib
import matplotlib.pyplot as plt
from skimage.exposure import equalize_adapthist

from spinalcordtoolbox.image import Image
import spinalcordtoolbox.reports.slice as qcslice
import sct_utils as sct


def add_slice(matrix, i, column, size_x, size_y, patch):
    start_col = (i % column) * size_y * 2
    end_col = start_col + size_y

    start_row = int(i / column) * size_x * 2
    end_row = start_row + size_x

    matrix[start_row:end_row, start_col:end_col] = patch
    return matrix


def get_mosaic(images, n_col, n_row=1):
    dim_x, dim_y, dim_z = images.shape

    matrix_sz = (int(dim_y * 2 * nb_row), int(dim_x * 2 * nb_column))

    centers_x, centers_y = int(dim_x // 2), int(dim_y // 2)

    matrix = np.zeros(matrix_sz)
    for i in range(dim_z):
        matrix = add_slice(matrix, i, n_col, dim_x, dim_y, images[:,:,i])

    return matrix


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
    # find all the images of insterest and store the mid slice in slice_lst
    slice_lst = []
    for x in os.walk(i_folder):
        for file in glob.glob(os.path.join(x[0], 'sub*'+im_string)):  # prefixe sub: to prevent from fetching warp files
            print('Loading: '+file)
            # load data
            if plane == 'ax':
                file_seg = file.split('.nii.gz')[0]+'_'+seg_string

                qcslice_cur = qcslice.Axial([Image(file), Image(file_seg)])
                center_x_lst, center_y_lst = qcslice_cur.get_center()  # find seg center of mass
                mid_slice_idx = int(qcslice_cur.get_dim(qcslice_cur._images[0]) // 2)  # find index of the mid slice
                mid_slice = qcslice_cur.get_slice(qcslice_cur._images[0].data, mid_slice_idx)  # get the mid slice
                # crop image around SC seg
                mid_slice = qcslice_cur.crop(mid_slice,
                                            int(center_x_lst[mid_slice_idx]), int(center_y_lst[mid_slice_idx]),
                                            30, 30)
            else:
                qcslice_cur = qcslice.Sagittal([Image(file)])
                mid_slice_idx = int(qcslice_cur.get_dim(qcslice_cur._images[0]) // 2)  # find index of the mid slice
                mid_slice = qcslice_cur.get_slice(qcslice_cur._images[0].data, mid_slice_idx)  # get the mid slice

            # histogram equalization using CLAHE
            slice_cur = equalized(mid_slice)

            slice_lst.append(slice_cur)

    # create a new Image object containing the samples to display
    affine = np.eye(4)
    print(slice_lst[0].shape)
    data = np.stack(slice_lst, axis=-1)
    nii = nib.nifti1.Nifti1Image(data, affine)
    img = Image(data, hdr=nii.header, dim=nii.header.get_data_shape())
    print(img.data.shape)
    img.save("test.nii.gz")

    # create mosaic
    mosaic = get_mosaic(img.data, nb_column, nb_row)

    # save mosaic
    plt.figure()
    plt.subplot(1, 1, 1)
    plt.axis("off")
    plt.imshow(np.fliplr(np.rot90(mosaic, k=3)), interpolation='nearest', cmap='gray', aspect='auto')
    plt.savefig(o_fname, dpi=300, bbox_inches='tight', pad_inches=0)
    plt.close()


def get_parameters():
    parser = argparse.ArgumentParser(
        description='Create a mosaic of images from different 3D data')
    parser.add_argument('-i', '--input',
                        required=True,
                        help="Unix like input data, may contain '*' wildcard Example: '*T1w.nii.gz' ")
    parser.add_argument('-ifolder', '--input_folder',
                        required=True,
                        help='Folder with BIDS format.')
    parser.add_argument('-s', '--segmentation',
                        required=False,
                        help="Unix like seg data, may contain '*' wildcard Example: '*T1w.nii.gz' ")
    parser.add_argument('-p', '--plane',
                        required=False,
                        default='ax',
                        choices=['ax', 'sag'],
                        help='Define the visualisation plane of the samples:\
                        ax --> axial view ; \
                        sag --> sagittal view')
    parser.add_argument('-col', '--col',
                        required=True,
                        help='Number of columns in the output image.')
    parser.add_argument('-row', '--row',
                        required=False,
                        default=1,
                        help='Number of rows in the output image.')
    parser.add_argument('-o', '--output',
                        required=False,
                        default='mosaic.png',
                        help='Output fname.')
    args = parser.parse_args()
    return args


if __name__ == "__main__":
    args = get_parameters()
    im_string = args.input
    i_folder = args.input_folder
    seg_string = args.segmentation
    plane = args.plane
    nb_column = int(args.col)
    nb_row = int(args.row)
    o_fname = args.output
    main()
