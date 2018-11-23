#!/bin/bash
#
# Extract metrics. This script should be run within the subject's folder.
#
# Usage:
#   ./extract_metrics.sh <subject_ID>
#
# Where subject_ID refers to the subject ID according to the BIDS format.
#
# Example:
#   ./extract_metrics.sh sub-03
#
# Authors: Julien Cohen-Adad, Stephanie Alley

# Retrieve subject tag
sub=$1

# Go to anat folder where all structural data are located
cd anat/

# t1
# ==============================================================================
# Check if manual segmentation already exists
if [ -e "${sub}_T1w_seg_manual.nii.gz" ]; then
  file_T1w_seg="${sub}_T1w_seg_manual"
else
  file_T1w_seg="${sub}_T1w_seg"
fi
# Compute the cord CSA for each vertebral level of interest
sct_process_segmentation -i ${file_T1w_seg}.nii.gz -p csa -vert 2:3 -vertfile ${file_T1w_seg}_labeled.nii.gz -ofolder csa-SC_T1w

# t2
# ==============================================================================
# Check if manual segmentation already exists
if [ -e "${sub}_T2w_seg_manual.nii.gz" ]; then
  file_seg="${sub}_T2w_seg_manual"
else
  file_seg="${sub}_T2w_seg"
fi
# Compute the cord CSA for each vertebral level of interest
sct_process_segmentation -i ${file_seg}.nii.gz -p csa -vert 2:3 -vertfile ${file_T1w_seg}_labeled.nii.gz -ofolder csa-SC_T2w

# mt
# ==============================================================================
# Compute MTR and MTsat in WM between C2 and C5 vertebral levels
sct_extract_metric -i mtr.nii.gz -f label_axT1w/atlas -l 51 -vert 2:5 -o mtr.xls

# t2s
# ==============================================================================
# Check if manual GM segmentation already exists
if [ -e "${sub}_acq-ax_T2star_seg_manual.nii.gz" ]; then
  file_GM_seg="${sub}_acq-ax_T2star_gmseg_manual"
else
  file_GM_seg="${sub}_acq-ax_T2star_gmseg"
fi
# Compute the gray matter CSA between C3 and C4 levels
# NB: Here we set -no-angle 1 because we do not want angle correction: it is too
# unstable with GM seg, and t2s data were acquired orthogonal to the cord anyways.
sct_process_segmentation -i ${file_GM_seg}.nii.gz -p csa -no-angle 1 -vert 3:4 -vertfile ${file_T1w_seg}_labeled.nii.gz -ofolder csa-GM_T2s

# dmri
# ===========================================================================================
cd ../dwi
# Compute FA, MD and RD in WM between C2 and C5 vertebral levels
sct_extract_metric -i dti_FA.nii.gz -f label/atlas -l 51 -vert 2:5 -o fa.xls
sct_extract_metric -i dti_MD.nii.gz -f label/atlas -l 51 -vert 2:5 -o md.xls
sct_extract_metric -i dti_RD.nii.gz -f label/atlas -l 51 -vert 2:5 -o rd.xls
# Go to parent folder
cd ..
