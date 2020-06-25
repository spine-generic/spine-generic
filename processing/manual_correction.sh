#!/bin/bash

# Run this script in results/data folder
#
# USAGE - define $FILES variable as list of segmentations (separeted by space)
# to correct in the terminal and then run:
#   PATH_TO_SPINEGENERIC/processing/manual_correction.sh $FILES
#


# Print help
if [[ $# != 1 ]] || [[ $1 == "--help" ]] || [[ $1 == "-h" ]];then

  echo "Invalid input. Please define \$FILES variable as list of segmentations (separeted by space) to correct in the terminal."
  echo -e "Example:\n\tFILES=(sub-amu02_acq-T1w_MTS.nii.gz sub-beijingGE04_T2w_RPI_r.nii.gz)"
  echo -e "Then run:\n\tPATH_TO_SPINEGENERIC/processing/manual_correction.sh \$FILES"

else

  # Folder to output the manual labels
  PATH_SEGMANUAL="../../seg_manual"
  mkdir $PATH_SEGMANUAL
  # List of files to correct segmentation on
  FILES=$1

  # Loop across files
  for file in ${FILES[@]}; do
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
    # Copy file to PATH_SEGMANUAL
    cp $fname_seg $fname_seg_dest
    # Launch FSLeyes
    echo "In FSLeyes, click on 'Edit mode', correct the segmentation, then save it with the same name (overwrite)."
    fsleyes -yh $fname_data $fname_seg_dest -cm red
  done

fi
