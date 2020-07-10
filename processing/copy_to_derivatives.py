#!/usr/bin/env python
#
# Copy files from <path-in>/sub-xxx/anat/ to <path-out>/derivatives/labels/sub-xxx/anat/.
#
# For more details, see the help.

# TODO: add possibility to add suffix to output file

import os
import shutil
import argparse

import utils

FOLDER_DERIVATIVES = os.path.join('derivatives', 'labels')


def get_parser():
    parser = argparse.ArgumentParser(
        description="Copy files from <path-in>/sub-xxx/anat/ to <path-out>/derivatives/labels/sub-xxx/anat/. All "
                    "copied files should share a common suffix as in sub-xxx_SUFFIX.nii.gz (e.g., "
                    "T1w_RPI_r_seg_labeled). If the derivatives folder does not exist, it will be created",
        formatter_class=utils.SmartFormatter,
        prog=os.path.basename(__file__).strip('.py')
        )
    parser.add_argument('-path-in', required=True, type=str,
                        help="Path to input BIDS dataset, which contains all the 'sub-' folders.")
    parser.add_argument('-path-out', required=True, type=str,
                        help="Path to output BIDS dataset, which contains all the 'sub-' folders.")
    parser.add_argument('-suffix', dest="suffix", required=True, type=str,
                        help="Suffix of the input file, as in sub-*<suffix>.nii.gz. The program will search for all "
                             "files with .nii.gz extension.")
    return parser


def copy_files_that_match_suffix(path_in, suffix, path_out, folder_derivatives, extension='.nii.gz'):
    """
    Crawl in BIDS directory, and copy files that match suffix
    :param path_in: Path to input BIDS dataset, which contains all the 'sub-' folders.
    :param suffix:
    :param path_out: Path to output BIDS dataset, which contains all the 'sub-' folders.
    :param folder_derivatives: name of derivatives folder where to put the data
    :param extension:
    :return:
    """
    from pathlib import Path
    import bids

    fnames = list(Path(path_in).rglob('*' + suffix + extension))
    for fname in fnames:
        file = fname.parts[-1]
        # build output path, create dir
        path_out = Path(path_out, folder_derivatives, bids.get_subject(file), bids.get_contrast(file))
        os.makedirs(path_out, exist_ok=True)
        # copy
        shutil.copy(fname, path_out.joinpath(file))
        # TODO: add logging
    # TODO: add counter


def main():
    parser = get_parser()
    args = parser.parse_args()
    copy_files_that_match_suffix(args.path_in, args.suffix, args.path_out, FOLDER_DERIVATIVES)


if __name__ == '__main__':
    main()
