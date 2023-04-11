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

    Contrast_list = ["T1w", "T2w", "T2star", "MTS"]
    query = layout.get(suffix=Contrast_list, extension="nii.gz")

    with importlib.resources.path(spinegeneric.config, "specs.json") as path_specs:
        with open(path_specs) as json_file:
            data = json.load(json_file)

    # Loop across the contrast images to check parameters
    for item in query:
        if "Manufacturer" not in item.get_metadata():
            logging.warning(f" {item.filename}: Missing Manufacturer in json sidecar; Cannot check parameters.")
        else:
            Manufacturer = item.get_metadata()["Manufacturer"]
            if Manufacturer not in data.keys():
                logging.warning(f" {item.filename}: Manufacturer '{Manufacturer}' not in list "
                                f"of known manufacturers: {data.keys()}. Cannot check parameters.")
            else:
                ManufacturersModelName = item.get_metadata()["ManufacturersModelName"]
                if ManufacturersModelName not in data[Manufacturer].keys():
                    logging.warning(f" {item.filename}: Missing: {ManufacturersModelName}; Cannot check parameters.")
                else:
                    if "SoftwareVersions" in item.get_metadata():
                        SoftwareVersions = item.get_metadata()["SoftwareVersions"]
                    RepetitionTime = item.get_metadata()["RepetitionTime"]
                    Contrast = ((item.filename).split("_")[-1]).split(".")[0]
                    if Contrast == "MTS":
                        MTS_acq = item.filename.split("_acq-")[1].split(".")[0]
                        Contrast = MTS_acq
                    keys_contrast = data[Manufacturer][ManufacturersModelName][
                        str(Contrast)
                    ].keys()
                    if "RepetitionTime" in keys_contrast:
                        if (
                            RepetitionTime
                            - data[Manufacturer][ManufacturersModelName][str(Contrast)][
                                "RepetitionTime"
                            ]
                        ) > 0.1:
                            logging.warning(
                                " "
                                + item.filename
                                + ": Incorrect RepetitionTime: TR="
                                + str(RepetitionTime)
                                + " instead of "
                                + str(
                                    data[Manufacturer][ManufacturersModelName][
                                        str(Contrast)
                                    ]["RepetitionTime"]
                                )
                            )
                    EchoTime = item.get_metadata()["EchoTime"]
                    if "EchoTime" in keys_contrast:
                        if (
                            EchoTime
                            - data[Manufacturer][ManufacturersModelName][str(Contrast)][
                                "EchoTime"
                            ]
                        ) > 0.1:
                            logging.warning(
                                " "
                                + item.filename
                                + ": Incorrect EchoTime: TE="
                                + str(EchoTime)
                                + " instead of "
                                + str(
                                    data[Manufacturer][ManufacturersModelName][
                                        str(Contrast)
                                    ]["EchoTime"]
                                )
                            )
                    FlipAngle = item.get_metadata()["FlipAngle"]
                    if "FlipAngle" in keys_contrast:
                        if (
                            data[Manufacturer][ManufacturersModelName][str(Contrast)][
                                "FlipAngle"
                            ]
                            != FlipAngle
                        ):
                            logging.warning(
                                " "
                                + item.filename
                                + ": Incorrect FlipAngle: FA="
                                + str(FlipAngle)
                                + " instead of "
                                + str(
                                    data[Manufacturer][ManufacturersModelName][
                                        str(Contrast)
                                    ]["FlipAngle"]
                                )
                            )

    # Print WARNING log
    if path_warning_log:
        file = open(path_warning_log, "r")
        lines = file.read().splitlines()
        file.close()
        for line in lines:
            print(line)


if __name__ == "__main__":
    main()
