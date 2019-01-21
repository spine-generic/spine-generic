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

# Fetch OS type (used to open QC folder)
if uname -a | grep -i  darwin > /dev/null 2>&1; then
  # OSX
  export OPEN_CMD="open"
elif uname -a | grep -i  linux > /dev/null 2>&1; then
  # Linux
  export OPEN_CMD="xdg-open"
fi

# Initialization
unset SITES
# unset SUBJECTS
time_start=$(date +%x_%r)

# Load config file
if [ -e "parameters.sh" ]; then
  source parameters.sh
else
  printf "\n${Red}${On_Black}ERROR: The file parameters.sh was not found. You need to create one for this pipeline to work. Please see README.md.${Color_Off}\n\n"
  exit 1
fi

# build syntax for process execution
task=`pwd`/$1

# If the variable SITES does not exist (commented), get list of all sites
if [ -z ${SITES} ]; then
  echo "Processing all sites located in: $PATH_DATA"
  # Get list of folders (remove full path, only keep last element)
  SITES=`ls -d ${PATH_DATA}/*/ | xargs -n 1 basename`
else
  echo "Processing sites specified in parameters.sh"
fi
echo "--> " ${SITES[@]}

# Create processing folder ("-p" creates parent folders if needed)
mkdir -p ${PATH_PROCESSING}
if [ ! -d "$PATH_PROCESSING" ]; then
  printf "\n${Red}${On_Black}ERROR: Cannot create folder: $PATH_PROCESSING. Exit.${Color_Off}\n\n"
  exit 1
fi

# Processing of one subject
do_one_subject() {
  local subject="$1"
  a="${PATH_PROCESSING}/$(basename $(dirname $subject))_$(basename $subject)"
  echo "rsync -avzh ${subject}/ ${a}/; cd ${a}; ${task} $(basename $subject) ${PATH_PROCESSING} ${PATH_QC}"
}

# Run processing with or without "GNU parallel", depending if it is installed or not
if [ -x "$(command -v parallel)" ]; then
  echo 'GNU parallel is installed! Processing subjects in parallel using multiple cores.' >&2
  for site in ${SITES[@]}; do
    find ${PATH_DATA}/${site} -mindepth 1 -maxdepth 1 -type d | while read subject; do
      do_one_subject "$subject"
    done
  done \
  | parallel --halt-on-error soon,fail=1 sh -c "{}"
else
  echo 'GNU parallel is not installed. Processing subjects sequentially.' >&2
  for site in ${SITES[@]}; do
    find ${PATH_DATA}/${site} -mindepth 1 -maxdepth 1 -type d | while read subject; do
      do_one_subject "$subject"
    done
  done
fi  

# Display stuff
echo "FINISHED :-)"
echo "Started: $time_start"
echo "Ended  : $(date +%x_%r)"

# Display syntax to open QC report on web browser
echo "To open Quality Control (QC) report on a web-browser, run the following:\n"
echo "${OPEN_CMD} ${PATH_QC}/index.html"
