#!/bin/bash

#Usage: Move to spine generic folder. 
#run ./move_files_derivatives.sh Suffix_file (e.g., T2w_seg-manual)
# It will create the according derivatives folder and move the file with the right suffix there. 

for file in ./*
do
	name="${file##*/}" #get everything befor the slash (sub name)
	if test -d "$file";then # check if it is a folder 
		if test -f "$file"/anat/"$name"_"$1".nii.gz; then #check if ile exists inside folder
			echo "$name" #Monitor processed folder
			mkdir -p derivatives/labels/"$name"/anat #create folder -p option used to create parent folder if needed 
			cp "$file"/anat/"$name"_"$1".nii.gz derivatives/labels/"$name"/anat/ #copy file
		fi
	fi
done
