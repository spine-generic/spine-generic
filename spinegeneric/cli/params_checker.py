#!/usr/bin/env python
#
# Script to check acquisition parameters.
#
# For usage, type: sg_params_checker -h
#
# Authors: Alexandru Foias, Julien Cohen-Adad

import os
import json
import logging
import argparse
import importlib.resources

from bids import BIDSLayout, BIDSLayoutIndexer

import spinegeneric as sg
import spinegeneric.cli
import spinegeneric.utils
import spinegeneric.config


def get_parser():
    parser = argparse.ArgumentParser(
        description="Acquisition parameters checker feature. This feature allows the users "
                    "to compare the acquisition parameters that can be found in the json "
                    "sidecar to the recommended acquisition parameters.",
        formatter_class=sg.utils.SmartFormatter,
        prog=os.path.basename(__file__).strip(".py"),
    )
    parser.add_argument(
        "-path-in",
        required=True,
        type=str,
        help="Path to input BIDS dataset, which contains all the 'sub-' folders.",
    )
    return parser


def main():
    # Parse input arguments
    parser = get_parser()
    args = parser.parse_args()
    data_path = args.path_in

    # Initialize logging
    path_warning_log = os.path.join(data_path, "WARNING.log")
    if os.path.isfile(path_warning_log):
        os.remove(path_warning_log)
    logging.basicConfig(
        filename=path_warning_log,
        format="%(levelname)s:%(message)s",
        level=logging.DEBUG,
    )

    # Initialize the BIDSLayout object directed at the input dataset.
    # From the BIDS documentation:
    #   "A BIDSLayout instance is a lightweight container for all files in the BIDS project directory."
    with importlib.resources.path(spinegeneric.config, "bids_specs.json") as path_sg_layout_config:
        # TODO: This step takes quite a long time, but nothing gets logged during. Maybe we could provide some feedback?
        layout = BIDSLayout(
            data_path,
            # BIDSLayoutIndexer is a class that indexes files based on pattern-matching defined in the config.
            # By default, BIDS has its own config. But, SG specifies its own custom config instead. (Why?)
            # TODO: The default config fetches 1573 files from data-multi-subject, but the modified config
            #       *also* fetches 1573 files. Do they always perform identically? In what cases is the custom
            #       config even needed? It would be nice to add comments to `bids_specs.json` to highlight the
            #       areas where the custom config deviates from the built-in, default config.
            indexer=BIDSLayoutIndexer(config_filename=str(path_sg_layout_config)),
            # From BIDS documentation for `validate`:
            #     > If True, all files are checked for BIDS compliance when first indexed,
            #     > and non-compliant files are ignored. This provides a convenient way to
            #     > restrict file indexing to only those files defined in the “core” BIDS spec,
            #     > as setting validate=True will lead files in supplementary folders like
            #     > derivatives/, code/, etc. to be ignored.
            # I presume that by setting `validate=False`, we want to keep `derivatives/`, etc.
            validate=False,
        )

    # Fetch a list of `BIDSImageFile` objects from the layout that meet the requirements below
    query = layout.get(suffix=["T1w", "T2w", "T2star", "MTS"], extension="nii.gz")

    # Fetch acquisition parameters for various vendors (Siemens, GE, Phillips) and MRI models
    with importlib.resources.path(spinegeneric.config, "specs.json") as path_specs:
        with open(path_specs) as json_file:
            data = json.load(json_file)  # TODO: We could probably be more descriptive with this filename?

    # Loop across the contrast images to check parameters
    for item in query:
        # Check that the json sidecar has the correct keys and values
        if "Manufacturer" not in item.get_metadata():
            logging.warning(f" {item.filename}: Missing 'Manufacturer' key in json sidecar; Cannot check parameters.")
            continue
        Manufacturer = item.get_metadata()["Manufacturer"]
        if Manufacturer not in data.keys():
            logging.warning(f" {item.filename}: Manufacturer '{Manufacturer}' not in list "
                            f"of known manufacturers: {data.keys()}. Cannot check parameters.")
            continue
        ManufacturersModelName = item.get_metadata()["ManufacturersModelName"]
        if ManufacturersModelName not in data[Manufacturer].keys():
            logging.warning(f" {item.filename}: Model '{ManufacturersModelName}' not present in list of known "
                            f"models for manufacturer '{Manufacturer}'. Cannot check parameters.")
            continue

        # Parse the file's contrast from its suffix (sans `.nii.gz`)
        Contrast = (item.filename.split("_")[-1]).split(".")[0]
        # In the case of MTS files, the spine-generic protocol doesn't just specify 'MTS'. Instead, 'MTon_MTS',
        # 'MToff_MTS', 'T1w_MTS' etc. are used. So, we need to parse the type of MTS from the filename,
        # then convert it to the specific names expected by the 'manufacturer params' dictionary.
        if Contrast == "MTS":
            # TODO: The manufacturer param dicts specifically contains the key "T1w_MTS", but I can't
            #       find a single file in `data-multi-subject` that is MTS + T1w. Instead, all I see are
            #       'mt-off' and 'mt-on'. So, this new method for parsing filenames passes for
            #       data-multi-subject, but may fail for "T1w_MTS" data, if such data even exists?
            try:
                # Try new method for renamed, BIDS-compliant 'data-multi-subject'
                MTS_acq = item.filename.split('_')[-2]
                Contrast = {'mt-off': "MToff_MTS", 'mt-on': "MTon_MTS"}[MTS_acq]
            except KeyError:
                # Fall back to the old method for backwards compatibility with older datasets
                Contrast = item.filename.split("_acq-")[1].split(".")[0]

        # Fetch the names of each available parameter for the given manufacturer + model
        keys_contrast = data[Manufacturer][ManufacturersModelName][str(Contrast)].keys()

        # Validate repetition time against spine-generic's acquisition protocol
        RepetitionTime = item.get_metadata()["RepetitionTime"]
        if "RepetitionTime" in keys_contrast:
            ExpectedRT = data[Manufacturer][ManufacturersModelName][str(Contrast)]["RepetitionTime"]
            # TODO: We check against at threshold here, rather than FA, which checks for exactness. Do we want this?
            if RepetitionTime - ExpectedRT > 0.1:
                logging.warning(f" {item.filename}: Incorrect RepetitionTime: "
                                f"TR={RepetitionTime} instead of {ExpectedRT} +/- 0.1.")

        # Validate echo time against spine-generic's acquisition protocol
        EchoTime = item.get_metadata()["EchoTime"]
        if "EchoTime" in keys_contrast:
            ExpectedTE = data[Manufacturer][ManufacturersModelName][str(Contrast)]["EchoTime"]
            # TODO: We check against at threshold here, rather than FA, which checks for exactness. Do we want this?
            if EchoTime - ExpectedTE > 0.1:
                logging.warning(f" {item.filename}: Incorrect EchoTime: "
                                f"TE={EchoTime} instead of {ExpectedTE} +/- 0.1.")

        # Validate flip angle against spine-generic's acquisition protocol
        FlipAngle = item.get_metadata()["FlipAngle"]
        if "FlipAngle" in keys_contrast:
            ExpectedFA = data[Manufacturer][ManufacturersModelName][str(Contrast)]["FlipAngle"]
            if FlipAngle != ExpectedFA:
                logging.warning(f" {item.filename}: Incorrect FlipAngle: "
                                f"FA={FlipAngle} instead of {ExpectedFA}.")

    # Print WARNING log
    if path_warning_log:
        file = open(path_warning_log, "r")
        lines = file.read().splitlines()
        file.close()
        for line in lines:
            print(line)


if __name__ == "__main__":
    main()
