#!/bin/bash
#
# Process data. This script should be run within the subject's folder.
#
# Usage:
#   ./process_data.sh <subject_ID>
#
# Where subject_ID refers to the subject ID according to the BIDS format.
#
# Example:
#   ./process_data.sh sub-03
#
# Authors: Julien Cohen-Adad, Stephanie Alley

# The following global variables are retrieved from parameters.sh but could be
# overwritten here:
# PATH_QC="~/qc"

# Exit if user presses CTRL+C (Linux) or CMD+C (OSX)
trap "echo Caught Keyboard Interrupt within script. Exiting now.; exit" INT

# Retrieve input params
sub=$1
PATH_PROCESSING=$2
PATH_QC=$3

# Go to anat folder where all structural data are located
cd anat/

# T1w
# ==============================================================================
file="${sub}_T1w"
# Reorient to RPI and resample to 1mm iso (supposed to be the effective resolution)
sct_image -i ${file}.nii.gz -setorient RPI -o ${file}_RPI.nii.gz
sct_resample -i ${file}_RPI.nii.gz -mm 1x1x1 -o ${file}_RPI_r.nii.gz
file="${file}_RPI_r"
# Check if manual segmentation already exists
if [ -e "${file}_seg_manual.nii.gz" ]; then
  file_T1w_seg="${file}_seg_manual"
else
  # Segment spinal cord
  sct_deepseg_sc -i "${file}.nii.gz" -c t1 -qc ${PATH_QC}
  file_T1w_seg="${file}_seg"
fi
# Check if manual labels already exists
# if [ ! -e "label_c2c3.nii.gz" ]; then
  # echo "Create manual label at C2-C3 disc."
  # sct_label_utils -i ${file}.nii.gz -create-viewer 3 -o label_c2c3.nii.gz -msg "Click at the posterior tip of C2-C3 disc, then click 'Save and Quit'"
# fi
# Generate labeled segmentation
sct_label_vertebrae -i ${file}.nii.gz -s ${file_T1w_seg}.nii.gz -c t1 -qc ${PATH_QC}
# Create labels in the cord at C2 and C5 mid-vertebral levels
sct_label_utils -i ${file_T1w_seg}_labeled.nii.gz -vert-body 2,5 -o labels_vert.nii.gz
# Register to PAM50 template
sct_register_to_template -i ${file}.nii.gz -s ${file_T1w_seg}.nii.gz -l labels_vert.nii.gz -c t1 -param step=1,type=seg,algo=centermassrot:step=2,type=seg,algo=syn,slicewise=1,smooth=0,iter=5:step=3,type=im,algo=syn,slicewise=1,smooth=0,iter=3 -qc ${PATH_QC}
# Rename warping fields for clarity
mv warp_template2anat.nii.gz warp_template2T1w.nii.gz
mv warp_anat2template.nii.gz warp_T1w2template.nii.gz
# Warp template without the white matter atlas (we don't need it at this point)
sct_warp_template -d ${file}.nii.gz -w warp_template2T1w.nii.gz -a 0 -ofolder label_T1w
# Flatten scan along R-L direction (to make nice figures)
sct_flatten_sagittal -i ${file}.nii.gz -s ${file_T1w_seg}.nii.gz
# Compute average cord CSA between C2 and C3
sct_process_segmentation -i ${file_T1w_seg}.nii.gz -vertfile ${file_T1w_seg}_labeled.nii.gz -p csa -vert 2:3 -o ${PATH_PROCESSING}/csa-SC_T1w.csv -append 1

# T2
# ==============================================================================
file="${sub}_T2w"
# Reorient to RPI and resample to 0.8mm iso (supposed to be the effective resolution)
sct_image -i ${file}.nii.gz -setorient RPI -o ${file}_RPI.nii.gz
sct_resample -i ${file}_RPI.nii.gz -mm 0.8x0.8x0.8 -o ${file}_RPI_r.nii.gz
file="${file}_RPI_r"
# Check if manual segmentation already exists
if [ -e "${file}_seg_manual.nii.gz" ]; then
  file_T2w_seg="${file}_seg_manual"
else
  # Segment spinal cord
  sct_deepseg_sc -i ${file}.nii.gz -c t2 -qc ${PATH_QC}
  file_T2w_seg="${file}_seg"
fi
# Flatten scan along R-L direction (to make nice figures)
sct_flatten_sagittal -i ${file}.nii.gz -s ${file_T2w_seg}.nii.gz
# Compute average cord CSA between C2 and C3
sct_process_segmentation -i ${file_T2w_seg}.nii.gz -p csa -vert 2:3 -vertfile ${file_T1w_seg}_labeled.nii.gz -o ${PATH_PROCESSING}/csa-SC_T2w.csv -append 1

# MTS
# ==============================================================================
file_t1w="${sub}_acq-T1w_MTS"
file_mton="${sub}_acq-MTon_MTS"
file_mtoff="${sub}_acq-MToff_MTS"
# Check if manual segmentation already exists
if [ -e "${file_t1w}_seg_manual.nii.gz" ]; then
  file_seg="${file_t1w}_seg_manual"
else
  # Segment spinal cord
  sct_deepseg_sc -i ${file_t1w}.nii.gz -c t1 -qc ${PATH_QC}
  file_seg="${file_t1w}_seg"
fi
# Create mask
sct_create_mask -i ${file_t1w}.nii.gz -p centerline,${file_seg}.nii.gz -size 35mm -o ${file_t1w}_mask.nii.gz
# Crop data for faster processing
sct_crop_image -i ${file_t1w}.nii.gz -m ${file_t1w}_mask.nii.gz -o ${file_t1w}_crop.nii.gz
# Register PD->T1w
# Tips: here we only use rigid transformation because both images have very similar sequence parameters. We don't want to use SyN/BSplineSyN to avoid introducing spurious deformations.
sct_register_multimodal -i ${file_mtoff}.nii.gz -d ${file_t1w}_crop.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -x spline
# Register MT->T1w
sct_register_multimodal -i ${file_mton}.nii.gz -d ${file_t1w}_crop.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -x spline
# Register template->T1w_ax (using template-T1w as initial transformation)
sct_register_multimodal -i $SCT_DIR/data/PAM50/template/PAM50_t1.nii.gz -iseg $SCT_DIR/data/PAM50/template/PAM50_cord.nii.gz -d ${file_t1w}_crop.nii.gz -dseg ${file_seg}.nii.gz -param step=1,type=seg,algo=slicereg,metric=MeanSquares,smooth=2:step=2,type=im,algo=bsplinesyn,metric=MeanSquares,iter=5,gradStep=0.5 -initwarp warp_template2T1w.nii.gz -initwarpinv warp_T1w2template.nii.gz
# Rename warping field for clarity
mv warp_PAM50_t12${file_t1w}_crop.nii.gz warp_template2axT1w.nii.gz
mv warp_${file_t1w}_crop2PAM50_t1.nii.gz warp_axT1w2template.nii.gz
# Warp template
sct_warp_template -d ${file_t1w}_crop.nii.gz -w warp_template2axT1w.nii.gz -ofolder label_axT1w
# Compute MTR
sct_compute_mtr -mt0 ${file_mtoff}_reg.nii.gz -mt1 ${file_mton}_reg.nii.gz
# Compute MTsat
sct_compute_mtsat -mt ${file_mton}_reg.nii.gz -pd ${file_mtoff}_reg.nii.gz -t1 ${file_t1w}_crop.nii.gz -trmt 57 -trpd 57 -trt1 15 -famt 9 -fapd 9 -fat1 15
# Extract MTR, MTsat and T1 in WM between C2 and C5 vertebral levels
sct_extract_metric -i mtr.nii.gz -f label_axT1w/atlas -l 51 -vert 2:5 -o ${PATH_PROCESSING}/MTR.csv -append 1
sct_extract_metric -i mtsat.nii.gz -f label_axT1w/atlas -l 51 -vert 2:5 -o ${PATH_PROCESSING}/MTsat.csv -append 1
sct_extract_metric -i t1map.nii.gz -f label_axT1w/atlas -l 51 -vert 2:5 -o ${PATH_PROCESSING}/T1.csv -append 1

# t2s
# ==============================================================================
file="${sub}_T2star"
# Compute root-mean square across 4th dimension (if it exists), corresponding to all echoes in Philips scans.
sct_maths -i ${file}.nii.gz -rms t -o ${file}_rms.nii.gz
file="${file}_rms"
# Check if manual GM segmentation already exists
if [ -e "${file}_gmseg_manual.nii.gz" ]; then
  file_GM_seg="${file}_gmseg_manual"
else
  # Segment spinal cord
  sct_deepseg_gm -i ${file}.nii.gz -qc ${PATH_QC}
  file_GM_seg="${file}_gmseg"
fi
# Compute the gray matter CSA between C3 and C4 levels
# NB: Here we set -no-angle 1 because we do not want angle correction: it is too
# unstable with GM seg, and t2s data were acquired orthogonal to the cord anyways.
sct_process_segmentation -i ${file_GM_seg}.nii.gz -p csa -no-angle 1 -vert 3:4 -vertfile ${file_T1w_seg}_labeled.nii.gz -o ${PATH_PROCESSING}/csa-GM_T2s.csv -append 1

# DWI
# ==============================================================================
cd ../dwi
# Separate b=0 and DW images
sct_dmri_separate_b0_and_dwi -i ${sub}_dwi.nii.gz -bvec ${sub}_dwi.bvec
# Segment cord (1st pass -- just to get rough centerline)
sct_propseg -i ${sub}_dwi_dwi_mean.nii.gz -c dwi
# Create mask to help motion correction and for faster processing
sct_create_mask -i ${sub}_dwi_dwi_mean.nii.gz -p centerline,${sub}_dwi_dwi_mean_seg.nii.gz -size 30mm
# Crop data for faster processing
sct_crop_image -i ${sub}_dwi.nii.gz -m mask_${sub}_dwi_dwi_mean.nii.gz -o ${sub}_dwi_crop.nii.gz
# Motion correction
sct_dmri_moco -i ${sub}_dwi_crop.nii.gz -bvec ${sub}_dwi.bvec -x spline
# Check if manual segmentation already exists
if [ -e "${sub}_dwi_crop_moco_dwi_mean_seg_manual.nii.gz" ]; then
  file_seg="${sub}_dwi_crop_moco_dwi_mean_seg_manual"
else
  # Segment cord (2nd pass, after motion correction)
  sct_propseg -i ${sub}_dwi_crop_moco_dwi_mean.nii.gz -c dwi -qc ${PATH_QC}
  file_seg="${sub}_dwi_crop_moco_dwi_mean_seg"
fi
# Register template->dwi (using template-T1w as initial transformation)
sct_register_multimodal -i $SCT_DIR/data/PAM50/template/PAM50_t1.nii.gz -iseg $SCT_DIR/data/PAM50/template/PAM50_cord.nii.gz -d ${sub}_dwi_crop_moco_dwi_mean.nii.gz -dseg ${file_seg}.nii.gz -param step=1,type=seg,algo=slicereg,metric=MeanSquares,smooth=2:step=2,type=im,algo=bsplinesyn,metric=MeanSquares,iter=5,gradStep=0.5 -initwarp ../anat/warp_template2T1w.nii.gz -initwarpinv ../anat/warp_T1w2template.nii.gz
# Rename warping field for clarity
mv warp_PAM50_t12${sub}_dwi_crop_moco_dwi_mean.nii.gz warp_template2dwi.nii.gz
mv warp_${sub}_dwi_crop_moco_dwi_mean2PAM50_t1.nii.gz warp_dwi2template.nii.gz
# Warp template
sct_warp_template -d ${sub}_dwi_crop_moco_dwi_mean.nii.gz -w warp_template2dwi.nii.gz
# Create mask around the spinal cord
sct_maths -i ${sub}_dwi_crop_moco_dwi_mean_seg.nii.gz -dilate 3,3,0 -o ${sub}_dwi_crop_moco_dwi_mean_seg_dil.nii.gz
# Compute DTI using RESTORE
sct_dmri_compute_dti -i ${sub}_dwi_crop_moco.nii.gz -bvec ${sub}_dwi.bvec -bval ${sub}_dwi.bval -method restore -m ${sub}_dwi_crop_moco_dwi_mean_seg_dil.nii.gz
# Compute FA, MD and RD in WM between C2 and C5 vertebral levels
sct_extract_metric -i dti_FA.nii.gz -f label/atlas -l 51 -vert 2:5 -o ${PATH_PROCESSING}/DWI_FA.csv -append 1
sct_extract_metric -i dti_MD.nii.gz -f label/atlas -l 51 -vert 2:5 -o ${PATH_PROCESSING}/DWI_MD.csv -append 1
sct_extract_metric -i dti_RD.nii.gz -f label/atlas -l 51 -vert 2:5 -o ${PATH_PROCESSING}/DWI_RD.csv -append 1
# Go back to parent folder
cd ..
