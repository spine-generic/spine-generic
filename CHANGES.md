## v2.2 (2020-08-17)
[View detailed changelog](https://github.com/spine-generic/spine-generic/compare/v2.1.1...v2.2)

**BUG**

 - Fix issue when generating fig_t1_t2_agreement figures.  [View pull request](https://github.com/spine-generic/spine-generic/pull/161)
 - Fixed missing '-manual' after _seg suffix for manual corrs.  [View pull request](https://github.com/spine-generic/spine-generic/pull/133)

**ENHANCEMENT**

 - Use subprocess.run.  [View pull request](https://github.com/spine-generic/spine-generic/pull/174)
 - Use importlib.resources to access spinegeneric/flags/*.png.  [View pull request](https://github.com/spine-generic/spine-generic/pull/173)
 - Distribute packages properly.  [View pull request](https://github.com/spine-generic/spine-generic/pull/172)
 - Implement CI for checking data consistency.  [View pull request](https://github.com/spine-generic/spine-generic/pull/171)
 - Fix generate figure.  [View pull request](https://github.com/spine-generic/spine-generic/pull/167)
 - Fix superscript for MD and RD ylabel and remove a.u. unit for MTsat.  [View pull request](https://github.com/spine-generic/spine-generic/pull/164)
 - Improve qc defacing.  [View pull request](https://github.com/spine-generic/spine-generic/pull/162)
 - Added flag -qc-only; Major refactoring to simplify code.  [View pull request](https://github.com/spine-generic/spine-generic/pull/160)
 - Improve sg_manual_correction.  [View pull request](https://github.com/spine-generic/spine-generic/pull/158)
 - Exclude sub-mountSinai03 from some analyses.  [View pull request](https://github.com/spine-generic/spine-generic/pull/156)
 - Changed slicereg to centermass for DWI registration.  [View pull request](https://github.com/spine-generic/spine-generic/pull/154)
 - Improve sg_package_for_correction.  [View pull request](https://github.com/spine-generic/spine-generic/pull/149)
 - Update flags dict.  [View pull request](https://github.com/spine-generic/spine-generic/pull/147)
 - Generate QC report for manual corrections.  [View pull request](https://github.com/spine-generic/spine-generic/pull/146)
 - Create json sidecar.  [View pull request](https://github.com/spine-generic/spine-generic/pull/144)
 - Adding new function sg_params_checker to check acquisition parameters; Include it in CI.  [View pull request](https://github.com/spine-generic/spine-generic/pull/134)
 - Added spinegeneric in path for import.  [View pull request](https://github.com/spine-generic/spine-generic/pull/132)
 - New script to package data awaiting correction.  [View pull request](https://github.com/spine-generic/spine-generic/pull/129)
 - Fix help in manual_correction.py; file name instead of sub ID for labeling.  [View pull request](https://github.com/spine-generic/spine-generic/pull/127)
 - Convert to proper Python package.  [View pull request](https://github.com/spine-generic/spine-generic/pull/121)
 - Adding script to copy label file into derivatives/labels/sub-XXX/anat.  [View pull request](https://github.com/spine-generic/spine-generic/pull/118)
 - Ensures reproducible pipeline across OSs; various improvements.  [View pull request](https://github.com/spine-generic/spine-generic/pull/115)
 - Check if file exists before copying.  [View pull request](https://github.com/spine-generic/spine-generic/pull/109)
 - New script to copy manual corrections under derivatives/.  [View pull request](https://github.com/spine-generic/spine-generic/pull/106)
 - Look for manual files under derivatives/.  [View pull request](https://github.com/spine-generic/spine-generic/pull/104)
 - manual_correction.py script.  [View pull request](https://github.com/spine-generic/spine-generic/pull/103)

**DOCUMENTATION**

 - Documentation updates.  [View pull request](https://github.com/spine-generic/spine-generic/pull/122)
 - switch from relative to absolute links in documentation.  [View pull request](https://github.com/spine-generic/spine-generic/pull/102)
