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

from bids import BIDSLayout

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

    # Keep track of whether any warnings are found
    warnings_found = False

    def warn(*args, **kwargs):
        nonlocal warnings_found
        warnings_found = True
        logging.warning(*args, **kwargs)

    # Initialize the BIDSLayout object directed at the input dataset.
    # From the BIDS documentation:
    #   "A BIDSLayout instance is a lightweight container for all files in the BIDS project directory."
    layout = BIDSLayout(str(args.path_in), validate=False)

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
            warn(
                f"{item.filename}: Missing 'Manufacturer' key in json "
                f"sidecar; Cannot check parameters."
            )
            continue
        Manufacturer = metadata["Manufacturer"]
        if Manufacturer not in sg_acq_protocol.keys():
            warn(
                f"{item.filename}: Manufacturer '{Manufacturer}' not in list "
                f"of known manufacturers: {sg_acq_protocol.keys()}. Cannot "
                f"check parameters."
            )
            continue
        ManufacturersModelName = metadata["ManufacturersModelName"]
        if ManufacturersModelName not in sg_acq_protocol[Manufacturer].keys():
            warn(
                f"{item.filename}: Model '{ManufacturersModelName}' not "
                f"present in list of known models for manufacturer "
                f"'{Manufacturer}'. Cannot check parameters."
            )
            continue

        # Parse the filename's BIDS entities and suffix
        parts = item.filename.removesuffix(".nii.gz").split("_")
        suffix = parts.pop()
        entities = {}
        for part in parts:
            try:
                key, value = part.split("-", maxsplit=1)
            except ValueError:
                warn(f"{item.filename}: Ignoring bad filename entity: '{part}'.")
                continue
            if key in entities:
                warn(f"{item.filename}: Repeated entity in filename: '{key}'.")
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
            warn(f"{item.filename}: Unrecognized contrast: '{Contrast}'")
            continue

        # Fetch the available parameters for the given manufacturer + model
        expected = sg_acq_protocol[Manufacturer][ManufacturersModelName][Contrast]

        # Validate values against spine-generic's acquisition protocol
        for key, symbol, tolerance in [
            ("RepetitionTime", "TR", 0.1),
            ("EchoTime", "TE", 0.1),
            ("InversionTime", "TI", 0.1),
            ("FlipAngle", "FA", None),
        ]:
            if key not in expected:
                # The protocol doesn't require this value.
                continue
            if key not in metadata:
                warn(f"{item.filename}: Missing {key}.")
                continue
            if tolerance is None:
                # We want an exact match of data type and value
                if metadata[key] != expected[key]:
                    warn(
                        f"{item.filename}: Incorrect {key}: {symbol}="
                        f"{metadata[key]!r} instead of {expected[key]!r}."
                    )
            else:
                # We want an approximate match of numerical values
                try:
                    actual = float(metadata[key])
                except ValueError:
                    warn(
                        f"{item.filename}: Incorrect {key}: {symbol}="
                        f"{metadata[key]!r} is not a number."
                    )
                    continue
                if abs(actual - expected[key]) > tolerance:
                    warn(
                        f"{item.filename}: Incorrect {key}: {symbol}={actual} "
                        f"instead of {expected[key]} +/- {tolerance}."
                    )

    # Exit code for the script
    return 1 if warnings_found else 0
