# spine-generic

Description of the publicly-available database and processing pipeline for the "spine generic protocol" project.

- [Data collection and organization](#data-collection-and-organization)
- [Analysis pipeline](#analysis-pipeline)

## Data collection and organization

The "Spine Generic" MRI acquisition protocol is available at [this link](https://osf.io/tt4z9/). Each site scanned six healthy subjects (3 men, 3 women), aged between 20 and 40 y.o. Note: there is a flexibility here, and if you wish to scan more than 6 subjects, you are welcome to. If your site is interested in participating in this publicly-available database, please contact Julien Cohen-Adad for details.

### Data conversion: DICOM to BIDS

To facilitate the collection, sharing and processing of data, we use the [BIDS standard](http://bids.neuroimaging.io/). An example of the data structure for one center is shown below:

~~~
spineGeneric_multiSubjects
├── dataset_description.json
├── participants.json
├── participants.tsv
├── sub-ucl01
├── sub-ucl02
├── sub-ucl03
├── sub-ucl04
├── sub-ucl05
└── sub-ucl06
    ├── anat
    │   ├── sub-ucl06_T1w.json
    │   ├── sub-ucl06_T1w.nii.gz
    │   ├── sub-ucl06_T2star.json
    │   ├── sub-ucl06_T2star.nii.gz
    │   ├── sub-ucl06_T2w.json
    │   ├── sub-ucl06_T2w.nii.gz
    │   ├── sub-ucl06_acq-MToff_MTS.json
    │   ├── sub-ucl06_acq-MToff_MTS.nii.gz
    │   ├── sub-ucl06_acq-MTon_MTS.json
    │   ├── sub-ucl06_acq-MTon_MTS.nii.gz
    │   ├── sub-ucl06_acq-T1w_MTS.json
    │   └── sub-ucl06_acq-T1w_MTS.nii.gz
    └── dwi
        ├── sub-ucl06_dwi.bval
        ├── sub-ucl06_dwi.bvec
        ├── sub-ucl06_dwi.json
        └── sub-ucl06_dwi.nii.gz
~~~

To convert your DICOM data folder to the compatible BIDS structure, we ask you
to install [dcm2bids](https://github.com/cbedetti/Dcm2Bids#install). Once installed,
[download this config file](https://raw.githubusercontent.com/sct-pipeline/spine-generic/master/config_spine.txt) (click File>Save to save the file), then convert your Dicom folder using the following
command (replace xx with your center and subject number):
~~~
dcm2bids -d <PATH_DICOM> -p sub-xx -c config_spine.txt -o CENTER_spineGeneric
~~~

For example:
~~~
dcm2bids -d /Users/julien/Desktop/DICOM_subj3 -p sub-milan03 -c ~/Desktop/config_spine.txt -o milan_spineGeneric
~~~

A log file is generated under `tmp_dcm2bids/log/`. If you encounter any problem while
running the script, please [open an issue](https://github.com/sct-pipeline/spine-generic/issues)
and upload the log file. We will offer support.

Once you've converted all subjects for the study, create the following files and add them to the data structure:

**dataset_description.json** (Pick the correct values depending on your system and environment)
```
{
	"Name": "Spinal Cord MRI Public Database",
	"BIDSVersion": "1.2.0",
	"InstitutionName": "Name of the institution",
	"Manufacturer": "YOUR_VENDOR",
	"ManufacturersModelName": "YOUR_MODEL",
	"ReceiveCoilName": "YOUR_COIL",
	"SoftwareVersion": "YOUR_SOFTWARE",
	"Researcher": "J. Doe, S. Wonder, J. Pass",
	"Notes": "Particular notes you might have. E.g.: We don't have the ZOOMit license, unf-prisma/sub-01 and unf-skyra/sub-03 is the same subject.
}
```

Example of possible values:
- **Manufacturer**: "Siemens", "GE", "Philips"
- **ManufacturersModelName**: "Prisma", "Prisma-fit", "Skyra", "750w", "Achieva"
- **ReceiveCoilName**: "64ch+spine", "12ch+4ch neck", "neurovascular"
- **SoftwareVersion**: "VE11C", "DV26.0", "R5.3", ...

**participants.json** (This file is generic, you don't need to change anything there. Just create a new file with this content)
```json
{
    "participant_id": {
        "LongName": "Participant ID",
        "Description": "Unique ID"
    },
    "sex": {
        "LongName": "Participant gender",
        "Description": "M or F"
    },
    "age": {
        "LongName": "Participant age",
        "Description": "yy"
    },
    "date_of_scan": {
        "LongName": "Date of scan",
        "Description": "yyyy-mm-dd"
    }
}
```

**participants.tsv** (Tab-separated values)
```
participant_id	sex	age	date_of_scan	institution_id	institution	manufacturer	manufacturers_model_name	receive_coil_name	software_versions	researcher
sub-unf01	F	24	2018-12-07	unf	Neuroimaging Functional Unit (UNF), CRIUGM, Polytechnique Montreal	Siemens	Prisma-fit	HeadNeck_64	syngo_MR_E11	J. Cohen-Adad, A. Foias
sub-unf02	M	29	2018-12-07	unf	Neuroimaging Functional Unit (UNF), CRIUGM, Polytechnique Montreal	Siemens	Prisma-fit	HeadNeck_64	syngo_MR_E11	J. Cohen-Adad, A. Foias
sub-unf03	M	22	2018-12-07	unf	Neuroimaging Functional Unit (UNF), CRIUGM, Polytechnique Montreal	Siemens	Prisma-fit	HeadNeck_64	syngo_MR_E11	J. Cohen-Adad, A. Foias
sub-unf04	M	31	2018-12-07	unf	Neuroimaging Functional Unit (UNF), CRIUGM, Polytechnique Montreal	Siemens	Prisma-fit	HeadNeck_64	syngo_MR_E11	J. Cohen-Adad, A. Foias
sub-unf05	F	23	2019-01-11	unf	Neuroimaging Functional Unit (UNF), CRIUGM, Polytechnique Montreal	Siemens	Prisma-fit	HeadNeck_64	syngo_MR_E11	J. Cohen-Adad, A. Foias
sub-unf06	F	27	2019-01-11	unf	Neuroimaging Functional Unit (UNF), CRIUGM, Polytechnique Montreal	Siemens	Prisma-fit	HeadNeck_64	syngo_MR_E11	J. Cohen-Adad, A. Foias
```

Once you've created the BIDS dataset, remove any temp folders (e.g., `tmp_dcm2bids/`) and zip the entire folder. It is now ready for sharing! You could send it to Julien Cohen-Adad via any cloud-based method (Gdrive, Dropbox, etc.).

### Ethics and anonymization

Each subject consented to be scanned and to have their anonymized data put in a publicly-available repository. To prove it, an email from each participant should be sent to the manager of the database (Julien Cohen-Adad). The email should state the following: "I am the subject who volunteered and I give you permission to release the scan freely to the public domain."

Anatomical scans where facial features are visible (T1w) could be "defaced" before being collected (at the discretion of the subject). Because FreeSurfer's `mri_deface` does not work well on those data (which include a big portion of the spine), we recommend to do the defacing manually. It is a very easy procedure that takes less than a minute. To do so, open Fsleyes (as an example, but you could use another MRI editor) and open the T1w scan. Go to **Tools > Edit mode**, Select the pencil with size 100, deface, then save. Below is an example of a defaced subject:

![example_defacing](doc/example_defacing.png)

## Example datasets (WIP)

We provide two example datasets:
- Multi-center, single-subject
- [Multi-center, multi-subjects](https://openneuro.org/datasets/ds001919/)

## Analysis pipeline

The analysis pipeline available in this repository enables to output the following metrics (organized per contrast):

- **T1**: Spinal cord CSA averaged between C2 and C3.
- **T2**: Spinal cord CSA averaged between C2 and C3.
- **T2s**: Gray matter CSA averaged between C3 and C4.
- **DWI**: FA in WM averaged between C2 and C5.
- **MTS**: MTR in WM averaged between C2 and C5. Uses MTon_MTS and MToff_MTS.
- **MTS**: MTSat & T1 map in WM averaged between C2 and C5. Uses MTon_MTS, MToff_MTS and T1w_MTS.

### Dependencies

In its current state, this pipeline uses [SCT development version](https://github.com/neuropoly/spinalcordtoolbox#install-from-github-development). Once the pipeline is finalized, a stable version of SCT will be associated with this pipeline and indicated here. For now, please use the latest development version of SCT.

This pipeline also relies on [FSLeyes](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FSLeyes) for quality control (QC).

### How to run

Download (or `git clone`) this repository:
~~~
git clone https://github.com/sct-pipeline/spine-generic.git
~~~

Go to this repository:
~~~
cd spine-generic/processing
~~~

Copy and rename the parameter file:
~~~
cp parameters_template.sh parameters.sh
~~~

Edit the parameter file and modify the variables according to your needs:
~~~
edit parameters.sh
~~~

Launch processing
~~~
./run_process.sh process_data.sh
~~~

### Quality Control (Rapid)

A first quality control consists in opening the .csv results under `results/` folder
and spot values that are abnormality different than the group average.

Identify the site/subject/contrast associated with the abnormal value, and look at the
segmentation (or data). If the segmentation is clearly wrong, fix it (see [Quality Control (Slow)](#quality-control-slow). If the data look ugly (lots of artifact, motion, etc.), report it under a new file: `qc_report/$site_$subject_$contrast.txt`

### Quality Control (Slow)

After the processing is run, check your Quality Control (QC) report, by opening
double clicking on the file `qc/index.html`. Use the "Search" feature of the QC
report to quickly jump to segmentations or labeling results.

#### Segmentation

If you spot issues (missing pixels, leaking), identify the segmentation file, open
it with an editor (e.g., [FSLeyes](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FSLeyes)),
modify it (Tools > Edit Mode) and save it (Overlay > Save > Save to new file) with suffix `-manual`. Example: `sub-01_T2w_RPI_r_seg-manual.nii.gz`. Then, move the file to the folder you defined
under the variable `PATH_SEGMANUAL` in the file `parameters.sh`. Important: the manual segmentation
should be copied under a subfolder named after the site, e.g. `seg_manual/spineGeneric_unf/sub-01_T2w_RPI_r_seg-manual.nii.gz`. The files to look for are:

| Segmentation  | Associated image  | Relevant levels | Used for |
|:---|:---|:---|---|
| sub-XX_T1w_RPI_r_seg.nii.gz | sub-XX_T1w_RPI_r.nii.gz | C2-C3 | CSA |
| sub-XX_T2w_RPI_r_seg.nii.gz | sub-XX_T2w_RPI_r.nii.gz | C2-C3 | CSA |
| sub-XX_T2star_rms_gmseg.nii.gz | sub-XX_T2star_rms.nii.gz | C3-C4 | CSA |
| sub-XX_acq-T1w_MTS_seg.nii.gz | sub-XX_acq-T1w_MTS.nii.gz | C2-C5 | Template registration |

**Note:** For the interest of time, you don't need to fix *all* slices of the segmentation but only the ones listed
in the "Relevant levels" column of the table above.

#### Vertebral labeling

If you spot issues (wrong labeling), manually create labels in the cord at C2 and C5 mid-vertebral levels using the following command (you need to be in the appropriate folder before running the command):
~~~
sct_label_utils -i IMAGE -create-viewer 3,5 -o IMAGE_labels-manual.nii.gz
~~~
Example:
~~~
sct_label_utils -i sub-01_T1w.nii.gz -create-viewer 3,5 -o sub-01_T1w_labels-manual.nii.gz
mkdir ${PATH_SEGMANUAL}/spineGeneric_unf/
mv sub-01_T1w_labels-manual.nii.gz ${PATH_SEGMANUAL}/spineGeneric_unf/
~~~
Then, move the file to the folder you defined
under the variable `PATH_SEGMANUAL` in the file `parameters.sh`, as done for the segmentation.

Once you've corrected all the necessary files, re-run the whole process. Now, when the manual file exists,
the script will use it in the processing:
~~~
./run_process.sh process_data.sh
~~~

## Contributors

[List of contributors for the analysis pipeline.](https://github.com/sct-pipeline/spine_generic/graphs/contributors)

## License

The MIT License (MIT)

Copyright (c) 2018 Polytechnique Montreal, Université de Montréal

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
