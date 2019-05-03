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
#   Make sure to copy the file parameters_template.sh into parameters.sh and
#   edit it with the proper list of subjects and variable.
#
# Author: Julien Cohen-Adad


# Exit if user presses CTRL+C (Linux) or CMD+C (OSX)
trap "echo Caught Keyboard Interrupt within script. Exiting now.; exit" INT

# Build color coding (cosmetic stuff)
Color_Off='\033[0m'  # Text Reset
Green='\033[0;92m'  # Yellow
Red='\033[0;91m'  # Red
On_Black='\033[40m'  # Black

create_folder() {
  local folder="$1"
  mkdir -p $folder  # "-p" creates parent folders if needed
  if [ ! -d "$folder" ]; then
    printf "\n${Red}${On_Black}ERROR: Cannot create folder: $folder. Exit.${Color_Off}\n\n"
    exit 1
  fi
}

# Initialization
unset SITES
# unset SUBJECTS
time_start=$(date +%x_%r)

# Load config file
if [ -e "parameters.sh" ]; then
  source parameters.sh
else
  printf "\n${Red}${On_Black}ERROR: The file parameters.sh was not found. You need to create one for this pipeline to work.${Color_Off}\n\n"
  exit 1
fi

# build syntax for process execution
task="`pwd`/$1"

# If the variable SITES does not exist (commented), get list of all sites
if [ -z ${SITES} ]; then
  echo "Processing all sites located in: $PATH_DATA"
  # Get list of folders (remove full path, only keep last element)
  SITES=`ls -d ${PATH_DATA}/*/ | xargs -n 1 basename`
else
  echo "Processing sites specified in parameters.sh"
fi
echo "--> " ${SITES[@]}

# Create folders
create_folder $PATH_LOG
create_folder $PATH_OUTPUT

# Run processing with or without "GNU parallel", depending if it is installed or not
if [ -x "$(command -v parallel)" ]; then
  echo 'GNU parallel is installed! Processing subjects in parallel using multiple cores.' >&2
  for site in ${SITES[@]}; do
    mkdir -p ${PATH_OUTPUT}/${site}
    find ${PATH_DATA}/${site} -mindepth 1 -maxdepth 1 -type d | while read site_subject; do
      subject=`basename $site_subject`
      # echo "cd ${PATH_DATA}/${site}; ${task} $(basename $subject) $site $PATH_OUTPUT $PATH_QC $PATH_LOG 2>&1 | tee ${PATH_LOG}/${site}_${subject}.log ; test ${PIPESTATUS[0]} -eq 0 ; echo $?"  #if [ ! $? -eq 0 ]; then mv ${PATH_LOG}/${site}_${subject}.log ${PATH_LOG}/err.${site}_${subject}.log; fi"
      # echo "cd ${PATH_DATA}/${site}; ${task} $(basename $subject) $site $PATH_OUTPUT $PATH_QC $PATH_LOG 2>&1 | tee ${PATH_LOG}/${site}_${subject}.log ; echo $?"  #if [ ! $? -eq 0 ]; then mv ${PATH_LOG}/${site}_${subject}.log ${PATH_LOG}/err.${site}_${subject}.log; fi"
      echo "./_run_with_log.sh ${task} $(basename $subject) $site $PATH_OUTPUT $PATH_QC $PATH_LOG"  #if [ ! $? -eq 0 ]; then mv ${PATH_LOG}/${site}_${subject}.log ${PATH_LOG}/err.${site}_${subject}.log; fi"
    done
  done \
  | parallel -j ${JOBS} --halt-on-error soon,fail=1 bash -c "{}"
else
  echo 'GNU parallel is not installed. Processing subjects sequentially.' >&2
  for site in ${SITES[@]}; do
    mkdir -p ${PATH_OUTPUT}/${site}
    find ${PATH_DATA}/${site} -mindepth 1 -maxdepth 1 -type d | while read site_subject; do
      subject=`basename $site_subject`
      cd ${PATH_DATA}/${site}
      ${task} $(basename $subject) $site $PATH_OUTPUT $PATH_QC $PATH_LOG 2>&1 | tee ${PATH_LOG}/${site}_${subject}.log ; test ${PIPESTATUS[0]} -eq 0
      if [ ! $? -eq 0 ]; then
        mv ${PATH_LOG}/${site}_${subject}.log ${PATH_LOG}/err.${site}_${subject}.log
      fi
    done
  done
fi

# Display stuff
echo "FINISHED :-)"
echo "Started: $time_start"
echo "Ended  : $(date +%x_%r)"
