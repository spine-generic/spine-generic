#!/bin/bash
# 
# Process data.
# 
# Run script within the subject's folder.
# 
# Dependencies: 
# - SCT v3.2.0 and higher.
# - (fsleyes for visualization)
# 
# Authors: Julien Cohen-Adad, Stephanie Alley


# t1
# ===========================================================================================
cd t1
# Compute the cord CSA for each vertebral level of interest
for i in 3 4 5 6 7 8
do
  sct_process_segmentation -i t1_seg_manual.nii.gz -p csa -vert ${i}:${i} -vertfile t1_seg_labeled.nii.gz -ofolder csa_${i}
done
# Go to parent folder
cd ..


# t2
# ===========================================================================================
cd t2
# Compute the CSA of the cord for each vertebral level of interest
for i in 3 4 5 6 7 8
do
  sct_process_segmentation -i t2_seg_manual.nii.gz -p csa -vert ${i}:${i} -vertfile t1_seg_labeled_reg.nii.gz -ofolder csa_${i}
done
# Go to parent folder
cd ..


# dmri
# ===========================================================================================
cd dmri
# Compute FA in WM for each slice
for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14
do
  sct_extract_metric -i dti_FA.nii.gz -f label/template/PAM50_wm.nii.gz -z ${i} -o fa.xls
done
# Go to parent folder
cd ..


# mt
# ===========================================================================================
cd mt
# Compute MTR in WM for each slice
for i in 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19
do
  sct_extract_metric -i mtr.nii.gz -f label/template/PAM50_wm.nii.gz -z ${i} -o mtr.xls
done
# Go to parent folder
cd ..


# t2s
# ===========================================================================================
cd t2s
# Compute the gray matter CSA for each vertebral level of interest
for i in 3 4
do
  sct_process_segmentation -i t2s_gmseg_manual.nii.gz -p csa -vert ${i} -ofolder csa_gm_${i}
done
# Go to parent folder
cd ..