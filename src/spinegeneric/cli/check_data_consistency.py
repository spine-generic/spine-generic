"""
Script to check `participants.tsv` and the presence of JSON sidecars.

For usage, type: sg_check_data_consistency -h
"""

import argparse
import csv
import datetime
from pathlib import Path
import re


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


def validate_whitespace(value: str):
    if value != value.lstrip():
        raise ValueError("should not have leading whitespace")
    if value != value.rstrip():
        raise ValueError("should not have trailing whitespace")


def validate_integer(value: str) -> int:
    validate_whitespace(value)
    try:
        return int(value)
    except ValueError:
        raise ValueError("should be an integer") from None


def validate_sex(value: str):
    validate_whitespace(value)
    if value not in ["M", "F", "O"]:
        raise ValueError("should be one of 'M', 'F', 'O', or 'n/a'")


def validate_age(value: str):
    age = validate_integer(value)
    if not 18 <= age <= 60:
        raise ValueError("should be between 18 and 60")


date_re = re.compile(r"(\d{4})-(\d{2})-(\d{2})")


def validate_date(value: str):
    validate_whitespace(value)
    m = date_re.fullmatch(value)
    if m is None:
        raise ValueError("should be formatted as YYYY-mm-dd")
    year, month, day = map(int, m.group(1, 2, 3))
    datetime.date(year, month, day)  # to check month range and day range


validators = {
    "participant_id": validate_whitespace,
    "sex": validate_sex,
    "age": validate_age,
    "height": validate_integer,
    "weight": validate_integer,
    "date_of_scan": validate_date,
    "institution_id": validate_whitespace,
    "institution": validate_whitespace,
    "manufacturer": validate_whitespace,
    "manufacturers_model_name": validate_whitespace,
    "receive_coil_name": validate_whitespace,
    "software_versions": validate_whitespace,
    "researcher": validate_whitespace,
}


def main():
    # Parse input arguments
    parser = get_parser()
    args = parser.parse_args()

    # Keep track of errors for the exit status
    warnings_found = False

    def warn(message: str):
        nonlocal warnings_found
        warnings_found = True
        print(f"Warning: {message}")

    # Read participants.tsv
    fieldnames, rows = read_tsv(args.path_in / "participants.tsv")

    # Compare subject list from participants.tsv and from sub-* folders
    if "participant_id" in fieldnames:
        tsv_subj = set(r["participant_id"] for r in rows)
        dir_subj = set(p.name for p in args.path_in.glob("sub-*") if p.is_dir())
        for subj in sorted(dir_subj - tsv_subj):
            warn(f"participants.tsv: missing row for data folder '{subj}'")
        for subj in sorted(tsv_subj - dir_subj):
            warn(f"participants.tsv: missing data folder for subject '{subj}'")

    # Check the presence of JSON sidecars
    for img_path in args.path_in.glob("sub-*/**/*.nii.gz"):
        json_path = img_path.with_suffix("").with_suffix(".json")
        if not json_path.exists():
            warn(f"missing JSON sidecar for {img_path}")

    # Check the column names of `participants.tsv` to ensure they match the validator
    tsv_cols = set(fieldnames)
    expected_cols = set(validators.keys())
    for col in sorted(expected_cols - tsv_cols):
        warn(f"participants.tsv: missing column '{col}'")
    for col in sorted(tsv_cols - expected_cols):
        warn(f"participants.tsv: extra column '{col}'")

    # Check the row values of `participants.tsv` using the validator
    for r, row in enumerate(rows, start=1):
        if None in row.values():
            warn(f"participants.tsv: row {r} is too short")
        if None in row.keys():
            warn(f"participants.tsv: row {r} is too long")
        for col, validate in validators.items():
            if col not in fieldnames:
                continue
            value = row[col]
            if value is None or value == "n/a":
                continue
            try:
                validate(value)
            except ValueError as e:
                warn(f"participants.tsv: row {r}: {col} is '{value}', but {e}")

    # exit code
    return 1 if warnings_found else 0
