Body size pipeline
==================

This pipeline extends the original `Analysis pipeline <https://spine-generic.readthedocs.io/analysis-pipeline.html>`__ and assesses the influence of body size on the structure of the central nervous system. All prerequisities and methods described for the `Analysis pipeline <https://spine-generic.readthedocs.io/analysis-pipeline.html>`__ applies even here with additional required dependencies and methods as described bellow.

This pipeline has been available since the source code release RXYZXXXX (to be edited) and presented in:

Labounek et al. (2022) Body size influences the structure of the central nervous system: a multi-center in vivo human neuroimaging study [Under Review]

Dependencies
------------

MANDATORY:

- For processing: `All Analysis pipeline dependencies <https://spine-generic.readthedocs.io/analysis-pipeline.html#dependencies>`__.
- For generating figures: `YAMLMatlab <https://code.google.com/archive/p/yamlmatlab/downloads>`__ >= 0.4.3; `Matlab <https://www.mathworks.com>`__ >= R2017b (utilized version R2021b; This version automatically aligns axis labels. Lower version will work, but labels can be worse readable.)

OPTIONAL:

- `FSLeyes <https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FSLeyes>`__ for correcting segmentations.
- `FreeSurfer <https://surfer.nmr.mgh.harvard.edu>`__ >=7.2 for segmentation and assessmnet of cerebral morphology from the **T1** scan.

Spinal cord image analysis
--------------------------

The same methods as used in the `Analysis pipeline <https://spine-generic.readthedocs.io/analysis-pipeline.html>`__, i.e sub-sections `Getting started <https://spine-generic.readthedocs.io/analysis-pipeline.html#getting-started>`__ and `Quality Control <https://spine-generic.readthedocs.io/analysis-pipeline.html#quality-control>`__.

Cerebral image analysis
-----------------------

You need to proceed your own automated cerebral segmentation of **T1** scans through the `FreeSurfer >=7.2 <https://surfer.nmr.mgh.harvard.edu>`__ software or download values obtained by the `UMN MILab <https://github.com/umn-milab>`__, which visually inspected and corrected (if necessary) all segmentation outcomes prior to extraction of the quantitative measurements.

Where to download UMN MILab measurements?
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

    git clone https://github.com/umn-milab/spine-generic-body-size-results.git
    cd spine-generic-body-size-results
    cp fs_measurements.xlsx sg.*.aparc.stats.*.csv <PATH_RESULTS>

Your own FreeSurfer segmentation and measurements
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

-   Group ``brain_t1`` in the `exclude.yml <https://github.com/spine-generic/data-multi-subject/blob/master/exclude.yml>`__ file defines list of scans whose cerebral volumes are not possible to be segmented correctly due to listed reasons.
-   You need to build your own ``fs_measurements.xlsx`` table.
-   The bash script `extract_fs_measures.sh <https://github.com/renelabounek/spine-generic/blob/rl/height-weight-analysis/extract_fs_measures.sh>`__ can help you to automatically export the sg.*.aparc.stats.*.csv files.
-   Store all table files in the ``<PATH_RESULTS>`` folder.

Generate figures
----------------

-   Make a copy and re-edit the `spine-generic/matlab/sg_example_script.m <https://github.com/renelabounek/spine-generic/blob/rl/height-weight-analysis/matlab/sg_example_script.m>`__ regarding to your own HDD.
-   Open MATLAB >= R2017b (>= R2021b recomended due to automated axis label orientations)
-   Execute re-edited script or execute following commands with a variable setting fitting your HDD

 .. code-block:: octave
 
    % path to the YAMLMatlab 0.4.3 toolbox
    path_yamltoolbox = '/home/user/toolbox/matlab/YAMLMatlab_0.4.3';
    % path to the spine-generic source code 
    path_spinegeneric = '/home/user/git/spine-generic';
    % path to the <PATH_RESULTS> folder
    path_results = '/home/user/spine-generic/data-multi-subject_results';
    % path to the <PATH_DATA> folder
    path_data = '/home/user/spine-generic/data-multi-subject';
    % Execute
    addpath(path_yamltoolbox);
    addpath(fullfile(path_spinegeneric,'matlab'))
    stat = sg_structure_versus_demography(path_results,path_data);
    % Figures exported in fig_*.png format and stat_labounek2022.mat file
    % will appear in the <PATH_RESULTS> folder

Results
-------

(to be extended once the whole dataset is analyzed)
