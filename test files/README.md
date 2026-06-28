# Test Files for MKVCompare

This repository contains dummy test files designed to validate the functionality of the [MKVCompare](https://codeberg.org/pwshAgyjkcrg761/MKVCompare) script.

## Purpose
These files are intended for development and testing use only. Use them to verify that the script correctly:
1. Pairs source folders with their corresponding `_updated*` twins using wildcard logic.
2. Identifies discrepancies in MKV file counts and specific filenames.
3. Detects and reports "Conflicts" when multiple updated folders exist for one source.
4. Handles edge cases like empty directories and special naming conventions.

## License
The contents of the `test files` directory in this repository are licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-nc-sa/4.0/).

## How to use
1. Clone or download the `test files` directory to a separate testing location.
2. Run [MKVCompare](https://codeberg.org/pwshAgyjkcrg761/MKVCompare) against the root of the test directory (Batch Mode) or drag specific folders onto the script (Direct Mode).
3. Review the **Summary Statistics** to ensure the counts for Matches, Mismatches, and Conflicts align with the folder structure.

## Included Test Scenarios
The test directory is structured to trigger specific script behaviors:
- **`match` & `match_updated`**: Verifies standard 1:1 pairing and perfect matches.
- **`match scriptname` & `match scriptname_updated-scriptname`**: Validates wildcard pairing when both the source and updated folders contain custom suffixes.
- **`conflict` (with `_updated-scriptname1` & `_updated-scriptname2`)**: Triggers the **Pair Conflict** logic to ensure the script flags ambiguous updates.
- **`missing file` & `missing file_updated`**: Validates the **Mismatch** engine by providing different MKV counts/filenames.
- **`empty folder` & `empty folder_updated`**: Tests the script's ability to handle pairs containing zero MKV files.

*Note: These files do not contain actual video content; they are zero-byte files used for structural verification.*