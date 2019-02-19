#!/usr/bin/env python
#
# Script to check if dataset is named correctly for BIDS
#
# Usage:
#   python dataset_validator.py -d PATH_TO_INDIVIDUAL_BIDS_DATASET
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

    print '\nNow checking : ' + path_data

    validator = BIDSValidator()
    flag_warning = False

    # Check if the dataset has the required files
    required_files_BIDS = ["dataset_description.json", "participants.tsv","participants.json"]
    for item in required_files_BIDS:
        if os.path.isfile(os.path.join(path_data,item)) == False:
            print 'Warning - missing: /' + item
            flag_warning = True
    # Loop within the BIDS dataset to check if is BIDS
    for subdir in os.listdir(path_data):
        path_sub_dir = os.path.join(path_data,subdir)
        # Check if the top level files are named correctly
        if os.path.isfile(path_sub_dir):
            if validator.is_bids('/' + subdir) == False and subdir != '.DS_Store':
                print 'Warning : ' + '/' + subdir + '  is not BIDS.'
                flag_warning = True
        # Check if the files associated to a subject is BIDS
        for r,d,f in os.walk(path_sub_dir):
            if f != []:
                rel_root_path = '/'.join(r.split('/')[(len(r.split('/'))-2):len(r.split('/'))])
                for datafile in f:
                    path_datafile = ('/' + rel_root_path + '/' +  datafile)
                    if (validator.is_bids(path_datafile)) == False and datafile != '.DS_Store':
                        print 'Warning : ' + path_datafile + ' is not BIDS.'
                        flag_warning = True
    
    if flag_warning == False:
        print 'No problems found :)'

if __name__ == "__main__":
    args = get_parameters()
    check_bids_dataset(args.path_data)