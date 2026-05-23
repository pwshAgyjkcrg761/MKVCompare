# ==============================================================================
# SCRIPT: MKVCompare.ps1
# VERSION: 2026.05.22__21.12.35
# TARGET: PowerShell 7.6.1 LTS
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
# AI INSTRUCTIONS: 
# 1. HEADER: Update Version comment.
#    - VERSIONING: Update using CHICAGO TIME (Central Time). 
#    - CRITICAL: Do not use AI system time. Use the time provided in the most 
#      recent user prompt or link (Ref: https://www.timeanddate.com/worldclock/usa/chicago).
#    - STAMP ACCURACY: Ensure the minutes match the current Chicago clock exactly.
# 2. DO NOT modify or refactor any code inside <PROTECTED> tags.
# 3. SCRIPT OUTPUT:
#    - When printing the script only print snippets unless asked for entire script.
#    - Always use a codebox with a copy button.
# 4. VERBATIM ANCHOR PROTOCOL:
#    - To facilitate "Find" in Notepad++, always provide "Verbatim Anchors."
#    - "Verbatim Anchors" are the exact lines of existing code immediately BEFORE and AFTER the insertion point.
#    - Do not summarize, truncate, or refactor the existing code used as an anchor.
#    - Copy the existing spaces, comments, and symbols exactly as they appear in the file.
# ==============================================================================
# </PROTECTED>
<#
.SYNOPSIS
    Compares .mkv file counts between source folders and their corresponding _updated folders.
    Supports sending multiple specific folders, parent folders, or running locally.
    Outputs all data strictly matching native Windows Explorer alphanumeric sort order.
#>

$Title = "MKV Folder Sync Auditor"
[Console]::Title = $Title

# 1. Beginning Prompt
Clear-Host
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "         $Title initialized" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press [Enter] to begin comparing MKV counts"
Write-Host ""

$Mismatches = [System.Collections.Generic.List[PSObject]]::new()
$UnpairedFolders = [System.Collections.Generic.List[PSObject]]::new()
$TotalCheckedPairs = 0

# C-Sharp signature to hook into the native Windows StrCmpLogicalW sorting algorithm
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
Add-Type -TypeDefinition $WindowsSortCode

# Helper function to sort objects exactly like Windows File Explorer
function Sort-AsWindows {
    param(
        [Parameter(Mandatory=$true)]
        [System.Collections.Generic.List[PSObject]]$InputList,
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

# Helper function to audit a specific pair of directories
function Invoke-FolderComparison {
    param (
        [System.IO.DirectoryInfo]$SourceDir,
        [System.IO.DirectoryInfo]$UpdatedDir
    )
    $script:TotalCheckedPairs++
    
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

# 2. Parse Input Arguments
$ValidPassedPaths = @()
if ($args.Count -gt 0) {
    foreach ($arg in $args) {
        if (Test-Path -Path $arg -PathType Container) {
            $ValidPassedPaths += Get-Item -LiteralPath $arg
        }
    }
}

# 3. Determine Execution Mode Dynamically
$ProcessedAsPairs = $false

if ($ValidPassedPaths.Count -gt 0) {
    # Check if any of the passed folders contain "_updated" or have a twin that does
    $HasDirectPairs = $false
    foreach ($Path in $ValidPassedPaths) {
        if ($Path.Name -like "*_updated") {
            $HasDirectPairs = $true
            break
        } else {
            $ExpectedUpdatedName = "$($Path.Name)_updated"
            if ($ValidPassedPaths.Name -contains $ExpectedUpdatedName) {
                $HasDirectPairs = $true
                break
            }
        }
    }

    # --- MODE A: Direct Folder Selection ---
    if ($HasDirectPairs) {
        $ProcessedAsPairs = $true
        
        $PairedPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $SourceFolders = $ValidPassedPaths | Where-Object { $_.Name -notlike "*_updated" }

        foreach ($Source in $SourceFolders) {
            $ExpectedUpdatedName = "$($Source.Name)_updated"
            $Updated = $ValidPassedPaths | Where-Object { $_.Name -eq $ExpectedUpdatedName }

            if ($Updated) {
                Invoke-FolderComparison -SourceDir $Source -UpdatedDir $Updated
                [void]$PairedPaths.Add($Source.FullName)
                [void]$PairedPaths.Add($Updated.FullName)
            }
        }

        # Identify orphans
        foreach ($Path in $ValidPassedPaths) {
            if (-not $PairedPaths.Contains($Path.FullName)) {
                $MissingTwinType = $Path.Name -like "*_updated" ? "Base Folder" : "Updated Folder (_updated)"
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
            Where-Object { $_.Name -notlike "*_updated" }

        foreach ($Source in $SourceFolders) {
            $UpdatedPath = Join-Path -Path $Target.FullName -ChildPath "$($Source.Name)_updated"
            
            if (Test-Path -Path $UpdatedPath -PathType Container) {
                $UpdatedDir = Get-Item -LiteralPath $UpdatedPath
                Invoke-FolderComparison -SourceDir $Source -UpdatedDir $UpdatedDir
            }
        }
    }
}

# 4. Display Results
Write-Host "----------------------------------------------------" -ForegroundColor Gray
Write-Host "Audit Results:" -ForegroundColor White
Write-Host "----------------------------------------------------"

# Display Mismatches (Sorted with Windows Natural Sort)
if ($TotalCheckedPairs -gt 0) {
    if ($Mismatches.Count -eq 0) {
        Write-Host "All evaluated folders match! Checked $TotalCheckedPairs pair(s) perfectly." -ForegroundColor Green
    } else {
        Write-Host "Found $($Mismatches.Count) mismatching folder pair(s) out of $TotalCheckedPairs checked:`n" -ForegroundColor Red
        
        $SortedMismatches = Sort-AsWindows -InputList $Mismatches -PropertyName "FolderName"
        foreach ($Item in $SortedMismatches) {
            Write-Host "[-] Directory: " -NoNewline -ForegroundColor Yellow
            Write-Host $Item.FolderName -ForegroundColor White
            Write-Host "    -> Base Folder Total:    $($Item.SourceCount) MKV(s)" -ForegroundColor Gray
            Write-Host "    -> Updated Folder Total: $($Item.UpdatedCount) MKV(s)" -ForegroundColor Gray
            
            if ($Item.MissingInUpdated) {
                Write-Host "    -> Missing from Updated folder:" -ForegroundColor Red
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

# 5. Ending Prompt
Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "         Audit processing complete." -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press [Enter] to exit the script"