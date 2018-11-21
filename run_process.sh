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

# Go to path data folder that encloses all subjects' folders
cd ${PATH_DATA}

# If the variable SUBJECTS does not exist (commented), get list of all subject
# folders from current directory
if [ -z ${SUBJECTS} ]; then
  echo "Processing all subjects present in: $PATH_DATA."
  SUBJECTS=`ls -d */`
else
  echo "Processing subjects specified in parameters.sh."
fi

# Loop across subjects
for subject in ${SUBJECTS[@]}; do
  # Display stuff
  printf "${Green}${On_Black}\n===============================\n\PROCESSING SUBJECT: ${subject}\n===============================\n${Color_Off}"
  # Go to subject folder
  cd ${subject}
  # Run process
  $CMD
  # Go back to parent folder
  cd ..
done
