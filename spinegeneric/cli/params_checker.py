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
        description="Acquisition parameters checker feature. This feature allows the users"
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

    path_warning_log = os.path.join(data_path, "WARNING.log")
    if os.path.isfile(path_warning_log):
        os.remove(path_warning_log)
    logging.basicConfig(
        filename=path_warning_log,
        format="%(levelname)s:%(message)s",
        level=logging.DEBUG,
    )

    # Initialize the layout
    with importlib.resources.path(spinegeneric.config, "bids_specs.json") as path_sg_layout_config:
        layout = BIDSLayout(
            data_path,
            indexer=BIDSLayoutIndexer(config_filename=path_sg_layout_config),
            validate=False,
        )

    query = layout.get(suffix=["T1w", "T2w", "T2star", "MTS"], extension="nii.gz")

    with importlib.resources.path(spinegeneric.config, "specs.json") as path_specs:
        with open(path_specs) as json_file:
            data = json.load(json_file)

    # Loop across the contrast images to check parameters
    for item in query:
        if "Manufacturer" not in item.get_metadata():
            logging.warning(f" {item.filename}: Missing Manufacturer in json sidecar; Cannot check parameters.")
            continue
        Manufacturer = item.get_metadata()["Manufacturer"]
        if Manufacturer not in data.keys():
            logging.warning(f" {item.filename}: Manufacturer '{Manufacturer}' not in list "
                            f"of known manufacturers: {data.keys()}. Cannot check parameters.")
            continue
        ManufacturersModelName = item.get_metadata()["ManufacturersModelName"]
        if ManufacturersModelName not in data[Manufacturer].keys():
            logging.warning(f" {item.filename}: Missing: {ManufacturersModelName}; Cannot check parameters.")
            continue

        Contrast = (item.filename.split("_")[-1]).split(".")[0]
        if Contrast == "MTS":
            MTS_acq = item.filename.split("_acq-")[1].split(".")[0]
            Contrast = MTS_acq
        keys_contrast = data[Manufacturer][ManufacturersModelName][
            str(Contrast)
        ].keys()

        # Validate repetition time against manufacturer's specifications
        RepetitionTime = item.get_metadata()["RepetitionTime"]
        if "RepetitionTime" in keys_contrast:
            ExpectedRT = data[Manufacturer][ManufacturersModelName][str(Contrast)]["RepetitionTime"]
            if RepetitionTime - ExpectedRT > 0.1:
                logging.warning(f" {item.filename}: Incorrect RepetitionTime: "
                                f"TR={RepetitionTime} instead of {ExpectedRT}.")

        # Validate echo time against manufacturer's specifications
        EchoTime = item.get_metadata()["EchoTime"]
        if "EchoTime" in keys_contrast:
            ExpectedTE = data[Manufacturer][ManufacturersModelName][str(Contrast)]["EchoTime"]
            if EchoTime - ExpectedTE > 0.1:
                logging.warning(f" {item.filename}: Incorrect EchoTime: "
                                f"TE={EchoTime} instead of {ExpectedTE}.")

        # Validate flip angle against manufacturer's specifications
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
