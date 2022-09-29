#!/usr/bin/env python
#
# XX
#
# USAGE:
#   ${SCT_DIR}/python/envs/venv_sct/bin/python create_mosaic.py
#
# EXAMPLE:
#   ${SCT_DIR}/python/envs/venv_sct/bin/python create_mosaic.py -i *T1w_RPI_r_flatten.nii.gz -ifolder /Volumes/projects/spine_generic/spineGeneric_20191104/results/data -s _seg.nii.gz -p sag -col 18 -row 12 -o fig_mosaic_t1.png
#
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

sys.path.append(os.environ["SCT_DIR"])
from spinalcordtoolbox.utils import __sct_dir__

sys.path.append(os.path.join(__sct_dir__, "scripts"))
from spinalcordtoolbox.image import Image
import spinalcordtoolbox.reports.slice as qcslice
from spinalcordtoolbox.resampling import resample_nib

from spinegeneric.utils import add_suffix


def scale_intensity(data, out_min=0, out_max=255):
    """Scale intensity of data in a range defined by [out_min, out_max], based on the 2nd and 98th percentiles."""
    p2, p98 = np.percentile(data, (2, 98))
    return rescale_intensity(data, in_range=(p2, p98), out_range=(out_min, out_max))


def get_mosaic(images, n_col, n_row=1):
    dim_x, dim_y, dim_z = images.shape

    matrix_sz = (int(dim_x * n_row), int(dim_y * n_col))

    matrix = np.zeros(matrix_sz)
    for i in range(dim_z):
        start_col = (i % n_col) * dim_y
        end_col = start_col + dim_y

        start_row = int(np.floor(i / n_col) % n_row) * dim_x
        end_row = start_row + dim_x

        matrix[start_row:end_row, start_col:end_col] = images[:, :, i]

    return matrix


def equalized(a, winsize):
    """
    Perform histogram equalization using CLAHE.
    """
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
    args = get_parameters()
    print(args)
    im_string = args.input
    # i_folder = args.input_folder
    # seg_string = args.segmentation
    plane = args.plane
    nb_column = int(args.col)
    nb_row = int(args.row)
    winsize = int(args.winsize_CLAHE)
    o_fname = args.output
    # List input folders
    files = glob.glob(
        os.path.join(args.input_folder, "**/sub" + im_string), recursive=True
    )
    files.sort()
    # Initialize list that will store each mosaic element
    slice_lst = []
    for file in files:
        print("Processing ({}/{}): {}".format(files.index(file), len(files), file))
        if plane == "ax":
            file_seg = add_suffix(file, args.segmentation)
            # Extract the mid-slice
            img, seg = Image(file).change_orientation("RPI"), Image(
                file_seg
            ).change_orientation("RPI")
            mid_slice_idx = int(float(img.dim[2]) // 2)
            nii_mid = nib.nifti2.Nifti2Image(
                img.data[:, :, mid_slice_idx], img.hdr.get_best_affine()
            )
            nii_mid_seg = nib.nifti2.Nifti2Image(
                seg.data[:, :, mid_slice_idx], seg.hdr.get_best_affine()
            )
            img_mid = Image(
                img.data[:, :, mid_slice_idx],
                hdr=nii_mid.header,
                dim=nii_mid.header.get_data_shape(),
            )
            seg_mid = Image(
                seg.data[:, :, mid_slice_idx],
                hdr=nii_mid_seg.header,
                dim=nii_mid_seg.header.get_data_shape(),
            )
            # Instantiate spinalcordtoolbox.reports.slice.Axial class
            qcslice_cur = qcslice.Axial([img_mid, seg_mid])
            # Find center of mass of the segmentation
            center_x_lst, center_y_lst = qcslice_cur.get_center()
            # Select the mid-slice
            mid_slice = qcslice_cur.get_slice(qcslice_cur._images[0].data, 0)
            # Crop image around SC seg
            mid_slice = qcslice_cur.crop(
                mid_slice, int(center_x_lst[0]), int(center_y_lst[0]), 20, 20
            )
        elif plane == "sag":
            sag_im = Image(file).change_orientation("RSP")
            # check if data is not isotropic resolution
            if not np.isclose(sag_im.dim[5], sag_im.dim[6]):
                sag_im = resample_nib(
                    sag_im.copy(),
                    new_size=[sag_im.dim[4], sag_im.dim[5], sag_im.dim[5]],
                    new_size_type="mm",
                )
            mid_slice_idx = int(sag_im.dim[0] // 2)
            mid_slice = sag_im.data[mid_slice_idx, :, :]
            del sag_im

        # Histogram equalization using CLAHE
        slice_cur = equalized(mid_slice, winsize)
        # Scale intensities of all slices (ie of all subjects) in a common range of values
        slice_cur = scale_intensity(slice_cur)

        # Resize all slices with the shape of the first loaded slice
        if len(slice_lst):
            slice_cur = resize(slice_cur, slice_size, anti_aliasing=True)
        else:
            slice_size = slice_cur.shape

        slice_lst.append(slice_cur)

    # Create a 2d array containing the samples to display
    data = np.stack(slice_lst, axis=-1)
    nb_img = data.shape[2]
    nb_items_mosaic = nb_column * nb_row
    nb_mosaic = np.ceil(float(nb_img) / nb_items_mosaic)
    for i in range(int(nb_mosaic)):
        if nb_mosaic == 1:
            fname_out = o_fname
        else:
            fname_out = (
                os.path.splitext(o_fname)[0]
                + "_"
                + str(i).zfill(3)
                + os.path.splitext(o_fname)[1]
            )
        # create mosaic
        idx_end = (
            (i + 1) * nb_items_mosaic if (i + 1) * nb_items_mosaic <= nb_img else nb_img
        )
        data_mosaic = data[:, :, i * nb_items_mosaic : idx_end]
        mosaic = get_mosaic(data_mosaic, nb_column, nb_row)
        # save mosaic
        plt.figure()
        plt.subplot(1, 1, 1)
        plt.axis("off")
        plt.imshow(mosaic, interpolation="bilinear", cmap="gray", aspect="equal")
        plt.savefig(fname_out, dpi=300, bbox_inches="tight", pad_inches=0)
        plt.close()
        print("\nCreated: {}".format(fname_out))


def get_parameters():
    parser = argparse.ArgumentParser(
        description="Create a mosaic of images from different 3D data"
    )
    parser.add_argument(
        "-i",
        "--input",
        required=True,
        help="Unix like input data, may contain '*' wildcard Example: '*T1w.nii.gz', This is used to"
        "specify the type of image you want in the mosaic."
        "Script will search for 'sub{your_input}",
    )
    parser.add_argument(
        "-ifolder", "--input_folder", required=True, help="Folder with BIDS format."
    )
    parser.add_argument(
        "-s",
        "--segmentation",
        required=False,
        help="Segmentation suffix. Only used with '--plane ax'. Example: '_seg'.",
        default="_seg",
    )
    parser.add_argument(
        "-p",
        "--plane",
        required=False,
        default="ax",
        choices=["ax", "sag"],
        help="Define the visualisation plane of the samples:\
                        ax --> axial view; \
                        sag --> sagittal view",
    )
    parser.add_argument(
        "-col", "--col", required=True, help="Number of columns in the output image."
    )
    parser.add_argument(
        "-row",
        "--row",
        required=False,
        default=1,
        help="Number of rows in the output image.",
    )
    parser.add_argument(
        "-wsize",
        "--winsize_CLAHE",
        required=False,
        default=16,
        help="Winsize for the equalisation using CLAHE algorithm",
    )
    parser.add_argument(
        "-o", "--output", required=False, default="mosaic.png", help="Output fname."
    )
    args = parser.parse_args()
    return args


if __name__ == "__main__":
    main()
