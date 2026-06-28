# MKVCompare
**A high-speed directory auditing utility and filename validation suite for PowerShell 7.6.x.**

---

## Overview
MKVCompare is a high-performance directory auditing utility designed for media archivists during library updates. It operates by validating that updated media folders perfectly mirror their source counterparts, helping maintain strict library organization and track integrity.

The script logic is divided into two specialized operational modes:
1. **DIRECT MODE:** Triggered when you drag and drop specific folders or explicitly pass them via parameters. It pairs folders based on the presence of the `_updated` suffix.
2. **BATCH MODE:** Triggered when running the script within a parent folder. It automatically scans the root directory and pairs every standard folder with its corresponding `_updated*` sibling.

### Startup Display
The script clears the console and displays the active source paths before beginning its execution. This startup display is automatically suppressed when debugging is active to ensure that the internal telemetry log remains perfectly preserved and readable.

### Pairing Logic
The script employs a flexible wildcard matching system for updated folders. A base source folder named `ShowTitle` will automatically discover and pair with folders named `ShowTitle_updated`, `ShowTitle_updated-HEVC`, `ShowTitle_updated-v2`, and similar naming variations.

### Comparison Engine
Unlike simple tools that only perform basic file count checks, this script executes a full filename audit. If the base folder contains `Movie.mkv` and the updated folder contains `Movie-fixed.mkv`, the script will report a mismatch even if the total file counts match. This ensures that hidden variations are caught and track integrity remains intact.

## Usage Examples
```powershell
# Batch Audit Current Directory
.\MKVCompare.ps1

# Audit Specific Folders (Drag & Drop)
.\MKVCompare.ps1 -Path 'C:\Media\Show', 'C:\Media\Show_updated'

# Debug Pairing Logic
.\MKVCompare.ps1 -DevDebug
```

---

## Parameter Reference

### Core Flags
| Flag | Description |
| :--- | :--- |
| `-Path <string[]>` | Defines the target directory or directories. Supports multiple paths. If omitted, the script defaults to the current working directory. Supports folder drag-and-drop. |
| `-DevDebug \| -Dev \| -DBG` | **Exposing the Black Box:** Exposes the script's internal pairing logic. Prints the full absolute paths of every Base/Updated pair it identifies before starting the comparison, and suppresses the startup console clear to preserve telemetry logs. |
| `-help \| -manual \| -h` | Displays the built-in internal manual and usage guide. |

---

## Dependencies
* **PowerShell:** Built with PowerShell 7.6.x. The script utilizes the ternary operator and other modern syntax features not available in Windows PowerShell 5.1.
* **Windows OS:** Required for native `shlwapi.dll` (Natural Sort) integration to ensure files and folders are evaluated in the same order seen in File Explorer.

## Support & Maintenance
**This repository is provided "as-is" for archival purposes.** The author is not actively looking for feedback, feature requests, or bug reports. The issue tracker is disabled, and the author will not be responding to inquiries regarding setup or usage.

## Disclaimer
*This script automates directory auditing and structural validation. While designed for safety and read-only comparison, always ensure you maintain proper data workflows during library updates. The author is not responsible for any accidental data loss, sorting discrepancies, or script execution conflicts resulting from the use of this tool.*

---
> **Document Control**
> *This document is up-to-date with the following version of MKVCompare.*
> *2026.06.28__15.22.44*