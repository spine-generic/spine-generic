#!/bin/bash
#
# Wrapper to processing scripts, which loops across subjects. Data should be
# organized according to the BIDS structure:
# https://github.com/sct-pipeline/spine_generic#file-structure
#
# Usage:
#   ./run_process.sh <script>
#
# Example:
#   ./run_process.sh process_data.sh
#
# Note:
#   Make sure to edit the file parameters.sh with the proper list of subjects and variable.
#
# NB: add the flag "-x" after "!/bin/bash" for full verbose of commands.
#
# Author: Julien Cohen-Adad

# Exit if user presses CTRL+C (Linux) or CMD+C (OSX)
trap "echo Caught Keyboard Interrupt within script. Exiting now.; exit" INT

# Build color coding (cosmetic stuff)
Color_Off='\033[0m'  # Text Reset
Green='\033[0;92m'  # Yellow
Red='\033[0;91m'  # Red
On_Black='\033[40m'  # Black

# Load config file
if [ -e "parameters.sh" ]; then
  source parameters.sh
else
  printf "\n${Red}${On_Black}ERROR: The file parameters.sh was not found. You need to create one for this pipeline to work. Please see README.md.${Color_Off}\n\n"
  exit 1
fi

# build syntax for process execution
CMD=`pwd`/$1

# Go to path data folder that encloses all sites' folders
# cd ${PATH_DATA}

# If the variable SUBJECTS does not exist (commented), get list of all sites
if [ -z ${SITES} ]; then
  echo "Processing all sites located in: $PATH_DATA"
  # Get list of folders (remove full path, only keep last element)
  SITES=`ls -d ${PATH_DATA}/*/ | xargs -n 1 basename`
else
  echo "Processing sites specified in parameters.sh"
fi
echo "--> " ${SITES}

# If the variable SUBJECTS does not exist (commented), get list of all subjects
# if [ -z ${SUBJECTS} ]; then
#   echo "Processing all subjects present in: $PATH_DATA."
#   SUBJECTS=`ls -d */`
# else
#   echo "Processing subjects specified in parameters.sh."
# fi

# Create processing folder ("-p" creates parent folders if needed)
mkdir -p ${PATH_PROCESSING}
if [ ! -d "$PATH_PROCESSING" ]; then
  printf "\n${Red}${On_Black}ERROR: Cannot create folder: $PATH_PROCESSING. Exit.${Color_Off}\n\n"
  exit 1
fi

# Loop across sites
for site in ${SITES[@]}; do
  # If the variable SUBJECTS does not exist (commented), get list of all subjects
  if [ -z ${SUBJECTS} ]; then
    echo "Processing all subjects present in: $PATH_DATA:"
    # Get list of folders (remove full path, only keep last element)
    SUBJECTS=`ls -d ${PATH_DATA}/${site}/sub-*/ | xargs -n 1 basename`
  else
    echo "Processing subjects specified in parameters.sh:"
  fi
  echo "--> " ${SUBJECTS}
  # Loop across subjects
  for subject in ${SUBJECTS[@]}; do
    # Copy source subject folder to processing folder
    # Here, we merge the site+subject into a single folder to facilitate QC
    echo "Copy source data to processing folder..."
    folder_out=${site}_${subject}
    cp -r ${PATH_DATA}/${site}/${subject} ${PATH_PROCESSING}/${folder_out}
    # Go to folder
    cd ${PATH_PROCESSING}/${folder_out}
    # Display stuff
    printf "${Green}${On_Black}\n================================================================================${Color_Off}"
    printf "${Green}${On_Black}\n PROCESSING: ${site}_${subject}${Color_Off}"
    printf "${Green}${On_Black}\n================================================================================\n${Color_Off}"
    # Run process
    #$CMD ${subject}
  done
done
