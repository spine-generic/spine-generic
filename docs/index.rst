Generic Acquisition, Database and Analysis Protocol for Quantitative MRI of the Spinal Cord
===========================================================================================

.. image:: _static/logo_spinegeneric.png
   :scale: 50 %
   :alt: alternate text
   :align: center

Quantitative spinal cord MRI is fraught with a number of challenges, among which is the lack of standardized imaging protocols. Here we present quantitative MRI protocols (which, collectively, we refer to as the "spine generic protocol") for the three main MRI vendors (GE, Philips and Siemens), that provide valuable metrics for assessing spinal cord macrostructural and microstructural integrity: T1w and T2w imaging for SC cross-sectional area (CSA) computation, multi-echo gradient echo for gray matter CSA, as well as magnetization transfer and diffusion weighted imaging for assessing white matter microstructure. The spine generic protocol was used in a single-subject reproducibility study across 19+ centers (spanning all three vendors) and in multiple subjects across 42+ centers. 

The protocols and datasets are open-access and the data analysis code is open-source. Full documentation, including a description of the processing pipeline with detailed text and video instructions can be found in this website. 

The main publications for this project are:

- Cohen-Adad et al. *Generic acquisition protocol for quantitative MRI of the spinal cord*. **Nature Protocols** 2021 (doi: 10.1038/s41596-021-00588-0). `📥 ‎ PDF <https://github.com/spine-generic/protocols/blob/main/CohenAdad21_NatureProtocols.pdf>`_
- Cohen-Adad et al. *Open-access quantitative MRI data of the spinal cord and reproducibility across participants, sites and manufacturers*. **Scientific Data** 2021 (doi: 10.1038/s41597-021-01026-2). `📥 ‎ PDF <https://www.nature.com/articles/s41597-021-00941-8.pdf>`_

.. toctree::
   :name: mastertoc
   :caption: Table of contents
   :maxdepth: 2

   data-acquisition.rst
   analysis-pipeline.rst


Contributors
------------

A list of contributors for the analysis pipeline is available `here <https://github.com/spine-generic/spine-generic/graphs/contributors>`__.
If you would like to contribute to this project, please see `contribution guidelines <https://github.com/spine-generic/spine-generic/blob/master/CONTRIBUTING.md>`_.


License
-------

.. include:: ../LICENSE
