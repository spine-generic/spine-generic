#!/usr/bin/env python
#
# Generate figure for generic spine data.
#
# USAGE:
# The script should be launched using SCT's python:
#   ${SCT_DIR}/python/bin/python ${PATH_SPINEGENERIC}/generate_figure.py -i <image1> <image2>...
#
# OUTPUT:
# Figure
#
# Authors: Stephanie Alley
# License: https://github.com/neuropoly/gm_challenge/blob/master/LICENSE

import os, sys
import argparse
import numpy as np
import nibabel as nib
import matplotlib.pyplot as plt

def get_parameters():
    parser = argparse.ArgumentParser(description='Create a figure composed of axial slices of each of the files provided.')
    parser.add_argument("-i", "--input",
                        help="List the files to include in the figure, separated by a space.",
                        nargs='+',
                        required=True)
    args = parser.parse_args()
    return args

def main():
	list_of_files = args.input

	# Initiate the figure
	fig = plt.figure(figsize=(6,2))
	# Define position of first slice in the figure
	p = 1
	# For each file provided, add z slices to the figure
	for file in list_of_files:
		# Load NIfTI file
		im = nib.load(file)
		# Get image data as an array
		im_array = im.get_data().T
		# Get the number of z slices
		slice_num = im_array.shape[0]
		# Add each slice to the figure
		for slice in range(slice_num):
			# Add slice as a subplot
			fig.add_subplot(len(list_of_files),slice_num,p)
			plt.imshow(im_array[slice], cmap=plt.cm.gray, origin='lower')
			plt.axis('off')
			fig.subplots_adjust(hspace=0, wspace=0)
			plt.savefig('im.png')
			p += 1

	plt.show()

if __name__ == "__main__":
    args = get_parameters()
    main()