# ==============================================================================
# SCRIPT: MKVCompare.ps1
# VERSION: 2026.06.28__15.22.44
# TARGET: PowerShell 7.6.3 LTS
#
# Copyright (C) 2026 pwshAgyjkcrg761
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# ==============================================================================
# <PROTECTED>
# ==============================================================================
# AI INSTRUCTIONS v2026.06.24__06.54.45 : 
#
# 1. MESSAGE STAMP: 
#    - Every response containing code MUST begin with a standalone version stamp.
#    - Use CHICAGO TIME (Central Time), 24-hour clock.
#    - Format: YYYY.MM.DD__HH.MM.SS.
#    - CRITICAL: Use the time provided in the prompt or at https://www.timeanddate.com/worldclock/usa/chicago. Ensure minutes are exact.
#
# 2. VERSION SNIPPET PROHIBITION:
#    - DO NOT provide code snippets, anchors, or steps to update the script's internal VERSION comment or $scriptVersion variable. 
#    - The user handles internal file versioning manually based on the Message Stamp.
#
# 3. SCRIPT OUTPUT (SURGICAL FIXES ONLY):
#    - Provide minimal, highly targeted, surgical edits. Do not rewrite large blocks or entire functions.
#    - Always use a codebox with a copy button.
#    - Multiple modifications MUST be presented strictly ONE step at a time. Wait for user confirmation before proceeding to the next step. 
#    - DO NOT modify or refactor any code inside <PROTECTED> tags.
#
# 4. VERBATIM ANCHOR PROTOCOL (FOR NOTEPAD++):
#    - To facilitate "Find" in Notepad++, always structure edits with:
#      - "Verbatim Anchor (Before)" - The exact lines of existing code immediately before the change.
#      - "Verbatim Anchor (After)" - The exact lines of existing code immediately after the change.
#      - "Snippet to REPLACE" - The exact code block to be deleted.
#      - "What to PASTE in its place" - The new code block to be inserted.
#    - Do not summarize, truncate, or refactor the existing code used as an anchor.
#    - Match spaces, comments, and symbols exactly as they appear in the file.
#
# 5. CONTENT PRESERVATION:
#    - Do not remove, modify, or strip out telemetry data or DevDebug information from any provided code.
# ==============================================================================
# </PROTECTED>


param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [Alias("Path")]
    [string[]]$Paths = @("."),

    # Global Debugging Param
    [alias("Dev", "DevD", "DBG", "DDBG")]
    [switch]$DevDebug,
    
    [alias("h", "help")]
    [switch]$Manual
)



# --- GLOBAL VERSION DEFINITION ---
$scriptVersion = "2026.06.28__15.22.44"

if ($PSVersionTable.PSVersion -lt [version]"7.6.0") {
    Write-Host "ERROR: Running on version $($PSVersionTable.PSVersion). This script requires at least 7.6.0." -ForegroundColor DarkRed
    Read-Host "Press Enter to exit"; exit
}



$Title = "MKV Compare"
[Console]::Title = $Title

function Show-ProjectManual {
    param($scriptVersion)

    # $True means DarkCyan, $False means DarkMagenta
    $global:altColorToggle = $true  

    $PrintManualBlock = {
        param(
            [string]$FlagLine,
            [string[]]$DescLines,
            [string]$ForceDescColor = $null
        )
        
        # 1. Print the Flag in DarkGreen
        Write-Host $FlagLine -ForegroundColor DarkGreen
        
        # 2. Determine description color
        $currentColor = if ($ForceDescColor) { $ForceDescColor } else { 
            if ($global:altColorToggle) { "DarkCyan" } else { "DarkMagenta" } 
        }
        
        # 3. Print the description lines
        foreach ($line in $DescLines) {
            Write-Host $line -ForegroundColor $currentColor
        }
        
        if (-not $ForceDescColor) {
            $global:altColorToggle = -not $global:altColorToggle
        }
    }

    Clear-Host
    Write-Host "============================================================" -ForegroundColor Cyan
               " MKVCompare.ps1 v$scriptVersion  ",
               " MANUAL & USAGE GUIDE" | ForEach-Object { Write-Host $_ -ForegroundColor DarkMagenta }
    Write-Host " Copyright (C) 2026 pwshAgyjkcrg761`n" -ForegroundColor DarkCyan
    
     " This program is free software: you can redistribute it and/or",
     " modify it under the terms of the GNU General Public License as",
     " published by the Free Software Foundation, either version 3 of",
     " the License, or (at your option) any later version."  | ForEach-Object { Write-Host $_ -ForegroundColor DarkMagenta }
    Write-Host "============================================================" -ForegroundColor Cyan
    
    Write-Host "`n OVERVIEW:" -ForegroundColor DarkYellow
     "  This utility is designed for high-speed directory auditing during media",
     "  library updates. It ensures that 'Updated' folders contain the exact",
     "  same number of MKV files as their 'Source' counterparts and identifies",
     "  specific missing or extra files by filename.",
     "",
     "  The script operates in two dynamic modes:",
     "  1. DIRECT MODE: Triggered when you drag and drop specific folders or",
     "     pass them via -Path. It pairs folders based on the '_updated' suffix.",
     "  2. BATCH MODE: Triggered when running in a parent folder. It scans the",
     "     root directory and automatically pairs every folder with its",
     "     corresponding '_updated*' sibling.",
     "",
     "  STARTUP DISPLAY:",
     "  The script clears the console and displays the active source paths",
     "  before execution. This is suppressed when -DevDebug is active to",
     "  preserve the telemetry log.",
     "",
     "  PAIRING LOGIC:",
     "  The script uses a wildcard match for 'Updated' folders. A source folder",
     "  named 'ShowTitle' will automatically pair with 'ShowTitle_updated' or",
     "  'ShowTitle_updated-HEVC', 'ShowTitle_updated-v2', etc.`n" | ForEach-Object { Write-Host $_ -ForegroundColor DarkMagenta }

    Write-Host " COMPARISON ENGINE:" -ForegroundColor DarkYellow
    "  Unlike simple count checkers, this script performs a full filename",
    "  audit. If the base folder has 'Movie.mkv' and the updated folder has",
    "  'Movie-fixed.mkv', the script will report a mismatch even if the file",
    "  counts are identical. This ensures track integrity remains intact.`n" | ForEach-Object { Write-Host $_ -ForegroundColor DarkCyan }
    
    Write-Host " DEPENDENCIES:" -ForegroundColor DarkYellow
    "  • PowerShell: Built with PowerShell 7.6.x. The script utilizes the",
    "    ternary operator and other modern syntax not available in 5.1.",
    "  • Windows OS: Required for Natural Sort (shlwapi.dll) integration.`n" | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }

    Write-Host " USAGE EXAMPLES:`n" -ForegroundColor DarkYellow
    
    Write-Host "  Batch Audit Current Directory:`n" -ForegroundColor DarkGray
    Write-Host "    .\MKVCompare.ps1`n" -ForegroundColor DarkMagenta
    
    Write-Host "  Audit Specific Folders (Drag & Drop):`n" -ForegroundColor DarkGray
    Write-Host "    .\MKVCompare.ps1 -Path 'C:\Media\Show', 'C:\Media\Show_updated'`n" -ForegroundColor DarkCyan
    
    Write-Host "  Debug Pairing Logic:`n" -ForegroundColor DarkGray
    Write-Host "    .\MKVCompare.ps1 -DevDebug`n" -ForegroundColor DarkMagenta

    Write-Host "`n CORE FLAGS:`n" -ForegroundColor DarkYellow

    &$PrintManualBlock "  -Path <string[]>" @(
    "      Defines the target directory or directories. Supports multiple paths.",
    "      If omitted, the script defaults to the current working directory.`n"
)

    &$PrintManualBlock "  -DevDebug | -Dev | -DBG" @(
    "      Exposes the script's internal pairing logic. In this mode, the",
    "      script will print the full absolute paths of every Base/Updated",
    "      pair it identifies before starting the comparison.`n"
)    
                        
    &$PrintManualBlock "  -help | -manual | -h" @(
    "      Displays this manual. The one you are reading right now.`n"
)
    
    Write-Host "`n NOTES:" -ForegroundColor DarkYellow
    "  * CONFLICTS: If multiple updated folders are found for one source, the",
    "    script will log a CONFLICT and skip that pair to prevent false data.",
    "  * SORTING: Uses Windows Natural Sort (shlwapi.dll) to ensure files and",
    "    folders are evaluated in the same order seen in File Explorer." | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
    
    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host " Press any key to exit..." -ForegroundColor DarkYellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# --- HELP & MANUAL SYSTEM ---
if ($Manual) {
    Show-ProjectManual -scriptVersion $scriptVersion
}

# --- Logic Setup: Windows Natural Sort ---
$WindowsSortCode = @'
using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;

public class WindowsNaturalSort : IComparer<string> {
    [DllImport("shlwapi.dll", CharSet = CharSet.Unicode, ExactSpelling = true)]
    private static extern int StrCmpLogicalW(string x, string y);

    public int Compare(string x, string y) {
        return StrCmpLogicalW(x, y);
    }
}
'@
if (-not ([System.Management.Automation.PSTypeName]'WindowsNaturalSort').Type) {
    Add-Type -TypeDefinition $WindowsSortCode
}

# Helper function to sort objects exactly like Windows File Explorer
function Sort-AsWindows {
    param(
        [Parameter(Mandatory=$true)]
        $InputList,
        [Parameter(Mandatory=$true)]
        [string]$PropertyName
    )
    if ($InputList.Count -le 1) { return $InputList }
    $Sorter = [WindowsNaturalSort]::new()
    $SortedList = [System.Collections.Generic.List[PSObject]]::new($InputList)
    $SortedList.Sort([System.Comparison[PSObject]] {
        param($a, $b)
        return $Sorter.Compare($a.$PropertyName, $b.$PropertyName)
    })
    return $SortedList
}

# 1. Gather Arguments
$RawItems = [System.Collections.Generic.List[PSObject]]::new()
if ($Paths.Count -gt 0) {
    foreach ($arg in $Paths) {
        if (Test-Path -Path $arg -PathType Container) {
            $RawItems.Add((Get-Item -LiteralPath $arg))
        }
    }
}

# 2. Force Natural Sort (Fixes the "Right-Click First" Explorer behavior)
$ValidPassedPaths = if ($RawItems.Count -gt 1) {
    $Sorter = [WindowsNaturalSort]::new()
    $RawItems.Sort([System.Comparison[PSObject]] {
        param($a, $b) return $Sorter.Compare($a.FullName, $b.FullName)
    })
    $RawItems
} else {
    $RawItems
}

# 3. STARTUP DISPLAY
if (-not $DevDebug) { Clear-Host }
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "         $Title v$scriptVersion" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

if ($ValidPassedPaths.Count -gt 0) {
    Write-Host "Source Folder(s):" -ForegroundColor Blue
    foreach ($Path in $ValidPassedPaths) {
        Write-Host " -> $($Path.FullName)" -ForegroundColor DarkYellow
    }
    Write-Host ""
}

Read-Host "Press [Enter] to begin comparing MKV counts"
Write-Host ""

$Mismatches = [System.Collections.Generic.List[PSObject]]::new()
$UnpairedFolders = [System.Collections.Generic.List[PSObject]]::new()
$TotalCheckedPairs = 0
$MultipleMatchErrors = 0


# Helper function to audit a specific pair of directories
function Invoke-FolderComparison {
    param (
        [System.IO.DirectoryInfo]$SourceDir,
        [System.IO.DirectoryInfo]$UpdatedDir
    )
    $script:TotalCheckedPairs++
    if ($DevDebug) {
        Write-Host "`n[DevDebug] Evaluating Pair:" -ForegroundColor Gray
        Write-Host "          Base:    $($SourceDir.FullName)" -ForegroundColor Gray
        Write-Host "          Updated: $($UpdatedDir.FullName)`n" -ForegroundColor Gray
    }

    if (-not (Test-Path -Path (Join-Path $SourceDir.FullName "*.mkv")) -and -not (Test-Path -Path (Join-Path $UpdatedDir.FullName "*.mkv"))) {
        Write-Host "[!] Warning: No MKV files found in either folder: $($SourceDir.Name)" -ForegroundColor Yellow
    }
    
    $SourceFiles = @(Get-ChildItem -LiteralPath $SourceDir.FullName -Filter "*.mkv" -File | Select-Object -ExpandProperty Name)
    $UpdatedFiles = @(Get-ChildItem -LiteralPath $UpdatedDir.FullName -Filter "*.mkv" -File | Select-Object -ExpandProperty Name)

    # Correctly filter the SideIndicator property from the output objects
    $Comparisons = Compare-Object -ReferenceObject $SourceFiles -DifferenceObject $UpdatedFiles
    
    $MissingInUpdated = $Comparisons | Where-Object { $_.SideIndicator -eq '<=' } | Select-Object -ExpandProperty InputObject
    $MissingInSource  = $Comparisons | Where-Object { $_.SideIndicator -eq '=>' } | Select-Object -ExpandProperty InputObject

    if ($MissingInUpdated -or $MissingInSource) {
        $script:Mismatches.Add([PSCustomObject]@{
            FolderName       = $SourceDir.Name
            SourceCount      = $SourceFiles.Count
            UpdatedCount     = $UpdatedFiles.Count
            MissingInUpdated = $MissingInUpdated
            MissingInSource  = $MissingInSource
        })
    }
}



# 3. Determine Execution Mode Dynamically
$ProcessedAsPairs = $false

if ($ValidPassedPaths.Count -gt 0) {
    # Check if any of the passed folders contain "_updated" or have a twin that does
    $HasDirectPairs = $false
    foreach ($Path in $ValidPassedPaths) {
        if ($Path.Name -like "*_updated*") {
            $HasDirectPairs = $true
            break
        } elseif ($ValidPassedPaths.Name -like "$($Path.Name)_updated*") {
            $HasDirectPairs = $true
            break
        }
    }

    # --- MODE A: Direct Folder Selection ---
    if ($HasDirectPairs) {
        $ProcessedAsPairs = $true
        
        $PairedPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $SourceFolders = $ValidPassedPaths | Where-Object { $_.Name -notlike "*_updated*" }

        foreach ($Source in $SourceFolders) {
            $UpdatedMatches = $ValidPassedPaths | Where-Object { $_.Name -like "$($Source.Name)_updated*" }

            if ($UpdatedMatches.Count -gt 1) {
                $MultipleMatchErrors++
                Write-Host "CONFLICT: Multiple updated folders found. `n`n   Source: `n   --> $($Source.Name)`n   [?] $($UpdatedMatches.Name -join "`n   [?] ")" -ForegroundColor DarkRed
                continue
            }

            if ($UpdatedMatches) {
                $Updated = $UpdatedMatches[0]
                Invoke-FolderComparison -SourceDir $Source -UpdatedDir $Updated
                [void]$PairedPaths.Add($Source.FullName)
                [void]$PairedPaths.Add($Updated.FullName)
            }
        }

        # Identify orphans
        foreach ($Path in $ValidPassedPaths) {
            if (-not $PairedPaths.Contains($Path.FullName)) {
                $MissingTwinType = $Path.Name -like "*_updated*" ? "Base Folder" : "Updated Folder (_updated*)"
                $UnpairedFolders.Add([PSCustomObject]@{
                    FolderName  = $Path.Name
                    MissingTwin = $MissingTwinType
                })
            }
        }
    }
}

# --- MODE B & C: Parent Folder Batch Processing ---
if (-not $ProcessedAsPairs) {
    $Targets = @()
    if ($ValidPassedPaths.Count -gt 0) {
        $Targets = $ValidPassedPaths
    } else {
        $Targets += Get-Item -LiteralPath .
    }

    foreach ($Target in $Targets) {
        $SourceFolders = Get-ChildItem -LiteralPath $Target.FullName -Directory | 
            Where-Object { $_.Name -notlike "*_updated*" }

        foreach ($Source in $SourceFolders) {
            $UpdatedMatches = Get-ChildItem -LiteralPath $Target.FullName -Directory -Filter "$($Source.Name)_updated*"
            
            if ($UpdatedMatches.Count -gt 1) {
                $MultipleMatchErrors++
                Write-Host "CONFLICT: Multiple updated folders found. `n`n   Source: `n   --> $($Source.Name)`n   [?] $($UpdatedMatches.Name -join "`n   [?] ")" -ForegroundColor DarkRed
                continue
            }

            if ($UpdatedMatches) {
                Invoke-FolderComparison -SourceDir $Source -UpdatedDir $UpdatedMatches[0]
            }
        }
    }
}

# 4. Display Results
Write-Host "----------------------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "Results:" -ForegroundColor White
# Write-Host "----------------------------------------------------"
Write-Host ""

# Display Mismatches (Sorted with Windows Natural Sort)
if ($TotalCheckedPairs -gt 0) {
    if ($Mismatches.Count -eq 0) {
        Write-Host "All evaluated folders match! Checked $TotalCheckedPairs pair(s) perfectly." -ForegroundColor Green
    } else {
        Write-Host "Found $($Mismatches.Count) mismatching folder pair(s) out of $TotalCheckedPairs checked:`n" -ForegroundColor DarkRed
        
        $SortedMismatches = Sort-AsWindows -InputList $Mismatches -PropertyName "FolderName"
        foreach ($Item in $SortedMismatches) {
            Write-Host "[-] Directory: " -NoNewline -ForegroundColor Yellow
            Write-Host $Item.FolderName -ForegroundColor White
            Write-Host "    -> Base Folder Total:    $($Item.SourceCount) MKV(s)" -ForegroundColor Gray
            Write-Host "    -> Updated Folder Total: $($Item.UpdatedCount) MKV(s)" -ForegroundColor Gray
            
            if ($Item.MissingInUpdated) {
                Write-Host "    -> Missing from Updated folder:" -ForegroundColor DarkRed
                foreach ($File in $Item.MissingInUpdated) {
                    Write-Host "       [x] $File" -ForegroundColor DarkRed
                }
            }
            if ($Item.MissingInSource) {
                Write-Host "    -> Extra in Updated folder (Missing from Base):" -ForegroundColor Magenta
                foreach ($File in $Item.MissingInSource) {
                    Write-Host "       [+] $File" -ForegroundColor DarkMagenta
                }
            }
            Write-Host ""
        }
    }
} elseif ($UnpairedFolders.Count -eq 0) {
    Write-Host "No paired folders were found to evaluate." -ForegroundColor Yellow
}

# Display Unpaired/Orphaned Folders Warning (Sorted with Windows Natural Sort)
if ($UnpairedFolders.Count -gt 0) {
    Write-Host "`n----------------------------------------------------" -ForegroundColor Gray
    Write-Host "Warning: Unpaired Folders Detected" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------"
    Write-Host "The following folder(s) were sent but were missing their corresponding twin:" -ForegroundColor Gray
    Write-Host ""

    $SortedUnpaired = Sort-AsWindows -InputList $UnpairedFolders -PropertyName "FolderName"
    foreach ($Orphan in $SortedUnpaired) {
        Write-Host "[!] Folder: " -NoNewline -ForegroundColor DarkYellow
        Write-Host $Orphan.FolderName -ForegroundColor White
        Write-Host "    -> Missing: " -NoNewline -ForegroundColor Gray
        Write-Host $Orphan.MissingTwin -ForegroundColor Magenta
        Write-Host ""
    }
}

# Final Summary Stats
Write-Host "----------------------------------------------------" -ForegroundColor Gray
Write-Host "Summary Statistics:" -ForegroundColor White
Write-Host " -> Pairs Evaluated:  $TotalCheckedPairs" -ForegroundColor Gray
Write-Host " -> Perfect Matches:  $($TotalCheckedPairs - $Mismatches.Count)" -ForegroundColor Green
Write-Host " -> Mismatches:       $($Mismatches.Count)" -ForegroundColor ($Mismatches.Count -gt 0 ? "DarkRed" : "Gray")
Write-Host " -> Orphaned Folders: $($UnpairedFolders.Count)" -ForegroundColor ($UnpairedFolders.Count -gt 0 ? "Yellow" : "Gray")
Write-Host " -> Pair Conflicts:   $MultipleMatchErrors" -ForegroundColor ($MultipleMatchErrors -gt 0 ? "DarkRed" : "Gray")

# 5. Ending Prompt
Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "         Processing complete." -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press [Enter] to exit the script"