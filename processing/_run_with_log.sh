#!/bin/bash
#

TASK=$1
subject=$2
site=$3
PATH_OUTPUT=$4
PATH_QC=$5
PATH_LOG=$6

cd ${PATH_DATA}/${site}
${TASK} $(basename $subject) $site $PATH_OUTPUT $PATH_QC $PATH_LOG 2>&1 | tee ${PATH_LOG}/${site}_${subject}.log ; test ${PIPESTATUS[0]} -eq 0
if [ ! $? -eq 0 ]; then
  mv ${PATH_LOG}/${site}_${subject}.log ${PATH_LOG}/err.${site}_${subject}.log
fi
