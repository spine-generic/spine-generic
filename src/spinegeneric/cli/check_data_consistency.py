"""
Script to check `participants.tsv` and the presence of JSON sidecars.

For usage, type: sg_check_data_consistency -h
"""

import argparse
import csv
from pathlib import Path

import pandas as pd
from pandas_schema import Column, Schema
from pandas_schema.validation import (
    DateFormatValidation,
    InListValidation,
    InRangeValidation,
    LeadingWhitespaceValidation,
    MatchesPatternValidation,
    TrailingWhitespaceValidation,
)


def get_parser():
    parser = argparse.ArgumentParser(
        description="""
            Script to check the contents of 'participants.tsv', compare it
            against the set of 'sub-*' folders, and check the presence of JSON
            sidecars.
        """,
    )
    parser.add_argument(
        "-path-in",
        required=True,
        type=Path,
        help="Path to input BIDS dataset, which contains all the 'sub-*' folders.",
    )
    return parser


Fieldname = str
Row = dict[Fieldname, str]


def read_tsv(path: Path) -> tuple[list[Fieldname], list[Row]]:
    with path.open(newline="") as file:
        reader = csv.DictReader(file, delimiter="\t", lineterminator="\n")
        return reader.fieldnames, list(reader)


def main():
    # Parse input arguments
    parser = get_parser()
    args = parser.parse_args()

    # Read participants.tsv
    fieldnames, rows = read_tsv(args.path_in / "participants.tsv")

    # Compare subject list from participants.tsv and from sub-* folders
    tsv_subj = set(r["participant_id"] for r in rows)
    dir_subj = set(p.name for p in args.path_in.glob("sub-*") if p.is_dir())
    for subj in dir_subj - tsv_subj:
        print(f"Warning missing subject from participants.tsv: {subj}")
    for subj in tsv_subj - dir_subj:
        print(f"Warning missing data for subject listed in participants.tsv: {subj}")

    # Check the presence of JSON sidecars
    for img_path in args.path_in.glob("sub-*/**/*.nii.gz"):
        json_path = img_path.with_suffix("").with_suffix(".json")
        if not json_path.exists():
            print(f"Missing jsonSidecar: {json_path}")

    # Checking participants.tsv contents
    schema = Schema(
        [
            Column(
                "participant_id",
                [LeadingWhitespaceValidation(), TrailingWhitespaceValidation()],
            ),
            Column("sex", [InListValidation(["M", "F"])]),
            Column("age", [InRangeValidation(18, 60)]),
            Column("height", [MatchesPatternValidation(r"[0-9]|-")]),
            Column("weight", [MatchesPatternValidation(r"[0-9]|-")]),
            Column(
                "date_of_scan",
                [DateFormatValidation("%Y-%m-%d") | MatchesPatternValidation(r"-")],
            ),
            Column(
                "institution_id",
                [LeadingWhitespaceValidation(), TrailingWhitespaceValidation()],
            ),
            Column(
                "institution",
                [LeadingWhitespaceValidation(), TrailingWhitespaceValidation()],
            ),
            Column(
                "manufacturer",
                [LeadingWhitespaceValidation(), TrailingWhitespaceValidation()],
            ),
            Column(
                "manufacturers_model_name",
                [LeadingWhitespaceValidation(), TrailingWhitespaceValidation()],
            ),
            Column(
                "receive_coil_name",
                [LeadingWhitespaceValidation(), TrailingWhitespaceValidation()],
            ),
            Column(
                "software_versions",
                [LeadingWhitespaceValidation(), TrailingWhitespaceValidation()],
            ),
            Column(
                "researcher",
                [LeadingWhitespaceValidation(), TrailingWhitespaceValidation()],
            ),
        ]
    )

    tsv_file = pd.read_csv(str(args.path_in / "participants.tsv"), sep="\t")
    errors = schema.validate(tsv_file)
    print("\nChecking the contents of participants.tsv")
    if not errors:
        print("--> all good 👍")
    else:
        for error in errors:
            print(error)
