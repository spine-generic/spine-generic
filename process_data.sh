#!/bin/bash
#
# Process data.
#
# This script should be run within the subject's folder.
#
# Usage:
#   ./run_process.sh <subject_ID>
#
# Where subject_ID refers to the subject ID according to the BIDS format.
#
# Example:
#   ./run_process.sh sub-03
#
# Authors: Julien Cohen-Adad, Stephanie Alley

# The following global variables are retrieved from parameters.sh but could be overwritten here:
# PATH_QC="~/qc"

# Retrieve subject tag
sub=$1

# Go to anat folder where all structural data are located
cd anat/

# t1
# ==============================================================================
# Check if manual segmentation already exists
if [ -e "${sub}_T1w_seg_manual.nii.gz" ]; then
  file_seg="${sub}_T1w_seg_manual"
else
  # Segment spinal cord
  sct_deepseg_sc -i "${sub}_T1w.nii.gz" -c t1 -qc ${PATH_QC}
  file_seg="${sub}_T1w_seg"
fi
# Check if manual labels already exists
if [ ! -e "label_c2c3.nii.gz" ]; then
  # echo "Create manual label at C2-C3 disc."
  sct_label_utils -i ${sub}_T1w.nii.gz -create-viewer 3 -o label_c2c3.nii.gz -msg 'Click at the posterior tip of C2-C3 disc, then click "Save and Quit".'
fi
# Generate labeled segmentation
sct_label_vertebrae -i ${sub}_T1w.nii.gz -s ${file_seg}.nii.gz -c t1 -initlabel label_c2c3.nii.gz -qc ${PATH_QC}
# Create labels in the cord at C2 and C5 mid-vertebral levels
sct_label_utils -i ${file_seg}_labeled.nii.gz -vert-body 2,5 -o labels_vert.nii.gz
# Register to PAM50 template
sct_register_to_template -i ${sub}_T1w.nii.gz -s ${file_seg}.nii.gz -l labels_vert.nii.gz -c t1 -param step=1,type=seg,algo=centermassrot:step=2,type=seg,algo=syn,slicewise=1,smooth=0,iter=5:step=3,type=im,algo=syn,slicewise=1,smooth=0,iter=3 -qc "$PATH_QC"
# Rename warping fields for clarity
mv warp_template2anat.nii.gz warp_template2T1w.nii.gz
mv warp_anat2template.nii.gz warp_T1w2template.nii.gz
# Warp template without the white matter atlas (we don't need it at this point)
sct_warp_template -d ${sub}_T1w.nii.gz -w warp_template2T1w.nii.gz -a 0
# Flatten scan along R-L direction (to make nice figures)
sct_flatten_sagittal -i ${sub}_T1w.nii.gz -s ${file_seg}.nii.gz

# t2
# ==============================================================================
# Check if manual segmentation already exists
if [ -e "${sub}_T2w_seg_manual.nii.gz" ]; then
  file_seg="${sub}_T2w_seg_manual"
else
  # Segment spinal cord
  sct_deepseg_sc -i ${sub}_T2w.nii.gz -c t2 -qc ${PATH_QC}
  file_seg="${sub}_T2w_seg"
fi
# Flatten scan along R-L direction (to make nice figures)
sct_flatten_sagittal -i ${sub}_T2w.nii.gz -s ${file_seg}.nii.gz

# mt
# ==============================================================================
# Check if manual segmentation already exists
if [ -e "${sub}_acq-ax_T1w_seg_manual.nii.gz" ]; then
  file_seg="${sub}_acq-ax_T1w_seg_manual"
else
  # Segment spinal cord
  sct_deepseg_sc -i ${sub}_acq-ax_T1w.nii.gz -c t1 -qc ${PATH_QC}
  file_seg="${sub}_acq-ax_T1w_seg"
fi
# Create mask
sct_create_mask -i ${sub}_acq-ax_T1w.nii.gz -p centerline,${file_seg}.nii.gz -size 35mm -o ${sub}_acq-ax_T1w_mask.nii.gz
# Crop data for faster processing
sct_crop_image -i ${sub}_acq-ax_T1w.nii.gz -m ${sub}_acq-ax_T1w_mask.nii.gz -o ${sub}_acq-ax_T1w_crop.nii.gz
# Register PD->T1w
# Tips: here we only use rigid transformation because both images have very similar sequence parameters. We don't want to use SyN/BSplineSyN to avoid introducing spurious deformations.
sct_register_multimodal -i ${sub}_acq-ax_PD.nii.gz -d ${sub}_acq-ax_T1w_crop.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -x spline
# Register MT->T1w
sct_register_multimodal -i ${sub}_acq-ax_MT.nii.gz -d ${sub}_acq-ax_T1w_crop.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -x spline
# Register template->T1w_ax (using template-T1w as initial transformation)
sct_register_multimodal -i $SCT_DIR/data/PAM50/template/PAM50_t1.nii.gz -iseg $SCT_DIR/data/PAM50/template/PAM50_cord.nii.gz -d ${sub}_acq-ax_T1w_crop.nii.gz -dseg ${file_seg}.nii.gz -param step=1,type=seg,algo=slicereg,metric=MeanSquares,smooth=2:step=2,type=im,algo=bsplinesyn,metric=MeanSquares,iter=5,gradStep=0.5 -initwarp warp_template2T1w.nii.gz -initwarpinv warp_T1w2template.nii.gz
# Rename warping field for clarity
mv warp_PAM50_t12sub-01_acq-ax_T1w_crop.nii.gz warp_template2axT1w.nii.gz
mv warp_sub-01_acq-ax_T1w_crop2PAM50_t1.nii.gz warp_axT1w2template.nii.gz
# Warp template
sct_warp_template -d ${sub}_acq-ax_T1w_crop.nii.gz -w warp_template2axT1w.nii.gz -ofolder label_axT1w
# Compute MTR
sct_compute_mtr -mt0 ${sub}_acq-ax_PD_reg.nii.gz -mt1 ${sub}_acq-ax_MT_reg.nii.gz
# Compute MTsat
# TODO
# sct_compute_mtsat -mt mt1_crop.nii.gz -pd mt0_reg.nii.gz -t1 t1w_reg.nii.gz -trmt 30 -trpd 30 -trt1 15 -famt 9 -fapd 9 -fat1 15
# Go back to parent folder
cd ..

#
# # dmri
# # ===========================================================================================
# cd dmri
# # Separate b=0 and DW images
# sct_dmri_separate_b0_and_dwi -i dmri.nii.gz -bvec bvecs.txt
# # Segment cord (1st pass)
# sct_propseg -i dwi_mean.nii.gz -c dwi
# # Create mask to aid in motion correction and for faster processing
# sct_create_mask -i dwi_mean.nii.gz -p centerline,dwi_mean_seg.nii.gz -size 30mm
# # Crop data for faster processing
# sct_crop_image -i dmri.nii.gz -m mask_dwi_mean.nii.gz -o dmri_crop.nii.gz
# # Motion correction
# sct_dmri_moco -i dmri_crop.nii.gz -bvec bvecs.txt -x spline
# # Check if manual segmentation already exists
# if [ -e "dwi_moco_mean_seg_manual.nii.gz" ]; then
#   file_seg="dwi_moco_mean_seg_manual.nii.gz"
# else
#   # Segment cord (2nd pass, after motion correction)
#   sct_propseg -i dwi_moco_mean.nii.gz -c dwi
#   file_seg="dwi_moco_mean_seg.nii.gz"
#   # Check segmentation results and do manual corrections if necessary, then save modified segmentation as dwi_moco_mean_seg_manual.nii.gz"
#   echo "Check segmentation and do manual correction if necessary, then save segmentation as dwi_moco_mean_seg_manual.nii.gz"
#   fsleyes dwi_moco_mean.nii.gz -cm greyscale dwi_moco_mean_seg.nii.gz -cm red -a 70.0 &
#   # pause process during checking
#   read -p "Press any key to continue..."
#   # check if segmentation was modified
#   if [ -e "dwi_moco_mean_seg_manual.nii.gz" ]; then
#   	file_seg="dwi_moco_mean_seg_manual.nii.gz"
#   fi
# fi
# # create dummy label with value=4
# sct_label_utils -i dwi_moco_mean.nii.gz -create 1,1,1,4 -o label_dummy.nii.gz
# # use dummy label to import labels from t1 and keep only value=4 label
# sct_label_utils -i ../t1/label_disc.nii.gz -remove label_dummy.nii.gz -o label_disc.nii.gz
# # Register template to dwi
# # Tips: Only use segmentations.
# # Tips: First step: slicereg based on images, with large smoothing to capture potential motion between anatomical and dmri.
# # Tips: Second step: bpslinesyn in order to adapt the shape of the cord to the dmri modality (in case there are distortions between anatomical and dmri).
# sct_register_to_template -i dwi_moco_mean.nii.gz -s ${file_seg} -ldisc label_disc.nii.gz -ref subject -c t1 -param step=1,type=seg,algo=centermass:step=2,type=seg,algo=bsplinesyn,slicewise=1,iter=3
# # Rename warping field for clarity
# mv warp_template2anat.nii.gz warp_template2dmri.nii.gz
# # Warp template
# sct_warp_template -d dwi_moco_mean.nii.gz -w warp_template2dmri.nii.gz
# # Compute DTI
# sct_dmri_compute_dti -i dmri_crop_moco.nii.gz -bvec bvecs.txt -bval bvals.txt
# #sct_dmri_compute_dti -i dmri_crop_moco.nii.gz -bvec bvecs.txt -bval bvals.txt -method restore
# # Go back to parent folder
# cd ..
#
#

#
# # t2s
# # ===========================================================================================
# cd t2s
# # Check if manual cord segmentation already exists
# if [ -e "t2s_gmseg_manual.nii.gz" ]; then
#   file_gmseg="t2s_gmseg_manual.nii.gz"
# else
#   # Segment gray matter
#   sct_deepseg_gm -i t2s.nii.gz
#   file_seg="t2s_gmseg.nii.gz"
#   # Check segmentation results and do manual corrections if necessary, then save modified segmentation as dwi_moco_mean_seg_manual.nii.gz"
#   echo "Check segmentation and do manual correction if necessary, then save segmentation as t2_seg_manual.nii.gz"
#   fsleyes t2s.nii.gz -cm greyscale -a 100.0 t2s_gmseg.nii.gz -cm red -a 70.0 &
#   # pause process during checking
#   read -p "Press any key to continue..."
#   # check if segmentation was modified
#   if [ -e "t2s_gmseg_manual.nii.gz" ]; then
#   	file_seg="t2s_gmseg_manual.nii.gz"
#   fi
# fi
# # Bring labeled segmentation to t2s space
# sct_register_multimodal -i ../t1/t1_seg_labeled.nii.gz -d t2s.nii.gz -identity 1 -x nn
# # Go back to parent folder
# cd ..
