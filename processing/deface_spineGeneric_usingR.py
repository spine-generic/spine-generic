import argparse,os, shutil

def get_parameters():
    parser = argparse.ArgumentParser(description='This script is used to deface openneuro scans')
    parser.add_argument("-i", "--input_path",
                        help="Path to folder containing input data",
                        required=True)
    parser.add_argument("-o", "--output_path",
                        help="Path to folder containing output data",
                        required=True)
    parser.add_argument("-f", "--folder_copy",
                        help="Flag to copy input data to output data folder ",
                        action='store_true',
                        required=False)                    
    args = parser.parse_args()
    return args

def main(input_path,output_path,folder_copy):
    """
    Main function
    :param input_path:
    :param output_path:
    :param folder_copy:
    :return:
    """

    exclude_list = []
    currentwd = os.getcwd()
    currentwd = os.path.dirname(os.path.realpath(__file__))
    contrastList = ('T1w','T2w')
    if folder_copy: 
        shutil.copytree(input_path,output_path)
    else:
        for subject in (os.listdir(output_path)):
            pathSubject = os.path.join(output_path,subject)
            if os.path.isdir(pathSubject):
                for contrast in contrastList:
                    pathContrastDefaced = os.path.join(pathSubject,'anat',subject+'_'+contrast+ '_defaced.nii.gz')
                    pathContrast = os.path.join(pathSubject,'anat',subject+'_'+contrast+ '.nii.gz')
                    if not os.path.isfile(pathContrastDefaced) and ((subject+'_'+contrast+ '_defaced.nii.gz') not in exclude_list):
                        print ('Currently processing: ' + pathContrast )
                        try:
                            command = 'Rscript '+ currentwd + '/regular_deface.r -i '+pathContrast+ ' -o '+pathContrastDefaced
                            os.system(command)
                            pathContrastJson = (pathContrast.split('.')[0]+'.json')
                            pathContrastDefacedJson =  (pathContrastDefaced.split('.')[0]+'.json')
                            shutil.copy (pathContrastJson,pathContrastDefacedJson)
                        except:
                            try:
                                print ('Trying with special script ... ')
                                command = 'Rscript '+ currentwd + '/special_deface.r -i '+pathContrast+ ' -o '+pathContrastDefaced
                                os.system(command)
                            except:
                                print ('Both scripts failed !!!')
                                pass
                    print ('\n')

if __name__ == "__main__":
    args = get_parameters()
    main(args.input_path,args.output_path,args.folder_copy)
