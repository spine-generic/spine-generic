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

  sct_run_batch -jobs -1 -path-data <PATH_DATA> -path-output ~/spineGeneric_results/ process_data.sh

.. note::

   ``<PATH_DATA>`` points to a BIDS-compatible dataset. E.g., you could use one of the dataset
   listed in :ref:`multi-center-data`


Quality Control
---------------

After running the analysis, check your Quality Control (QC) report by
opening the file ``~/spineGeneric_results/qc/index.html``. Use the "Search"
feature of the QC report to quickly jump to segmentations or labeling
results.

Segmentation and vertebral labeling
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you spot segmentation or labeling issues, manually fix them using the procedure described
below. Also see the video tutorial below.

- Create a .yml file that lists the data awating manual correction. You can create this file using any text editor (vim, nano, atom, etc.).
- In the QC report, enter the string "deepseg" to only display segmentation results or the string "vertebrae" to only
  display vertebral labeling.
- Review all spinal cord and gray matter segmentations and vertebral labeling. Use the keyboard shortcuts up/down arrow
  to switch between subjects and the left arrow to toggle overlay.
- If you spot *major* issues with the segmentation (e.g. noticeable leaking or under-segmentation that extends over
  several slices) or wrong labeling, add the image name into the yml file as in the example below:

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

Some explanations about this yml file:

- ``FILES_SEG``: Images associated with spinal cord segmentation
- ``FILES_GMSEG``: Images associated with gray matter segmentation
- ``FILES_LABEL``: Images associated with vertebral labeling

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


- After you finished the QC, run ``sg_manual_correction`` as in the example below:

.. code-block:: bash

    sg_manual_correction -config files.yml -path-in ~/spineGeneric_results/results/data -path-out <PATH_DATA>

This script will loop through all the files that need correction (as per the .yml file that you created earlier),
and open an interactive window for you to either correct the segmentation, or perform manual labels. Each
manually-corrected label is saved under the ``derivatives/labels/`` folder at the root of ``<PATH_DATA>``,
according to the BIDS convention. The manually-corrected label files have the suffix ``-manual``.

Your name will be asked at the beginning, and will be recorded in the .json files that accompany the corrected labels.

Upload the manually-corrected files
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

A QC report of all the manual corrections will be created locally and archived as a zip file. To update the
database with the manual corrections, follow this procedure:

- Commit and push the manually-corrected files, which should be placed in the appropriate folders under ``derivatives/labels/``
- Create a pull request
- In the pull request body, briefly explain the purpose of these changes, and upload the zipped QC report so the admin team can easily review the proposed changes. 
- If the team accepts the pull request, a new release of the dataset will be created and the zipped QC report will be uploaded as a release object.

.. note::

   In case processing is ran on a remote cluster, it it convenient to generate a package of the files that need
   correction to be able to only copy these files locally, instead of copying the ~20GB of total processed files.
   If you are in this situation, use the script ``package_for_correction``.


Re-run the analysis
^^^^^^^^^^^^^^^^^^^

After you have corrected all the necessary segmentations/labels, you can re-run
the analysis (the ``sct_run_batch`` command above). If a manually-corrected file exists, it will be used
instead of re-creating a new one automatically.

.. Warning::

   If you re-run the analysis, make sure to output results in another folder (flag ``-path-output``), otherwise the
   previous analysis will be overwritten.


Generate figures
----------------

Generate figures based on the output csv files using ``sg_generate_figures.py`` script. Run this script in ``/results``
folder (folder containing csv files) or specify this folder using ``-path-results`` flag. Figures will be created in the
folder `results/`:

.. code-block:: bash

  sg_generate_figures -path-results ~/spineGeneric_results/results
