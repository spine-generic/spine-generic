#!/bin/bash
#
# This is a wrapper to processing scripts, that loops across subjects.
#
# Usage:
#   ./run_process.sh <script> <path_data>
#     script: the script to run
#     path_data: the absolute path that contains all subject folders
#
# Example:
#   ./run_process.sh extract_metrics.sh /Users/julien/data/spine_generic/
#
# NB: add the flag "-x" after "!/bin/bash" for full verbose of commands.
# Julien Cohen-Adad 2018-06-11

# Exit if user presses CTRL+C (Linux) or CMD+C (OSX)
trap "echo Caught Keyboard Interrupt within script. Exiting now.; exit" INT

# Load parameters
# source parameters.sh

# # Fetch OS type (used to open QC folder)
# if uname -a | grep -i  darwin > /dev/null 2>&1; then
#   # OSX
#   export OPEN_CMD="open"
# elif uname -a | grep -i  linux > /dev/null 2>&1; then
#   # Linux
#   export OPEN_CMD="xdg-open"
# fi

# Build color coding
Color_Off='\033[0m'       # Text Reset
Green='\033[0;92m'       # Yellow
On_Black='\033[40m'       # Black

# build syntax for process execution
CMD=`pwd`/$1

# go to path data
cd $2

# get list of folders in current directory
SUBJECTS=`ls -d */`

# Loop across subjects
for subject in ${SUBJECTS[@]}; do
  # Display stuff
  printf "${Green}${On_Black}\n===============================\nPROCESSING SUBJECT: ${subject}\n===============================\n${Color_Off}"
  # echo "==============================="
  # echo "PROCESSING SUBJECT: ${subject}"
  # echo "***"
  # go to subject folder
  cd ${subject}
  # run process
  $CMD
  # go back to parent folder
  cd ..
done
