#!/usr/bin/env python
#
# Script to check if dataset is named correctly for BIDS
#
# Usage:
#   python dataset_validator.py -r PATH_TO_INDIVIDUAL_BIDS_DATASET
#
# Authors: Alexandru Foias, Julien Cohen-Adad

from bids_validator import BIDSValidator
import os, argparse

def get_parameters():
    parser = argparse.ArgumentParser(description='Check if dataset is named correctly for BIDS ')
    parser.add_argument('-d', '--path-data',
                        help='Path to input BIDS dataset directory.',
                        required=True)
    args = parser.parse_args()
    return args


def check_bids_dataset(path_data):
    """
    Check if dataset is named correctly for BIDS.
    :param path_data: Path to input BIDS dataset directory
    :return:
    """
    validator = BIDSValidator()
    for subdir in os.listdir(path_data):
        path_sub_dir = os.path.join(path_data,subdir)
        for r,d,f in os.walk(path_sub_dir):
            if f != []:
                rel_root_path = '/'.join(r.split('/')[(len(r.split('/'))-2):len(r.split('/'))])
                for datafile in f:
                    path_datafile = ('/' + rel_root_path + '/' +  datafile)
                    if (validator.is_bids(path_datafile)) == False and datafile != '.DS_Store':
                        print 'Warning : ' + path_datafile + ' is named incorrectly.'

if __name__ == "__main__":
    args = get_parameters()
    check_bids_dataset(args.path_data)