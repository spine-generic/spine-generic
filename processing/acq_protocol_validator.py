#!/usr/bin/env python
#Use example: python acq_protocol_validator.py -d /Users/alfoi/Desktop/dataset_test -c /Users/alfoi/Desktop/template_acq_param.json
#Author: Alexandru Foias

import os, json, argparse

def get_parameters():
    parser = argparse.ArgumentParser(description='Compress DICOM scans to tar.gz')
    parser.add_argument('-d', '--path_dataset',
                        help='Path to input DICOM directory.',
                        required=True)
    parser.add_argument('-c', '--path_config_file',
                    help='Path to protocol config template.',
                    required=True)                  
    args = parser.parse_args()
    return args


def check_acq_param(path_dataset,path_config_file):
    with open(path_config_file, 'r') as f:
        acq_config_file = json.load(f)
    modality_key = acq_config_file.keys()

    for root,dirs,files in os.walk(path_dataset):
        for crt_file in files:
            for modality in modality_key:
                if crt_file.endswith('_'+modality+'.json'):
                    path_json = os.path.join(root,crt_file)
                    with open(path_json, 'r') as f:
                        acq_info = json.load(f)
                    for element in acq_config_file[modality].keys():
                        if element in acq_info.keys():
                            if acq_info[element] != acq_config_file[modality][element]:
                                print crt_file.split('.')[0] + " doesn't follow the protocol. Issue: " + element + ' = ' + str(acq_info[element]) + ' instead of '+  str(acq_config_file[modality][element])
if __name__ == "__main__":
    args = get_parameters()
    check_acq_param(args.path_dataset,args.path_config_file)