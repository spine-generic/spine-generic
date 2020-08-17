## This script is used to do a batch defacing of T1w & T2w scans using R
## Basic usage example:
## deface_spineGeneric_usingR -i PATH_TO_DATASET_TO_DEFACE -o PATH_TO_OUTPUT_DATASET_DEFACED -f
## If you use the command for the first time and you want to populate the `_defaced` folder add the `-f` flag at the end.
## Author: Alexandru Foias
## License MIT

import argparse,os, shutil

import spinegeneric.cli

def get_parameters():
    parser = argparse.ArgumentParser(description=
    "This script is used to deface T1w and T2w data from a BIDS dataset. This "
    "function is a wrapper to the R command regular_deface.r."
    "First, you need to run the command with '-f' flag to copy the dataset,"
    "and then you re-run the command without the '-f' flag.")
    parser.add_argument("-i", "--input_path",
                        help="Path to BIDS folder that contains all subjects.",
                        required=True)
    parser.add_argument("-o", "--output_path",
                        help="Path to output BIDS folder.",
                        required=True)
    parser.add_argument("-f", "--folder_copy",
                        help="Flag to copy input data to output data folder ",
                        action='store_true',
                        required=False)
    args = parser.parse_args()
    return args

def main():
    """
    Wrapper to deface images using R.
    """
    args = get_parameters()
    input_path = args.input_path
    output_path = args.output_path
    folder_copy = args.folder_copy

    exclude_list = []
    contrastList = ('T1w', 'T2w')
    if folder_copy:
        shutil.copytree(input_path, output_path)
    else:
        for subject in (os.listdir(output_path)):
            pathSubject = os.path.join(output_path, subject)
            if os.path.isdir(pathSubject):
                for contrast in contrastList:
                    pathContrastDefaced = os.path.join(pathSubject,'anat',subject+'_'+contrast+ '_defaced.nii.gz')
                    pathContrast = os.path.join(pathSubject,'anat',subject+'_'+contrast+ '.nii.gz')
                    if not os.path.isfile(pathContrastDefaced) and ((subject+'_'+contrast+ '_defaced.nii.gz') not in exclude_list):
                        print ('Currently processing: ' + pathContrast )
                        try:
                            with importlib.resources.path(spinegeneric.cli, 'regular_deface.r') as script:
                                command = 'Rscript '+ script + ' -i '+pathContrast+ ' -o '+pathContrastDefaced
                                os.system(command)
                                pathContrastJson = (pathContrast.split('.')[0]+'.json')
                                pathContrastDefacedJson =  (pathContrastDefaced.split('.')[0]+'.json')
                                shutil.copy (pathContrastJson,pathContrastDefacedJson)
                        except:
                            try:
                                print ('Trying with special script... ')
                                with importlib.resources.path(spinegeneric.cli, 'special_deface.r') as script:
                                    command = 'Rscript '+ script + ' -i '+pathContrast+ ' -o '+pathContrastDefaced
                                    os.system(command)
                            except:
                                print ('Both scripts failed!!!')
                                pass
                    print ('\n')

if __name__ == "__main__":
    main()
