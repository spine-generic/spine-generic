# spine_generic

Processing pipeline for the "spine generic protocol" project 

The following metrics are output (per contrast):
- T1: CSA profile between C2 and Th1
- T2: CSA profile between C2 and Th1


## Dependencies

[SCT v3.2.0](https://github.com/neuropoly/spinalcordtoolbox/releases/tag/v3.2.0) or above.


## File structure

~~~
data
  |- 001
  |- 002
  |- 003
      |- t1
        |- t1.nii.gz
      |- t2
        |- t2.nii.gz
      |- t2s
        |- t2s.nii.gz
      |- mt
	    |- mt1.nii.gz
        |- mt0.nii.gz
        |- t1w.nii.gz
      |- dmri
        |- dmri.nii.gz
        |- bvecs.txt
        |- bvals.txt
~~~

## How to run

- Download (or `git clone`) this repository.
- Go to this repository: `cd spine_generic`
- Export environment variable: ``export PATH_SPINEGENERIC=`pwd```
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
