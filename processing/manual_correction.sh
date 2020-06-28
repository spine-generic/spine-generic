#!/bin/bash

# Run this script in results/data folder
#
# Manual segmentations and labels are saved into ../../seg_manual folder
# (feel free to change this folder by change PATH_SEGMANUAL variable)
#
# USAGE:
# Define files.yml file as following:
#   FILES_SEG:
#   - sub-amu01_T1w_RPI_r.nii.gz
#   - sub-amu01_T2w_RPI_r.nii.gz
#   - sub-brnoCeitec01_T2star_rms.nii.gz
#   FILES_LABEL:
#   - sub-amu01
#   - sub-brnoUhb01
#
#
# THEN RUN:
#   PATH_TO_SPINEGENERIC/processing/manual_correction.sh files.yml
#
# Authors: Julien Cohen-Adad, Jan Valosek


# function for parsing input yaml file
yaml_parser() {

  INPUT_YAML=$1

  # tr: delete all newlines begining with dash (-), so convert input file into one line without dashes
  # (this also deletes all other dashes, so it is necessary to use last sed)
  # 1st sed: delete "FILES_LABEL:" string and everything after it
  # 2nd sed: delete "FILES_SEG:" string itself
  # 3rd sed: replace "sub" by "sub-" (tr command deleted all dashes (-))
  FILES_SEG=$(cat $INPUT_YAML | tr -d '\n-' | sed 's/FILES_LABEL:.*//' | sed 's/FILES_SEG://' | sed 's/sub/sub-/g')
  # tr: delete all newlines begining with dash (-), so convert input file into one line without dashes
  # (this also deletes all other dashes, so it is necessary to use last sed)
  # 1st sed: delete everything before "FILES_LABEL:" string including string "FILES_LABEL:" itself
  # 2nd sed: replace "sub" by "sub-" (tr command deleted all dashes (-))
  FILES_LABEL=$(cat $INPUT_YAML | tr -d '\n-' | sed 's/.*FILES_LABEL://' | sed 's/sub/sub-/g')
}

# Print help, if invalid input
if [[ $# != 1 ]] || [[ $1 == "--help" ]] || [[ $1 == "-h" ]];then

  echo -e "Invalid input. \n\nPlease create a files.yml file, which lists the files associated"
  echo -e "with the segmentations or labels to manually correct."
  echo -e "\nExample:\n"
  echo -e "FILES_SEG:"
  echo -e "- sub-amu01_T1w_RPI_r.nii.gz"
  echo -e "- sub-amu01_T2w_RPI_r.nii.gz"
  echo -e "- sub-brnoCeitec01_T2star_rms.nii.gz"
  echo -e "FILES_LABEL:"
  echo -e "- sub-amu01"
  echo -e "- sub-brnoUhb01"
  echo -e "\nThen run this script in results/data folder:\n\tPATH_TO_SPINEGENERIC/processing/manual_correction.sh files.yml"

else

  # call yaml_parser function
  yaml_parser $1

  # Folder to output the manual segmentations and labels
  # TODO - make this variable as an optional input
  PATH_SEGMANUAL="../../seg_manual"
  mkdir $PATH_SEGMANUAL

  # Loop across segmentation files
  for file in $FILES_SEG; do

    # extract subject using first delimiter '_'
    subject=${file%%_*}
    # check if file is under dwi/ or anat/ folder and get fname_data
    if [[ $file == *"dwi"* ]]; then
      fname_data=$subject/dwi/$file
    else
      fname_data=$subject/anat/$file
    fi
    # get fname_seg depending if it is cord or GM seg
    if [[ $file == *"T2star"* ]]; then
      fname_seg=${fname_data%%".nii.gz"*}_gmseg.nii.gz${fname_data##*".nii.gz"}
      fname_seg_dest=${PATH_SEGMANUAL}/${file%%".nii.gz"*}_gmseg-manual.nii.gz${file##*".nii.gz"}
    else
      fname_seg=${fname_data%%".nii.gz"*}_seg.nii.gz${fname_data##*".nii.gz"}
      fname_seg_dest=${PATH_SEGMANUAL}/${file%%".nii.gz"*}_seg-manual.nii.gz${file##*".nii.gz"}
    fi
    # check if segmentation file exist, i.e., filename is correct
    if [[ -f $fname_seg ]];then
      # Copy file to PATH_SEGMANUAL
      cp $fname_seg $fname_seg_dest
      # Launch FSLeyes
      echo "In FSLeyes, click on 'Edit mode', correct the segmentation, then save it with the same name (overwrite)."
      fsleyes -yh $fname_data $fname_seg_dest -cm red
    else
      echo "File $file does not exist. Please verity if you entered filename correctly."
    fi

  done

  # Loop across labeling files
  for subject in $FILES_LABEL; do

    fname_label=$subject/anat/${subject}_T1w_RPI_r.nii.gz
    fname_label_dest=${PATH_SEGMANUAL}/${subject}_T1w_RPI_r_labels-manual.nii.gz
    # check if labeling file exist, i.e., filename is correct
    if [[ -f $fname_label ]];then
      # Launch GUI for manual labeling
      echo "In sct_label_utils GUI, select C3 and C5, then click 'Save and Quit'."
      sct_label_utils -i $fname_label -create-viewer 3,5 -o $fname_label_dest
    else
      echo "File $fname_label does not exist. Please verity if you entered filename correctly."
    fi

  done

fi
