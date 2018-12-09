# spine_generic

Processing pipeline for the "spine generic protocol" project

The following metrics are output (per contrast):
- **T1**: Spinal cord CSA averaged between C2 and C3.
- **T2**: Spinal cord CSA averaged between C2 and C3.
- **T2s**: Gray matter CSA averaged between C3 and C4.
- **DWI**: FA in WM averaged between C2 and C5.
- **MTS**: MTR in WM averaged between C2 and C5. Uses MTon_MTS and MToff_MTS.
- **MTS**: MTS in WM averaged between C2 and C5. Uses MTon_MTS, MToff_MTS and T1w_MTS.

## Dependencies

In its current state, this pipeline uses [SCT development version](https://github.com/neuropoly/spinalcordtoolbox#install-from-github-development). Once the pipeline is finalized, a stable version of SCT will be associated with this pipeline and indicated here. For now, please use the latest development version of SCT.

This pipeline also relies on [FSLeyes](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FSLeyes) for quality control (QC).

## Data collection and organization

To facilitate the collection of data, we use the [BIDS standard](http://bids.neuroimaging.io/). Each proprietary DICOM data should be converted to NIFTI format using [dcm2niix](https://www.nitrc.org/plugins/mwiki/index.php/dcm2nii:MainPage) with option to output JSON file alongside each NIFTI file. Each participant is expected to provide a zip file containing the following data:

### BIDS-compatible data structure
~~~
site/
└── dataset_description.json
└── participants.tsv
└── sub-01
    └── anat
             └── sub-01_T1w.nii.gz
             └── sub-01_T1w.json
             └── sub-01_T2w.nii.gz
             └── sub-01_T2w.json
             └── sub-01_acq-MTon_MTS.nii.gz
             └── sub-01_acq-MTon_MTS.json
             └── sub-01_acq-MToff_MTS.nii.gz
             └── sub-01_acq-MToff_MTS.json
             └── sub-01_acq-T1w_MTS.nii.gz
             └── sub-01_acq-T1w_MTS.json
             └── sub-01_T2star.nii.gz
             └── sub-01_T2star.json
    └── dwi
             └── sub-01_dwi.nii.gz
             └── sub-01_dwi.bval
             └── sub-01_dwi.bvec
             └── sub-01_dwi.json
~~~
### dataset_description.json
```
{
	"Name": "Spinal Cord MRI Public Database",
	"BIDSVersion": "1.0.1",
	"InstitutionName": "Name of the institution",
	"Manufacturer": "Scanner brand, model",  # Examples: "Siemens, Prisma", "Philips, Achieva"
	"Coil": "Coil used", # Examples: 64ch+spine, 12ch+4ch neck, neurovascular, etc.
	"SoftwareVersion": "Version of MR software",  # Examples: "VE11C", "
	"Researcher": "Researchers who contributed to the dataset"  # Initial and Family name. Separate with ",". Examples: "J. Doe, S. Wonder, J. Pass"
}
```

### participants.tsv

~~~
id	sex	age	date_of_scan
sub-01	M	35	2018-12-18
sub-02	F	30	2018-11-01
~~~

### sub-XX_contrast.json

Where contrast={"T1w", "T2w", "T2star", "dwi", "MT", "PD"}
Note, the fields listed below are the mandatory fields. It is fine to have more fields. E.g., if you use `dcm2niix` you will likely have more entries. EchoTime and RepetitionTime are in seconds.
```
{
	"FlipAngle": 90,
	"EchoTime": 0.06,
	"RepetitionTime": 0.61,
	"PhaseEncodingDirection": "j-",
	"ConversionSoftware": "dcm2niix",
	"ConversionSoftwareVersion": "v1.0.20170130 (openJPEG build)",
}
```

### Ethics and anonymization

Each subject consented to be scanned and to have their anonymized data put in a publicly-available repository. To prove it, an email from each participant should be sent to the manager of the database (Julien Cohen-Adad). The email should state the following: "I am the subject who volunteered and I give you permission to release the scan freely to the public domain."

Anatomical scans where facial features are visible (T1w) should be "defaced" before being collected. To do so, [FreeSurfer's mri_deface](https://surfer.nmr.mgh.harvard.edu/fswiki/mri_deface ) could be used.

## Example datasets (WIP)

We provide two example datasets:
- Multi-center, single-subject
- [Multi-center, multi-subjects](https://osf.io/jkxzp/)

## How to run

- Download (or `git clone`) this repository.
- Go to this repository: `cd spine_generic`
- Copy the file `parameters_template.sh` and rename it as `parameters.sh`.
- Edit the file `parameters.sh` and modify the variables according to your needs.
- Process data: `./run_process.sh process_data.sh`

## Contributors

[List of contributors](https://github.com/sct-pipeline/spine_generic/graphs/contributors)

## License

The MIT License (MIT)

Copyright (c) 2018 Polytechnique Montreal, Université de Montréal

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
