import os 
import shutil 
import argparse


def move_files(path, suffix):
    os.chdir(path) # go to results folder
    list_folder = os.listdir("./")
    derivatives = "derivatives/labels/" 
    c = 0
    for x in list_folder:
        path_tmp = x + "/anat/" + x + "_" + suffix + ".nii.gz"
        # Check if file exists. 
        if os.path.isfile(path_tmp):
            c +=1
            path_out = derivatives + path_tmp
            os.makedirs(path_out, exist_ok=True)
            shutil.copy(path_tmp, path_out)
    print ("%i files moved"%(c))


def get_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--path", dest="path", required=True, type=str,
                        help="Path to results folder")
    parser.add_argument("-s", "--suffix", dest="suffix", required=True,
                        type=str, help="Suffix of the input file as in sub-xxx_suffix.nii.gz (E.g., _T2w)")
    return parser


def main():
    parser = get_parser()
    args = parser.parse_args()
    path_files = args.path
    chosen_suffix = args.suffix
    move_files(path_files, chosen_suffix)

if __name__=='__main__':
    main()
        
