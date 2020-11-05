#!/usr/bin/env python
#
# Script to check acquisition parameters.
#
# For usage, type: sg_check_data_consistency -h
#
# Authors: Alexandru Foias, Julien Cohen-Adad
import argparse
import pandas as pd
import os
from pprint import pprint
import spinegeneric as sg
import spinegeneric.utils
from pandas_schema import Column, Schema
from pandas_schema.validation import LeadingWhitespaceValidation, TrailingWhitespaceValidation, InRangeValidation, \
    InListValidation, DateFormatValidation, MatchesPatternValidation


def get_parser():
    parser = argparse.ArgumentParser(
        description="Data consistency checker feature. This feature allows the users"
                    "to check the subjects listed in participants.tsv and the actual sub-* data."
                    "In addition, it checks the presence of jsonSidecar.",
        formatter_class=sg.utils.SmartFormatter,
        prog=os.path.basename(__file__).strip('.py')
     )
    parser.add_argument('-path-in', required=True, type=str,
                        help="Path to input BIDS dataset, which contains all the 'sub-' folders.")
    return parser


def main():
    # Parse input arguments
    parser = get_parser()
    args = parser.parse_args()

    data_path = args.path_in

    path_tsv = os.path.join(data_path, 'participants.tsv')
    tsv_file = pd.read_csv(path_tsv, sep='\t')
    list_subj = [name for name in os.listdir(data_path) if
                 os.path.isdir(os.path.join(data_path, name)) and name.startswith('sub')]
    df = pd.DataFrame(tsv_file)
    list_tsv_participants = df['participant_id'].tolist()
    missing_subjects_tsv = list(set(list_subj) - set(list_tsv_participants))
    missing_subjects_folder = list(set(list_tsv_participants) - set(list_subj))

    if missing_subjects_tsv:
        # print ('Warning missing following subjects from participants.tsv : %s' %missing_subjects_tsv)
        print('\nWarning missing following subjects from participants.tsv: ')
        missing_subjects_tsv.sort()
        pprint(missing_subjects_tsv)
    if missing_subjects_folder:
        # print ('\nWarning missing data for subjects listed in participants.tsv : %s' %missing_subjects_folder)
        print('\nWarning missing data for subjects listed in participants.tsv: ')
        missing_subjects_folder.sort()
        pprint(missing_subjects_folder)

    for dirName, subdirList, fileList in os.walk(data_path):
        for file in fileList:
            if file.endswith('.nii.gz'):
                originalFilePath = os.path.join(dirName, file)
                jsonSidecarPath = os.path.join(dirName, file.split(".")[0] + '.json')
                if os.path.exists(jsonSidecarPath) == False:
                    print("Missing jsonSidecar: " + jsonSidecarPath)

    # Checking participants.tsv contents
    schema = Schema([
        Column('participant_id', [LeadingWhitespaceValidation(), TrailingWhitespaceValidation()]),
        Column('sex', [InListValidation(['M', 'F'])]),
        Column('age', [InRangeValidation(18, 60)]),
        Column('height', [MatchesPatternValidation(r"[0-9]|-")]),
        Column('weight', [MatchesPatternValidation(r"[0-9]|-")]),
        Column('date_of_scan', [DateFormatValidation('%Y-%m-%d')|MatchesPatternValidation(r"-")]),
        Column('institution_id', [LeadingWhitespaceValidation(), TrailingWhitespaceValidation()]),
        Column('institution', [LeadingWhitespaceValidation(), TrailingWhitespaceValidation()]),
        Column('manufacturer', [LeadingWhitespaceValidation(), TrailingWhitespaceValidation()]),
        Column('manufacturers_model_name', [LeadingWhitespaceValidation(), TrailingWhitespaceValidation()]),
        Column('receive_coil_name', [LeadingWhitespaceValidation(), TrailingWhitespaceValidation()]),
        Column('software_versions', [LeadingWhitespaceValidation(), TrailingWhitespaceValidation()]),
        Column('researcher', [LeadingWhitespaceValidation(), TrailingWhitespaceValidation()]),
    ])

    errors = schema.validate(tsv_file)
    print('\n Checking the contents of participants.tsv')
    for error in errors:
        print(error)


if __name__ == '__main__':
    main()
