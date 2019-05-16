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
from skimage.exposure import equalize_adapthist, rescale_intensity
from skimage.transform import resize
from matplotlib.offsetbox import OffsetImage, AnnotationBbox

from spinalcordtoolbox.utils import __sct_dir__
sys.path.append(os.path.join(__sct_dir__, "scripts"))
from spinalcordtoolbox.image import Image
import spinalcordtoolbox.reports.slice as qcslice
import sct_utils as sct


def scale_intensity(data, out_min=0, out_max=255):
    """Scale intensity of data in a range defined by [out_min, out_max], based on the 2nd and 98th percentiles."""
    p2, p98 = np.percentile(data, (2, 98))
    return rescale_intensity(data, in_range=(p2, p98), out_range=(out_min, out_max))


def get_mosaic_size(images, n_col, n_row):
    dim_x, dim_y, dim_z = images.shape

    matrix_sz = (int(dim_x * nb_row), int(dim_y * nb_column))

    return matrix_sz


def get_image_idx(idx, n_col, n_row, dim_x, dim_y):
    start_col = (idx % n_col) * dim_y
    end_col = start_col + dim_y

    start_row = int(np.floor(idx/n_col) % n_row) * dim_x
    end_row = start_row + dim_x

    return start_row, end_row, start_col, end_col


def equalized(a):
    """
    Perform histogram equalization using CLAHE.
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


def add_img2plot(ax, img, x, y):
    imagebox = OffsetImage(img, cmap='gray')
    imagebox.image.axes = ax

    ab = AnnotationBbox(imagebox, (x,y),
                        xycoords='axes pixels',
                        frameon=False, pad=0.0, box_alignment=(0.0, 0.0))
                        #boxcoords="offset points")

    ax.add_artist(ab)
    return ax


def main():
    # find all the images of interest and store the mid slice in slice_lst
    slice_lst = []
    for x in os.walk(i_folder):
        for file in glob.glob(os.path.join(x[0], 'sub' + im_string)):  # prefixe sub: to prevent from fetching warp files
            print('\nLoading: '+file)
            # load data
            if plane == 'ax':
                file_seg = file.split('.nii.gz')[0] + seg_string

                qcslice_cur = qcslice.Axial([Image(file), Image(file_seg)])
                center_x_lst, center_y_lst = qcslice_cur.get_center()  # find seg center of mass
                mid_slice_idx = int(qcslice_cur.get_dim(qcslice_cur._images[0]) // 2)  # find index of the mid slice
                mid_slice = qcslice_cur.get_slice(qcslice_cur._images[0].data, mid_slice_idx)  # get the mid slice
                # crop image around SC seg
                mid_slice = qcslice_cur.crop(mid_slice,
                                            int(center_x_lst[mid_slice_idx]), int(center_y_lst[mid_slice_idx]),
                                            30, 30)
            else:
                sag_im = Image(file).change_orientation('RSP')
                mid_slice_idx = int(sag_im.dim[0] // 2)
                mid_slice = sag_im.data[mid_slice_idx, :, :]
                del sag_im

            # histogram equalization using CLAHE
            slice_cur = equalized(mid_slice)
            # scale intensities of all slices (ie of all subjects) in a common range of values
            slice_cur = scale_intensity(slice_cur)

            # resize all sag_slices with the shape of the first loaded slice
            if len(slice_lst) and plane == "sag":
                slice_cur = resize(slice_cur, sag_size, anti_aliasing=True)
            else:
                sag_size = slice_cur.shape

            slice_lst.append(slice_cur)

    # create a new Image object containing the samples to display
    affine = np.eye(4)
    data = np.stack(slice_lst, axis=-1)
    nii = nib.nifti1.Nifti1Image(data, affine)
    img = Image(data, hdr=nii.header, dim=nii.header.get_data_shape())

    my_dpi = 300
    nb_img = img.data.shape[2]
    nb_items_mosaic = nb_column * nb_row
    nb_mosaic = np.ceil(float(nb_img) / (nb_items_mosaic))
    for i in range(int(nb_mosaic)):
        if nb_mosaic == 1:
            fname_out = o_fname
        else:
            fname_out = os.path.splitext(o_fname)[0] + '_' + str(i).zfill(3) + os.path.splitext(o_fname)[1]
        print('\nCreating: ' + fname_out)

        # create mosaic
        idx_end = (i+1)*nb_items_mosaic if (i+1)*nb_items_mosaic <= nb_img else nb_img
        data_mosaic = img.data[:, :, i*(nb_items_mosaic) : idx_end]
        mosaic_size = get_mosaic_size(data_mosaic, nb_column, nb_row)

        # save mosaic
        plt.figure(figsize=mosaic_size)
        fig, ax = plt.subplots()
        plt.axis("off")
        for ii in range(data_mosaic.shape[2]):
            x_start, x_end, y_start, y_end = get_image_idx(ii, nb_column, nb_row, data_mosaic.shape[0], data_mosaic.shape[1])
            print(x_start, y_start)
            ax = add_img2plot(ax, data_mosaic[:, :, ii], x_start, y_start)
        # plt.imshow(mosaic, interpolation='bilinear', cmap='gray', aspect='equal')
        plt.savefig(fname_out, dpi=my_dpi, bbox_inches='tight', pad_inches=0)
        plt.close()


def get_parameters():
    parser = argparse.ArgumentParser(
        description='Create a mosaic of images from different 3D data')
    parser.add_argument('-i', '--input',
                        required=True,
                        help="Unix like input data, may contain '*' wildcard Example: '*T1w.nii.gz', This is used to"
                             "specify the type of image you want in the mosaic."
                             "Script will search for 'sub{your_input}")
    parser.add_argument('-ifolder', '--input_folder',
                        required=True,
                        help='Folder with BIDS format.')
    parser.add_argument('-s', '--segmentation',
                        required=False,
                        help="Segmentation suffix, the string appended to the filename before .nii.gz, "
                             "Example: '_seg.nii.gz', '_seg_manual.nii.gz' ",
                        default="_seg.nii.gz")
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
