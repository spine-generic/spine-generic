"""
Script to check acquisition parameters.

For usage, type: sg_params_checker -h
"""

import argparse
import importlib.resources
import json
import logging
import logging.config
from pathlib import Path

from bids import BIDSLayout, BIDSLayoutIndexer

import spinegeneric.config


def get_parser():
    parser = argparse.ArgumentParser(
        description="""
            Script to check acquisition parameters. It compares the
            acquisition parameters found in the JSON sidecar files to the
            recommended acquisition parameters.
        """,
    )
    parser.add_argument(
        "-path-in",
        required=True,
        type=Path,
        help="Path to input BIDS dataset, which contains all the 'sub-*' folders.",
    )
    return parser


def main():
    # Parse input arguments
    parser = get_parser()
    args = parser.parse_args()

    # Initialize logging
    logging.config.dictConfig({
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {"default": {"format": "%(levelname)s: %(message)s"}},
        "handlers": {
            "console": {
                "class": "logging.StreamHandler",
                "formatter": "default",
            },
            "file": {
                "class": "logging.FileHandler",
                "formatter": "default",
                "filename": str(args.path_in / "WARNING.log"),
                "mode": "w",
            },
        },
        "root": {"level": "DEBUG", "handlers": ["console", "file"]},
    })

    # Initialize the BIDSLayout object directed at the input dataset.
    # From the BIDS documentation:
    #   "A BIDSLayout instance is a lightweight container for all files in the BIDS project directory."
    with importlib.resources.path(spinegeneric.config, "bids_specs.json") as path_sg_layout_config:
        layout = BIDSLayout(
            str(args.path_in),
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
    with importlib.resources.open_text(spinegeneric.config, "specs.json") as f:
        sg_acq_protocol = json.load(f)

    # Loop across the contrast images to check parameters
    for item in query:
        metadata = item.get_metadata()
        # Check that the json sidecar has the correct keys and values
        if "Manufacturer" not in metadata:
            logging.warning(f"{item.filename}: Missing 'Manufacturer' key in json sidecar; Cannot check parameters.")
            continue
        Manufacturer = metadata["Manufacturer"]
        if Manufacturer not in sg_acq_protocol.keys():
            logging.warning(f"{item.filename}: Manufacturer '{Manufacturer}' not in list "
                            f"of known manufacturers: {sg_acq_protocol.keys()}. Cannot check parameters.")
            continue
        ManufacturersModelName = metadata["ManufacturersModelName"]
        if ManufacturersModelName not in sg_acq_protocol[Manufacturer].keys():
            logging.warning(f"{item.filename}: Model '{ManufacturersModelName}' not present in list of known "
                            f"models for manufacturer '{Manufacturer}'. Cannot check parameters.")
            continue

        # Parse the filename's BIDS entities and suffix
        parts = item.filename.removesuffix(".nii.gz").split("_")
        suffix = parts.pop()
        entities = {}
        for part in parts:
            try:
                key, value = part.split("-", maxsplit=1)
            except ValueError:
                logging.warning(f"{item.filename}: Ignoring bad filename entity: '{part}'.")
                continue
            if key in entities:
                logging.warning(f"{item.filename}: Repeated entity in filename: '{key}'.")
            entities[key] = value

        # Get the contrast from the filename.
        # For MTS files, the spine-generic protocol splits this into 3 cases:
        # "MToff_MTS", "MTon_MTS", "T1w_MTS". This depends on either the
        # "flip" and "mt" entities (new naming scheme), or the "acq" entity
        # (old naming scheme).
        Contrast = suffix
        if Contrast == "MTS":
            try:
                # Try the new naming scheme first
                Contrast = {
                    ("1", "off"): "MToff_MTS",
                    ("1", "on"): "MTon_MTS",
                    ("2", "off"): "T1w_MTS",
                }[entities["flip"], entities["mt"]]
            except KeyError:
                # Fall back to the old naming scheme
                Contrast = f"{entities.get('acq', 'missing')}_MTS"
        if Contrast not in ["T1w", "T2w", "T2star", "MToff_MTS", "MTon_MTS", "T1w_MTS"]:
            logging.warning(f"{item.filename}: Unrecognized contrast: '{Contrast}'")
            continue

        # Fetch the names of each available parameter for the given manufacturer + model
        keys_contrast = sg_acq_protocol[Manufacturer][ManufacturersModelName][str(Contrast)].keys()

        # Validate repetition time against spine-generic's acquisition protocol
        RepetitionTime = metadata["RepetitionTime"]
        if "RepetitionTime" in keys_contrast:
            ExpectedRT = sg_acq_protocol[Manufacturer][ManufacturersModelName][str(Contrast)]["RepetitionTime"]
            # TODO: We only check `val > 0.1`, rather than `abs(val) > 0.1`. Is this a bug?
            if RepetitionTime - ExpectedRT > 0.1:
                logging.warning(f"{item.filename}: Incorrect RepetitionTime: "
                                f"TR={RepetitionTime} instead of {ExpectedRT} +/- 0.1.")

        # Validate echo time against spine-generic's acquisition protocol
        EchoTime = metadata["EchoTime"]
        if "EchoTime" in keys_contrast:
            ExpectedTE = sg_acq_protocol[Manufacturer][ManufacturersModelName][str(Contrast)]["EchoTime"]
            # TODO: We only check `val > 0.1`, rather than `abs(val) > 0.1`. Is this a bug?
            if EchoTime - ExpectedTE > 0.1:
                logging.warning(f"{item.filename}: Incorrect EchoTime: "
                                f"TE={EchoTime} instead of {ExpectedTE} +/- 0.1.")

        # Validate flip angle against spine-generic's acquisition protocol
        FlipAngle = metadata["FlipAngle"]
        if "FlipAngle" in keys_contrast:
            ExpectedFA = sg_acq_protocol[Manufacturer][ManufacturersModelName][str(Contrast)]["FlipAngle"]
            if FlipAngle != ExpectedFA:
                logging.warning(f"{item.filename}: Incorrect FlipAngle: "
                                f"FA={FlipAngle} instead of {ExpectedFA}.")
