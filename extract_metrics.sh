#!/bin/bash
# 
# Process data.
# 
# Run script within the subject's folder.
# 
# Dependencies: 
# - SCT v3.2.0 and higher.
# - FSL (for fslhd)
# - (fsleyes for visualization)
# 
# Authors: Julien Cohen-Adad, Stephanie Alley


# t1
# ===========================================================================================
cd t1
# remove existing folder
rm -rf csa
# Compute the cord CSA for each vertebral level of interest
for i in 2 3 4 5 6 7
do
  sct_process_segmentation -i t1_seg_manual.nii.gz -p csa -vert ${i} -vertfile t1_seg_labeled.nii.gz -ofolder csa
done
# Go to parent folder
cd ..


# t2
# ===========================================================================================
cd t2
# remove existing folder
rm -rf csa
# Compute the CSA of the cord for each vertebral level of interest
for i in 2 3 4 5 6 7
do
  sct_process_segmentation -i t2_seg_manual.nii.gz -p csa -vert ${i} -vertfile t1_seg_labeled_reg.nii.gz -ofolder csa
done
# Go to parent folder
cd ..


# dmri
# ===========================================================================================
cd dmri
# remove existing file
rm fa.xls
# get number of slices
# nz=`fslhd dti_fa.nii.gz.nii.gz | grep -m 1 dim3 | sed -e "s/^dim3           //"`
# build index from 0->nz-1
# ind=`seq 0 $((${nz}-1))`
# Compute FA in WM for each slice
for i in 2 3 4 5; do
  sct_extract_metric -i dti_FA.nii.gz -f label/atlas -l 51 -vert ${i} -o fa.xls
done
# Go to parent folder
cd ..


# mt
# ===========================================================================================
cd mt
# remove existing file
rm mtr.xls
# get number of slices
# nz=`fslhd mtr.nii.gz.nii.gz | grep -m 1 dim3 | sed -e "s/^dim3           //"`
# build index from 0->nz-1
# ind=`seq 0 $((${nz}-1))`
# Compute MTR in WM for each slice
for i in 2 3 4 5; do
  sct_extract_metric -i mtr.nii.gz -f label/atlas -l 51 -vert ${i} -o mtr.xls
  # sct_extract_metric -i mtr.nii.gz -f label/template/PAM50_wm.nii.gz -z ${i} -o mtr.xls
done
# Go to parent folder
cd ..


# t2s
# ===========================================================================================
cd t2s
# remove existing folder
rm -rf csa_gm
# Compute the gray matter CSA for each vertebral level of interest
# Tips: -no-angle 1 because we do not want angle correction (too unstable with GM seg), and t2s data were acquired orthogonal to the cord.
for i in 3 4
do
  sct_process_segmentation -i t2s_gmseg_manual.nii.gz -p csa -vert ${i} -vertfile t1_seg_labeled_reg.nii.gz -ofolder csa_gm
  # TODO: when (https://github.com/neuropoly/spinalcordtoolbox/issues/1791) is fixed, use the command below instead
  # sct_process_segmentation -i t2s_gmseg_manual.nii.gz -p csa -no-angle 1 -vert ${i} -vertfile t1_seg_labeled_reg.nii.gz -ofolder csa_gm
done
# Go to parent folder
cd ..