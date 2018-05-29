#!/bin/bash
# 
# Process data.
# 
# Run script from the subject's folder.
# 
# Dependencies: 
# - SCT v3.2.0 and higher.
# - fsleyes
# 
# Authors: Julien Cohen-Adad, Stephanie Alley


# t1
# ===========================================================================================================
cd t1
# Check if manual segmentation already exists
if [ -e "t1_seg_manual.nii.gz" ]; then
  file_seg="t1_seg_manual.nii.gz"
else
  echo "Segment spinal cord"
  sct_propseg -i t1.nii.gz -c t1
  file_seg="t1_seg.nii.gz"
  # Check segmentation results and do manual corrections if necessary
  echo "Check segmentation and do manual correction if necessary, then save modified segmentation as t1_seg_manual.nii.gz"
  fsleyes t1.nii.gz -cm greyscale t1_seg.nii.gz -cm red -a 70.0 &
fi
# Check if manual labels already exists
if [ ! -e "label_disc.nii.gz" ]; then
  echo "Create manual labels."
  sct_label_utils -i t1.nii.gz -create-viewer 3,4,5,6,7,8 -o label_disc.nii.gz -msg "Place labels at the posterior tip of each inter-vertebral disc. E.g. Label 3: C2/C3, Label 4: C3/C4, etc."
fi
echo "Flatten t1 scan (to make nice figures"
sct_flatten_sagittal -i t1.nii.gz -s ${file_seg}
# Go to parent folder
cd ..


# t2
# ===========================================================================================================
cd t2
# Check if manual segmentation already exists
if [ -e "t2_seg_manual.nii.gz" ]; then
  file_seg="t2_seg_manual.nii.gz"
else
  echo "Segment spinal cord"
  sct_propseg -i t2.nii.gz -c t2
  file_seg="t2_seg.nii.gz"
  # Check segmentation results and do manual corrections if necessary
  echo "Check segmentation and do manual correction if necessary, then save modified segmentation as t2_seg_manual.nii.gz"
  fsleyes t2.nii.gz -cm greyscale t2_seg.nii.gz -cm red -a 70.0 &
fi
# Check if manual labels already exists
if [ ! -e "label_disc.nii.gz" ]; then
  echo "Create manual labels."
  sct_label_utils -i t2.nii.gz -create-viewer 3,4,5,6,7,8 -o label_disc.nii.gz -msg "Place labels at the posterior tip of each inter-vertebral disc. E.g. Label 3: C2/C3, Label 4: C3/C4, etc."
fi
echo "Flatten t2 scan (to make nice figures"
sct_flatten_sagittal -i t2.nii.gz -s ${file_seg}
# Go to parent folder
cd ..


# # Segment cord
# echo "Segmenting t2 cord"
# sct_propseg -i t2.nii.gz -c t2 -radius 5 -max-deformation 5 -d 15 -alpha 30

# # Smooth cord to aid in segmentation
# sct_smooth_spinalcord -i t2.nii.gz -s t2_seg.nii.gz -smooth 7
# sct_propseg -i t2_smooth.nii.gz -c t2 -init-centerline t2_seg.nii.gz

# # Rename segmented image
# mv t2_smooth_seg.nii.gz t2_seg.nii.gz

# # Check segmentation results
# fslview t2.nii.gz t2_seg.nii.gz -l Red -b 0,1 -t 0.7 &

# # Create a file, labels.nii.gz, that will be used for template registration
# # Manually create labels at C3 (3) and T1 (8) by clicking on the center of the vertebral level using the interactive window
# echo "Creating t2 labels"
# sct_label_utils -i t2.nii.gz -create-viewer 3,8

# # Create mask for faster processing
# sct_create_mask -i t2.nii.gz -p centerline,t2_seg.nii.gz -size 100mm -o mask_cord.nii.gz

# # Crop data for faster processing
# echo "Cropping t2 data"
# sct_crop_image -i t2.nii.gz -m mask_cord.nii.gz -o t2_crop.nii.gz
# sct_crop_image -i t2_seg.nii.gz -m mask_cord.nii.gz -o t2_seg_crop.nii.gz
# sct_crop_image -i labels.nii.gz -m mask_cord.nii.gz -o labels_crop.nii.gz

# # Create vertebral levels for the cord segmentation
# # Initialize manually by clicking on the C2-C3 disc using the interactive window
# echo "Creating vertebral levels for t2"
# sct_label_vertebrae -i t2_crop.nii.gz -s t2_seg_crop -c t2 -initc2

# # Register to template
# echo "Registering t2 to template"
# sct_register_to_template -i t2_crop.nii.gz -s t2_seg_crop.nii.gz -c t2 -l labels_crop.nii.gz

# # Warp template without white matter atlas
# echo "Warping template to t2"
# sct_warp_template -d t2_crop.nii.gz -w warp_template2anat.nii.gz -a 0

# Go to parent folder
cd ..

# # ===========================================================================================================

# # dmri
# cd dmri

# # Separate b=0 and DW images
# echo "Separating b=0 and DW images"
# sct_dmri_separate_b0_and_dwi -i dmri.nii.gz -bvec bvecs.txt

# # Segment cord (1st pass)
# echo "Segmenting dwi cord"
# sct_propseg -i dwi_mean.nii.gz -c dwi

# # Create mask to aid in motion correction and for faster processing
# echo "Creating mask for dwi"
# sct_create_mask -i dwi_mean.nii.gz -p centerline,dwi_mean_seg.nii.gz -size 30mm

# # Crop data for faster processing
# echo "Cropping dwi data"
# sct_crop_image -i dmri.nii.gz -m mask_dwi_mean.nii.gz -o dmri_crop.nii.gz

# # Motion correction
# echo "Performing motion correction"
# sct_dmri_moco -i dmri_crop.nii.gz -bvec bvecs.txt -x spline

# # Segment cord (2nd pass, after motion correction)
# echo "Segmenting dwi cord"
# sct_propseg -i dwi_moco_mean.nii.gz -c dwi

# # Check segmentation results
# fslview dwi_moco_mean.nii.gz dwi_moco_mean_seg.nii.gz -l Red -b 0,1000 -t 0.7 &

# # Create close mask around spinal cord after motion correction (for more accurate registration results)
# echo "Creating close mask for dwi"
# sct_create_mask -i dwi_moco_mean.nii.gz -p centerline,dwi_moco_mean_seg.nii.gz -size 25mm -f cylinder

# # Register template to dwi
# # Tips: Only use segmentations.
# # Tips: First step: slicereg based on images, with large smoothing to capture potential motion between anatomical and dmri.
# # Tips: Second step: bpslinesyn in order to adapt the shape of the cord to the dmri modality (in case there are distortions between anatomical and dmri).
# # Tips: The initial warping field is that used to warp the template to t2.
# echo "Registering template to dwi"
# sct_register_multimodal -i $SCT_DIR/data/PAM50/template/PAM50_t2.nii.gz -d dwi_moco_mean.nii.gz -iseg $SCT_DIR/data/PAM50/template/PAM50_cord.nii.gz -dseg dwi_moco_mean_seg.nii.gz -param step=1,type=seg,algo=slicereg,smooth=3:step=2,type=seg,algo=bsplinesyn,slicewise=1,iter=3 -m mask_dwi_moco_mean.nii.gz -initwarp ../t2/warp_template2anat.nii.gz

# # Rename warping field for clarity
# mv warp_PAM50_t22dwi_moco_mean.nii.gz warp_template2dwi.nii.gz

# # Warp template and white matter atlas
# echo "Warping template to dwi"
# sct_warp_template -d dwi_moco_mean.nii.gz -w warp_template2dwi.nii.gz

# # Compute DTI
# echo "Computing DTI"
# sct_dmri_compute_dti -i dmri_crop_moco.nii.gz -bvec bvecs.txt -bval bvals.txt

# # Go to parent folder
# cd ..

# # ===========================================================================================================
# "
# # mt
# cd mt

# # Bring t1 segmentation into mt space to aid in segmentation (no optimization)
# echo "Bringing t1 segmentation into mt space"
# sct_register_multimodal -i ../t1/t1_seg.nii.gz -d mt1.nii.gz -identity 1 -x nn

# # Create mask for faster processing
# echo "creating mask for mt"
# sct_create_mask -i mt1.nii.gz -p centerline,t1_seg_reg.nii.gz -size 45mm

# # Crop data for faster processing
# echo "Cropping mt data"
# sct_crop_image -i mt1.nii.gz -m mask_mt1.nii.gz -o mt1_crop.nii.gz
# sct_crop_image -i mt0.nii.gz -m mask_mt1.nii.gz -o mt0_crop.nii.gz

# # Segment mt1
# echo "Segmenting mt1 cord"
# sct_propseg -i mt1_crop.nii.gz -c t2 -init-centerline t1_seg_reg.nii.gz

# # Check segmentation results
# fslview mt1_crop.nii.gz mt1_crop_seg.nii.gz -l Red -b 0,1 -t 0.7 &

# # Create close mask around spinal cord (for more accurate registration results)
# echo "Creating close mask for mt"
# sct_create_mask -i mt1_crop.nii.gz -p centerline,mt1_crop_seg.nii.gz -size 35mm -f cylinder

# # Register mt0 on mt1
# # Tips: Only use rigid transformation because both images have very similar sequence parameters. We don't want to use SyN/BSplineSyN to avoid introducing spurious deformations.
# echo "Registering mt0 to mt1"
# sct_register_multimodal -i mt0_crop.nii.gz -d mt1_crop.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -m mask_mt1_crop.nii.gz -x spline

# # Compute mtr
# echo "Computing mtr"
# sct_compute_mtr -mt0 mt0_crop_reg.nii.gz -mt1 mt1_crop.nii.gz

# # Register template to mt1
# # Tips: Only use segmentations.
# # Tips: First step: slicereg based on images, with large smoothing to capture potential motion between anatomical and mt.
# # Tips: Second step: bpslinesyn in order to adapt the shape of the cord to the mt modality (in case there are distortions between anatomical and mt).
# # Tips: The initial warping field is that used to warp the template to t1.
# echo "Registering template to mt1"
# sct_register_multimodal -i $SCT_DIR/data/PAM50/template/PAM50_t2.nii.gz -d mt1_crop.nii.gz -iseg $SCT_DIR/data/PAM50/template/PAM50_cord.nii.gz -dseg mt1_crop_seg.nii.gz -param step=1,type=seg,algo=slicereg,smooth=3:step=2,type=seg,algo=bsplinesyn,slicewise=1,iter=3 -m mask_mt1_crop.nii.gz -initwarp ../t1/warp_template2anat.nii.gz

# # Rename warping field for clarity
# mv warp_PAM50_t22mt1_crop.nii.gz warp_template2mt.nii.gz

# # Warp template and white matter atlas
# echo "Warping template to mt"
# sct_warp_template -d mt1_crop.nii.gz -w warp_template2mt.nii.gz

# # Go to parent folder
# cd ..

# # ===========================================================================================================
# : "
# # gre-me
# cd gre-me

# #Segment cord
# echo "Segmenting gre-me cord"
# sct_propseg -i gre-me.nii.gz -c t2_seg

# # Add QC here

# # Create a file, labels.nii.gz, that will be used for template registration
# # Manually create labels at C3 (3) and C4 (4) by clicking on the center of the respective vertebral level using the interactive window
# echo "Creating gre-me labels"
# sct_label_utils -i gre-me.nii.gz -create-viewer 3,4

# # Create mask for faster processing
# sct_create_mask -i gre-me.nii.gz -p centerline,gre-me_seg.nii.gz -size 40mm -o mask_cord.nii.gz

# # Crop data for faster processing
# echo "Cropping gre-me data"
# sct_crop_image -i gre-me.nii.gz -m mask_cord.nii.gz -o gre-me_crop.nii.gz
# sct_crop_image -i gre-me_seg.nii.gz -m mask_cord.nii.gz -o gre-me_seg_crop.nii.gz
# sct_crop_image -i labels.nii.gz -m mask_cord.nii.gz -o labels_crop.nii.gz

# # Create vertebral levels for the cord segmentation (t1 and t2 are the only contrast options available)
# # Initialize manually by clicking on the C2-C3 disc using the interactive window
# echo "Creating vertebral levels for gre-me"
# sct_label_vertebrae -i gre-me_crop.nii.gz -s gre-me_seg_crop -c t2 -initc2

# # Register to template
# echo "Registering gre-me to template"
# sct_register_to_template -i gre-me_crop.nii.gz -s gre-me_seg_crop.nii.gz -c t2s -l labels_crops.nii.gz

# # Warp template without the white matter atlas
# echo "Warping template to gre-me"
# sct_warp_template -d gre-me_crop.nii.gz -w warp_template2anat.nii.gz -a 0

# # Segment the gray matter of the gre-me
# echo "Segmenting gre-me gray matter"
# sct_segment_graymatter -i gre-me_crop.nii.gz -s gre-me_seg_crop.nii.gz

# # Go to parent folder
# cd ..
