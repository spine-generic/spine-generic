# spine_generic

Processing pipeline for the "spine generic protocol" project 

The following metrics are output (per contrast):
- t1: Spinal cord CSA profile between C2 and Th1, averaged within each level
- t2: Spinal cord CSA profile between C2 and Th1, averaged within each level
- t2s: Gray matter CSA profile between C3 and C4, averaged within each level
- dmri: FA in WM across slices
- mt: MTR in WM across slices
- mt: MTsat in WM across slices

## Dependencies

[SCT v3.2.0](https://github.com/neuropoly/spinalcordtoolbox/releases/tag/v3.2.0) or above.


## File structure

To facilitate the collection of data, we used the [BIDS standard](http://bids.neuroimaging.io/). Each proprietary Dicom data should be converted to NIFTI format using [dcm2niix](https://www.nitrc.org/plugins/mwiki/index.php/dcm2nii:MainPage) with option to output JSON file alongside each NIFTI file. Each participant is expected to provide a zip file containing the following data:

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
             └── sub-01_acq-ax_MT.nii.gz
             └── sub-01_acq-ax_MT.json
             └── sub-01_acq-ax_PD.nii.gz
             └── sub-01_acq-ax_PD.json
             └── sub-01_acq-ax_T1w.nii.gz
             └── sub-01_acq-ax_T1w.json
             └── sub-01_acq-ax_T2star.nii.gz
             └── sub-01_acq-ax_T2star.json
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
	"SoftwareVersion": "Version of MR software",  # Examples: "VE11C", "
	"Researcher": "Researchers who contributed to the dataset"  # Initial and Family name. Separate with ",". Examples: "J. Doe, S. Wonder, J. Pass"
}
```

### participants.tsv

|participant_id|sex|age|date_of_scan|
| --- | --- | --- | --- |
|sub-01|M|35|2018-12-18|

### sub-XX_contrast.json
Where contrast={"T1w", "T2w", "T2star", "dwi", "MT", "PD"}
Note, the fields listed below are the mandatory fields. It is fine to have more fields. E.g., if you use `dcm2niix` you will likely have more entries.
```
{
	"FlipAngle": 90,  # in deg
	"EchoTime": 0.06,  # in s
	"RepetitionTime": 0.61,  # in s
	"PhaseEncodingDirection": "j-",
	"ConversionSoftware": "dcm2niix",
	"ConversionSoftwareVersion": "v1.0.20170130 (openJPEG build)",
}
```

## How to run

- Download (or `git clone`) this repository.
- Go to this repository: `cd spine_generic`
- Export environment variable: ``` export PATH_SPINEGENERIC=`pwd` ```
- Go to a subject data (e.g. cd PATH_TO_DATA/001)
- Process data: `${PATH_SPINEGENERIC}/process_data.sh`
- Compute metrics: `${PATH_SPINEGENERIC}/compute_metrics.sh`

## Contributors

Stephanie Alley, Julien Cohen-Adad

## License

The MIT License (MIT)

Copyright (c) 2018 Polytechnique Montreal, Université de Montréal

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
