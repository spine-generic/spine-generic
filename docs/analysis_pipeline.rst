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


.. _getting-started:

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

  sct_run_batch -jobs -1 -path-data <PATH_TO_DATA> -path-output ~/spineGeneric_results/ process_data.sh


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

- Go to the ``results/data`` folder.
- In the QC report, enter the string "deepseg" to only display segmentation results or the string "vertebrae" to only
  display vertebral labeling.
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
    - sub-amu01_T1w_RPI_r.nii.gz
    - sub-amu02_T1w_RPI_r.nii.gz

(``FILES_SEG`` lists images associated with spinal cord segmentation, ``FILES_GMSEG`` lists images associated with gray
matter segmentation and ``FILES_LABEL`` lists images that vertebral labeling is done on.)

- If the data quality is too low to be interpreted (too blurry, large artifacts), exclude subject from processing by
  passing ``-exclude-list`` in ``sct_run_batch`` script.

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


- Once you finished the QC, run the ``sg_manual_correction.py`` script, as in the example below:

.. code-block:: bash

    sg_manual_correction.py -config files.yaml -path-in ~/spine-generic/results/data -path-out ~/data-spine-generic

- ``sg_manual_correction.py`` script saves manually-corrected files under ``derivatives/labels/`` folder, according to the BIDS convention.



Re-run the analysis
^^^^^^^^^^^^^^^^^^^

After you have corrected all the necessary segmentations/labels, you can re-run
the entire analysis. If the manually-corrected file exists, the script will use it in the
processing instead of re-creating a new one. In order to account for the
manually-corrected files, make sure to add the flag `-path-segmanual`. Example:

.. code-block:: bash

  sct_run_batch -jobs -1 -path-data ~/data/spineGeneric_6subj -path-output ~/spineGeneric_results_new -path-segmanual ~/spineGeneric_results_new/seg_manual process_data.sh


Generate figures
----------------

Generate figures based on the output csv files using ``sg_generate_figures.py`` script. Run this script in ``/results``
folder (folder containing csv files) or specify this folder using ``-path-results`` flag. Figures will be created in the
folder `results/`:

.. code-block:: bash

  sg_generate_figures.py


or

.. code-block:: bash

  sg_generate_figures.py -path-results ~/spineGeneric_results_new/results
