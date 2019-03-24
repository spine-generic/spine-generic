# spine-generic

Description of the publicly-available database and processing pipeline for the "spine generic protocol" project.

- [Data collection and organization](#data-collection-and-organization)
- [Analysis pipeline](#analysis-pipeline)

## Data collection and organization

The "Spine Generic" MRI acquisition protocol is available at [this link](https://osf.io/tt4z9/). If your site is interested in participating in this publicly-available database, please contact Julien Cohen-Adad for details.

### Data conversion: DICOM to BIDS

To facilitate the collection, sharing and processing of data, we use the [BIDS standard](http://bids.neuroimaging.io/). An example of the data structure is shown below:

~~~
ucl_spineGeneric
├── dataset_description.json
├── participants.json
├── participants.tsv
├── sub-01
├── sub-02
├── sub-03
├── sub-04
├── sub-05
└── sub-06
    ├── anat
    │   ├── sub-06_T1w.json
    │   ├── sub-06_T1w.nii.gz
    │   ├── sub-06_T2star.json
    │   ├── sub-06_T2star.nii.gz
    │   ├── sub-06_T2w.json
    │   ├── sub-06_T2w.nii.gz
    │   ├── sub-06_acq-MToff_MTS.json
    │   ├── sub-06_acq-MToff_MTS.nii.gz
    │   ├── sub-06_acq-MTon_MTS.json
    │   ├── sub-06_acq-MTon_MTS.nii.gz
    │   ├── sub-06_acq-T1w_MTS.json
    │   └── sub-06_acq-T1w_MTS.nii.gz
    └── dwi
        ├── sub-06_dwi.bval
        ├── sub-06_dwi.bvec
        ├── sub-06_dwi.json
        └── sub-06_dwi.nii.gz
~~~

To convert your DICOM data folder to the compatible BIDS structure, we ask you
to install [dcm2bids](https://github.com/cbedetti/Dcm2Bids#install). Once installed,
[download this config file](https://raw.githubusercontent.com/sct-pipeline/spine-generic/master/config_spine.txt) (click File>Save to save the file), then convert your Dicom folder using the following
command (replace xx with subject number):
~~~
dcm2bids -d <PATH_DICOM> -p sub-xx -c config_spine.txt -o CENTER_spineGeneric
~~~

For example:
~~~
dcm2bids -d /Users/julien/Desktop/DICOM_subj3 -p sub-03 -c ~/Desktop/config_spine.txt -o milan_spineGeneric
~~~

A log file is generated under `tmp_dcm2bids/log/`. If you encounter any problem while
running the script, please [open an issue](https://github.com/sct-pipeline/spine-generic/issues)
and upload the log file. We will offer support.

Once you've converted all subjects for the study, create the following files and add them to the data structure:

**dataset_description.json** (Pick the correct values depending on your system and environment)
```json
{
	"Name": "Spinal Cord MRI Public Database",
	"BIDSVersion": "1.0.1",
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
- **ManufacturersModelName**: "Prisma_fit", "Skyra", "750w", "Achieva"
- **ReceiveCoilName**: "64ch+spine", "12ch+4ch neck", "neurovascular"
- **SoftwareVersion**: "VE11C", "DV26.0", "R5.3", ...

**participants.json** (This file is generic, you don't need to change anything there)
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
id	sex	age	date_of_scan
sub-01	M	35	2018-12-18
sub-02	F	30	2018-11-01
```

Once you've created the BIDS dataset, zip the entire folder. It is now ready for sharing!

### Ethics and anonymization

Each subject consented to be scanned and to have their anonymized data put in a publicly-available repository. To prove it, an email from each participant should be sent to the manager of the database (Julien Cohen-Adad). The email should state the following: "I am the subject who volunteered and I give you permission to release the scan freely to the public domain."

Anatomical scans where facial features are visible (T1w) could be "defaced" before being collected (at the discretion of the subject). Because FreeSurfer's `mri_deface` does not work well on those data (which include a big portion of the spine), we recommend to do the defacing manually. It is a very easy procedure that takes less than a minute. To do so, open Fsleyes (as an example, but you could use another MRI editor) and open the T1w scan. Go to **Tools > Edit mode**, Select the pencil with size 100, deface, then save. Below is an example of a defaced subject:

![example_defacing](doc/example_defacing.png)

## Example datasets (WIP)

We provide two example datasets:
- Multi-center, single-subject
- [Multi-center, multi-subjects](https://osf.io/76jkx/)

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

- Download (or `git clone`) this repository.
- Go to this repository: `cd spine_generic`
- Copy the file `parameters_template.sh` and rename it as `parameters.sh`.
- Edit the file `parameters.sh` and modify the variables according to your needs.
- Process data: `./run_process.sh process_data.sh`

## Contributors

[List of contributors for the analysis pipeline.](https://github.com/sct-pipeline/spine_generic/graphs/contributors)

## License

The MIT License (MIT)

Copyright (c) 2018 Polytechnique Montreal, Université de Montréal

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
