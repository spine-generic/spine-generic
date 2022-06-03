#!/bin/bash
RESULTFOLDER=$1

cd $RESULTFOLDER
SAVEFOLDER=$2

for SUB in `ls -d sub-*[0-9]`;do
	for ROI in precentral postcentral;do 
		for SIDE in rh lh;do
			RESULTFILE=$SAVEFOLDER/sg.$SIDE.aparc.stats.$ROI.csv
			APARC=$SUB/stats/$SIDE.aparc.stats
			#APARC=$SUB/stats/$SIDE.aparc.DKTatlas.stats
			#APARC=$SUB/stats/$SIDE.aparc.pial.stats
			if [ -z "$HEADER" ];then			
				HEADER=$(cat $APARC | grep "# ColHeaders" | sed 's/# ColHeaders StructName //' | sed 's/ /,/g')
				HEADER=$(echo -e "SubID,$HEADER")
				echo "$HEADER" > $SAVEFOLDER/sg.rh.aparc.stats.precentral.csv
				echo "$HEADER" > $SAVEFOLDER/sg.lh.aparc.stats.precentral.csv
				echo "$HEADER" > $SAVEFOLDER/sg.rh.aparc.stats.postcentral.csv
				echo "$HEADER" > $SAVEFOLDER/sg.lh.aparc.stats.postcentral.csv
			fi		
			DATA=$(cat $APARC | grep $ROI | sed 's/precentral//' | sed 's/postcentral//' | sed 's/^ *//g' | sed 's/ \{1,\}/,/g')
			DATA=$(echo -e "$SUB,$DATA")
			echo "$DATA" >> $RESULTFILE
		done
	done	
done



