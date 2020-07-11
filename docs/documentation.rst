Data collection and organization
================================

The "Spine Generic" MRI acquisition protocol is available at `this
link <http://www.spinalcordmri.org/protocols>`__. Each site was instructed to scan six healthy subjects
(3 men, 3 women), aged between 20 and 40 y.o. Note: there was some
flexibility in terms of number of participants and age range.

If your site is interested in contributing to the publicly-available database, please
coordinate with Julien Cohen-Adad.

Data conversion: DICOM to BIDS
------------------------------

To facilitate the collection, sharing and processing of data, we use the
`BIDS standard <http://bids.neuroimaging.io/>`__. An example of the data
structure for one center is shown below:

::

    data-multi-subject
    │
    ├── dataset_description.json
    ├── participants.json
    ├── participants.tsv
    ├── sub-ubc01
    ├── sub-ubc02
    ├── sub-ubc03
    ├── sub-ubc04
    ├── sub-ubc05
    ├── sub-ubc06
    │   │
    │   ├── anat
    │   │   ├── sub-ubc06_T1w.json
    │   │   ├── sub-ubc06_T1w.nii.gz
    │   │   ├── sub-ubc06_T2star.json
    │   │   ├── sub-ubc06_T2star.nii.gz
    │   │   ├── sub-ubc06_T2w.json
    │   │   ├── sub-ubc06_T2w.nii.gz
    │   │   ├── sub-ubc06_acq-MToff_MTS.json
    │   │   ├── sub-ubc06_acq-MToff_MTS.nii.gz
    │   │   ├── sub-ubc06_acq-MTon_MTS.json
    │   │   ├── sub-ubc06_acq-MTon_MTS.nii.gz
    │   │   ├── sub-ubc06_acq-T1w_MTS.json
    │   │   └── sub-ubc06_acq-T1w_MTS.nii.gz
    │   │
    │   └── dwi
    │       ├── sub-ubc06_dwi.bval
    │       ├── sub-ubc06_dwi.bvec
    │       ├── sub-ubc06_dwi.json
    │       ├── sub-ubc06_dwi.nii.gz
    │       ├── (sub-ubc06_acq-b0_dwi.json)
    │       └── (sub-ubc06_acq-b0_dwi.nii.gz)
    │
    └── derivatives
        │
        └── labels
            └── sub-ubc06
                │
                ├── anat
                │   ├── sub-ubc06_T1w_RPI_r_seg-manual.nii.gz  <---------- manually-corrected spinal cord segmentation
                │   ├── sub-ubc06_T1w_RPI_r_seg-manual.json  <------------ information about origin of segmentation (see below)
                │   ├── sub-ubc06_T1w_RPI_r_labels-manual.nii.gz  <------- manual vertebral labels
                │   ├── sub-ubc06_T1w_RPI_r_labels-manual.json
                │   ├── sub-ubc06_T2w_RPI_r_seg-manual.nii.gz  <---------- manually-corrected spinal cord segmentation
                │   ├── sub-ubc06_T2w_RPI_r_seg-manual.json
                │   ├── sub-ubc06_acq-T1w_MTS_seg-manual.nii.gz  <-------- manually-corrected spinal cord segmentation
                │   ├── sub-ubc06_acq-T1w_MTS_seg-manual.json
                │   ├── sub-ubc06_T2star_rms_gmseg-manual.nii.gz  <------- manually-corrected gray matter segmentation
                │   └── sub-ubc06_T2star_rms_gmseg-manual.json
                │
                └── dwi
                    ├── sub-ubc06_dwi_moco_dwi_mean_seg-manual.nii.gz  <-- manually-corrected spinal cord segmentation
                    └── sub-ubc06_dwi_moco_dwi_mean_seg-manual.json


To convert your DICOM data folder to the compatible BIDS structure, you need to install
`dcm2bids <https://github.com/cbedetti/Dcm2Bids#install>`__. Once
installed, `download this config
file <https://github.com/spine-generic/spine-generic/blob/master/config_spine.txt>`__
(click File>Save to save the file), then convert your Dicom folder using
the following command (replace xx with your center and subject number):

.. code-block:: bash

  dcm2bids -d PATH_TO_DICOM -p sub-ID_SITE -c config_spine.txt -o SITE_spineGeneric

For example:

.. code-block:: bash

  dcm2bids -d /Users/julien/Desktop/DICOM_subj3 -p sub-milan03 -c ~/Desktop/config_spine.txt -o milan_spineGeneric


A log file is generated under ``tmp_dcm2bids/log/``. If you encounter
any problem while running the script, please `open an
issue <https://github.com/spine-generic/spine-generic/issues>`__ and
upload the log file. We will offer support.

Once you have converted all subjects for the study, create the following
files and add them to the data structure:

**dataset\_description.json** (Pick the correct values depending on your
system and environment)

::

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

Example of possible values:

- **Manufacturer**: "Siemens", "GE", "Philips"
- **ManufacturersModelName**: "Prisma", "Prisma-fit", "Skyra", "750w", "Achieva"
- **ReceiveCoilName**: "64ch+spine", "12ch+4ch neck", "neurovascular"
- **SoftwareVersion**: "VE11C", "DV26.0", "R5.3", ...

**participants.json** (This file is generic, you don't need to change
anything there. Just create a new file with this content)

.. code:: json

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

**participants.tsv** (Tab-separated values)

::

    participant_id  sex age date_of_scan    institution_id  institution manufacturer    manufacturers_model_name    receive_coil_name   software_versions   researcher
    sub-unf01   F   24  2018-12-07  unf Neuroimaging Functional Unit (UNF), CRIUGM, Polytechnique Montreal  Siemens Prisma-fit  HeadNeck_64 syngo_MR_E11    J. Cohen-Adad, A. Foias
    sub-unf02   M   29  2018-12-07  unf Neuroimaging Functional Unit (UNF), CRIUGM, Polytechnique Montreal  Siemens Prisma-fit  HeadNeck_64 syngo_MR_E11    J. Cohen-Adad, A. Foias
    sub-unf03   M   22  2018-12-07  unf Neuroimaging Functional Unit (UNF), CRIUGM, Polytechnique Montreal  Siemens Prisma-fit  HeadNeck_64 syngo_MR_E11    J. Cohen-Adad, A. Foias
    sub-unf04   M   31  2018-12-07  unf Neuroimaging Functional Unit (UNF), CRIUGM, Polytechnique Montreal  Siemens Prisma-fit  HeadNeck_64 syngo_MR_E11    J. Cohen-Adad, A. Foias
    sub-unf05   F   23  2019-01-11  unf Neuroimaging Functional Unit (UNF), CRIUGM, Polytechnique Montreal  Siemens Prisma-fit  HeadNeck_64 syngo_MR_E11    J. Cohen-Adad, A. Foias
    sub-unf06   F   27  2019-01-11  unf Neuroimaging Functional Unit (UNF), CRIUGM, Polytechnique Montreal  Siemens Prisma-fit  HeadNeck_64 syngo_MR_E11    J. Cohen-Adad, A. Foias

Once you've created the BIDS dataset, remove any temp folders (e.g.,
``tmp_dcm2bids/``) and zip the entire folder. It is now ready for
sharing! You could send it to Julien Cohen-Adad via any cloud-based
method (Gdrive, Dropbox, etc.).

Ethics and anonymization
------------------------

Each subject consented to be scanned and to have their anonymized data
put in a publicly-available repository. To prove it, an email from each
participant should be sent to the manager of the database (Julien
Cohen-Adad). The email should state the following: "I am the subject who
volunteered and I give you permission to release the scan freely to the
public domain."

Anatomical scans where facial features are visible (T1w) could be
"defaced" before being collected (at the discretion of the subject).

This can be done automatically using R or manually, in case the automatic
defacing fails.


Automatic defacing with R
^^^^^^^^^^^^^^^^^^^^^^^^^

1. Install `R <https://www.r-project.org/>`_, then open R (type "r" in the Terminal) and install the following dependencies:

.. code-block:: R

  install.packages("sessioninfo")
  install.packages("remotes")
  remotes::install_github("muschellij2/oro.nifti")  # answer "Yes" to "install from source?"
  install.packages("fslr")
  install.packages("argparser")
  install.packages("devtools")
  remotes::install_github("muschellij2/extrantsr")  # choose "1" when prompted

2. Download this repository and install Python's dependencies as instructed in `Getting started`_.

3. Run:

.. code-block:: bash

  deface_spineGeneric_usingR -i PATH_TO_BIDS_DATASET -o PATH_TO_DEFACED_BIDS_DATASET -f
  deface_spineGeneric_usingR -i PATH_TO_BIDS_DATASET -o PATH_TO_DEFACED_BIDS_DATASET

4. To launch the QC report of the defacing across multiple subjects, run:

.. code-block:: bash

  python qc_bids_deface.py


Manual Defacing
^^^^^^^^^^^^^^^

Automatic defacing might fail in some subjects, so this section explains how
to deface manually. This procedure takes less than a minute per subject. Here
we use FSLeyes but you can use any other NIfTI image editor.

Open FSLeyes and load the T1w scan. Go to **Tools > Edit mode**, Select
the pencil with size 100, deface, then save.

Below is an example of a defaced subject:

.. figure:: _static/example_defacing.png
   :alt: example\_defacing
   :align: center
   :scale: 70%

   Example of manual defacing.


Multi-center data
-----------------

In the context of this project, the following dataset have been acquired and are
available as open-access:

- `Multi-center, single-subject <https://github.com/spine-generic/data-single-subject>`__
- `Multi-center, multi-subject <https://github.com/spine-generic/data-multi-subject>`__



Analysis pipeline
=================

This repository includes a collection of scripts to analyse BIDS-structured
MRI data and output the following metrics for each contrast:

-  **T1**: Spinal cord CSA averaged between C2 and C3.
-  **T2**: Spinal cord CSA averaged between C2 and C3.
-  **T2s**: Gray matter CSA averaged between C3 and C4.
-  **DWI**: FA in WM averaged between C2 and C5.
-  **MTS**: MTR in WM averaged between C2 and C5. Uses MTon\_MTS and
   MToff\_MTS.
-  **MTS**: MTSat & T1 map in WM averaged between C2 and C5. Uses
   MTon\_MTS, MToff\_MTS and T1w\_MTS.



Dependencies
------------

MANDATORY:

- For processing: `SCT 4.3.0 <https://github.com/neuropoly/spinalcordtoolbox/releases/tag/4.3.0>`__.
- For generating figures: Python >= 3.6

OPTIONAL:

- `FSLeyes <https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FSLeyes>`__ for correcting segmentations.


Getting started
---------------

Download (or ``git clone``) this repository:

.. code-block:: bash

  git clone https://github.com/spine-generic/spine-generic.git

Install Python dependencies:

.. note::
   If you prefer to preserve your default Python's libraries, you could first
   create a `virtual environment <https://docs.python.org/3/tutorial/venv.html>`_,
   and then run the commands below.

.. code-block:: bash

  cd spine-generic
  pip install -e .

Create a folder where results will be generated (feel free to modify the
destination).

.. code-block:: bash

  mkdir ~/spineGeneric_results

Launch processing:

.. code-block:: bash

  sct_run_batch -jobs -1 -path-data ~/data/spineGeneric_6subj/ -path-output ~/spineGeneric_results/ processing/process_data.sh



Quality Control
---------------

After running the analysis, check your Quality Control (QC) report by
opening the file ``qc/index.html``. Use the "Search"
feature of the QC report to quickly jump to segmentations or labeling
results.

Segmentation and vertebral labeling
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you spot segmentation or labeling issues, manually fix them using the procedure described
below. Also see the video tutorial after the procedure.

- Go to the ``results/data`` folder
- In the QC report, enter the string "deepseg" to only display segmentation results or the string "vertebrae" to only
  display vertebral labeling
- Review all spinal cord and gray matter segmentations and vertebral labeling. Use the keyboard shortcuts up/down arrow
  to switch between subjects and the left arrow to toggle overlay.
- If you spot *major* issues with the segmentation (e.g. noticeable leaking or under-segmentation that extends over
  several slices) or wrong labeling, add the image name into the yaml file as in an example below:

.. Hint::
    You can create yaml file easily using your text editor (vim, nano, atom, ...).

::

    FILES_SEG:
    - sub-amu01_T1w_RPI_r.nii.gz
    - sub-amu01_T2w_RPI_r.nii.gz
    - sub-cardiff02_dwi_moco_dwi_mean.nii.gz
    FILES_GMSEG:
    - sub-amu01_T2star_rms.nii.gz
    FILES_LABEL:
    - sub-amu01
    - sub-amu02

(``FILES_SEG`` lists images associated with spinal cord segmentation, ``FILES_GMSEG`` lists images associated with gray
matter segmentation and ``FILES_LABEL`` lists subjects associated with vertebral labeling.)

- If the data quality is too low to be interpreted (too blurry, large artifacts),
  add the image file name to the variable ``TO_EXCLUDE`` in the file ``parameters.sh``,
  which will be used in the next processing iteration.

.. Hint::
   For the interest of time, you don't need to fix *all* slices of the segmentation
   but only the ones listed in the "Relevant levels" column of the table below.

+-------------------------------------------------------+---------------------------------------------------+-----------------+-----------------------+
| Segmentation                                          | Associated image                                  | Relevant levels | Used for              |
+=======================================================+===================================================+=================+=======================+
| sub-XX\_T1w\_RPI\_r\_seg.nii.gz                       | sub-XX\_T1w\_RPI\_r.nii.gz                        | C2-C3           | CSA                   |
+-------------------------------------------------------+---------------------------------------------------+-----------------+-----------------------+
| sub-XX\_T2w\_RPI\_r\_seg.nii.gz                       | sub-XX\_T2w\_RPI\_r.nii.gz                        | C2-C3           | CSA                   |
+-------------------------------------------------------+---------------------------------------------------+-----------------+-----------------------+
| sub-XX\_T2star\_rms\_gmseg.nii.gz                     | sub-XX\_T2star\_rms.nii.gz                        | C3-C4           | CSA                   |
+-------------------------------------------------------+---------------------------------------------------+-----------------+-----------------------+
| sub-XX\_acq-T1w\_MTS\_seg.nii.gz                      | sub-XX\_acq-T1w\_MTS.nii.gz                       | C2-C5           | Template registration |
+-------------------------------------------------------+---------------------------------------------------+-----------------+-----------------------+
| sub-XX\_dwi\_concat\_crop\_moco\_dwi\_mean_seg.nii.gz | sub-XX\_dwi\_concat\_crop\_moco\_dwi\_mean.nii.gz | C2-C5           | Template registration |
+-------------------------------------------------------+---------------------------------------------------+-----------------+-----------------------+

.. raw:: html

   <div style="position: relative; padding-bottom: 5%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
     <iframe width="700" height="394" src="https://www.youtube.com/embed/lB-F8WOHGeg" frameborder="0" allowfullscreen></iframe>


.. raw:: html

   <div style="position: relative; padding-bottom: 5%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
     <iframe width="700" height="394" src="https://www.youtube.com/embed/bX9yWYTipO8" frameborder="0" allowfullscreen></iframe>


- Once you've gone through all the QC, run the ``manual_correction.py`` script, as in an example below:

.. code-block:: bash

    manual_correction.py -config files.yaml -path-in ~/spine-generic/results/data -path-out ~/data-spine-generic

- ``manual_correction.py`` script saves manually corrected files under derivatives/ folder (BIDS standard).



Re-run the analysis
^^^^^^^^^^^^^^^^^^^

After you have corrected all the necessary segmentations/labels, you can re-run
the entire analysis. If the manually-corrected file exists, the script will use it in the
processing instead of re-creating a new one. In order to account for the
manually-corrected files, make sure to add the flag `-path-segmanual`. Example:

.. code-block:: bash

  sct_run_batch -jobs -1 -path-data ~/data/spineGeneric_6subj -path-output ~/spineGeneric_results_new -path-segmanual ~/spineGeneric_results_new/seg_manual processing/process_data.sh


Generate figures
----------------

Generate figures based on the output csv files. Figures will be created in the
folder `results/`:

.. code-block:: bash

  generate_figures parameters.sh



Contributors
------------

A list of contributors for the analysis pipeline is available `here <https://github.com/spine-generic/spine-generic/graphs/contributors>`__.
If you would like to contribute to this project, please see `contribution guidelines <https://github.com/spine-generic/spine-generic/blob/master/CONTRIBUTING.md>`_.



License
-------

.. include:: ../LICENSE
