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

To facilitate the collection of data, we used the [BIDS standard](http://bids.neuroimaging.io/). Each proprietary Dicom data were converted to NIFTI format using [dcm2niix](https://www.nitrc.org/plugins/mwiki/index.php/dcm2nii:MainPage) with option to output JSON file alongside each NIFTI file. 

**BIDS-compatible data structure:**
~~~
center_study/
└── dataset_description.json
└── participants.json
└── participants.tsv
└── sub-01
    └── anat
             └── sub-01_T1w.json
             └── sub-01_T1w.nii.gz
             └── sub-01_acq-ax_T2w.json
             └── sub-01_acq-ax_T2w.nii.gz
             └── sub-01_acq-inf_T2w.json
             └── sub-01_acq-inf_T2w.nii.gz
             └── sub-01_acq-sag_T2w.json
             └── sub-01_acq-sag_T2w.nii.gz
             └── sub-01_acq-sup_T2w.json
             └── sub-01_acq-sup_T2w.nii.gz
             └── sub-01_T2star.json
             └── sub-01_T2star.nii.gz
    └── dwi
             └── sub-01_dwi.bval
             └── sub-01_dwi.bvec
             └── sub-01_dwi.json
             └── sub-01_dwi.nii.gz
~~~
**dataset_description.json:**
```json
{
"Name": "SCT dataset",
"BIDSVersion": "1.0.1",
"InstitutionName" : "name_of_the_institution" ,
"Manufacturer" : "scanner_model" ,
"Study" : "name_of_the_study" ,
"Researcher": "name_of_the_researcher"
}
```
### participants.json
```json
{
    "participant_id": {
        "LongName": "Participant ID",
        "Description": "Unique ID corresponding to the Subject number"
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
    },
}
```

### participants.tsv

|participant_id|sex|age|date_of_scan|surname|family_name|pathology|data_id|
| --- | --- | --- | --- | --- | --- | --- | --- |
|sub-01|M|-|2013-03-18|John|Doe|HC|amu_2017-virginie_AS|

### sub-XXX__contrast.json
```
{
	"Manufacturer": "Siemens",
	"ManufacturersModelName": "Prisma_fit",
	"ProcedureStepDescription": "spine_generic",
	"ProtocolName": "DWI",
	"ImageType": ["ORIGINAL", "PRIMARY", "DIFFUSION", "NONE", "ND", "MOSA"],
	"AcquisitionDateTime": "2017-10-27T10:27:9.632812",
	"MagneticFieldStrength": 3,
	"FlipAngle": 90,
	"EchoTime": 0.06,
	"RepetitionTime": 0.61,
	"EffectiveEchoSpacing": 0.000939994,
	"PhaseEncodingDirection": "j-",
	"ConversionSoftware": "dcm2niix",
	"ConversionSoftwareVersion": "v1.0.20170130 (openJPEG build)",
}
```

where 

- contrast= ["T1w", "T2w", "T2star", "dwi", "fmri", "T1rho", "T1map", "T2map", "FLAIR", "FLASH", "PD", "PDmap", "PDT2", "inplaneT1", "inplaneT2"]


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

Copyright (c) 2018 École Polytechnique, Université de Montréal

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
