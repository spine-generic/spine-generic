#!/bin/bash

#!/bin/bash

# Metric extraction from t1, t2, dmri, mt, and gre-me

# Run script within the vendor folder

# t1
cd t1

# Compute the CSA of the cord for each vertebral level of interest
echo "Computing cord CSA for each vertebral level in t1"
for i in 2 3 4 5 6 7
do
	sct_process_segmentation -i t1_seg_crop.nii.gz -p csa -vert ${i}:${i} -ofolder csa_${i}
done

# Go to parent folder
cd ..

# ===========================================================================================================

# t2
cd t2

# Compute the CSA of the cord for each vertebral level of interest
echo "Computing cord CSA for each vertebral level in t2"
for i in 2 3 4 5 6 7
do
	sct_process_segmentation -i t2_seg_crop.nii.gz -p csa -vert ${i}:${i} -ofolder csa_${i}
done

# Go to parent folder
cd ..

# ===========================================================================================================

# dmri
cd dmri

# Compute FA for each slice
echo "Computing FA for each slice"
for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14
do
  sct_extract_metric -i dti_FA.nii.gz -f dwi_moco_mean_seg.nii.gz -z ${i} -o fa.xls
done

# Go to parent folder
cd ..

# ===========================================================================================================

# mt
cd mt

# Compute MTR for each slice
echo "Computing MTR for each slice"
for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21
do
  sct_extract_metric -i mtr.nii.gz -f mt1_crop.nii.gz -z ${i} -o mtr.xls
done

# Go to parent folder
cd ..

# ===========================================================================================================

# gre-me
cd gre-me

# Compute the gray matter CSA for each vertebral level of interest
echo "Computing gray matter CSA for each vertebral level in gre-me"
for i in 3 4
do
	sct_process_segmentation -i gre-me_crop_gmseg.nii.gz -p csa -vert ${i}:${i} -ofolder csa_gm_${i}
done

# Go to parent folder
cd ..