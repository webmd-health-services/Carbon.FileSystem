<!--markdownlint-disable MD012 no-multiple-blanks -->

# Carbon.FileSystem PowerShell Module

## Overview

Carbon.FileSystem is a PowerShell module for managing the Windows file system.


## System Requirements

* Windows PowerShell 5.1 and .NET 4.6.1+
* PowerShell Core 6+


## Installing

To install globally:

```powershell
Install-Module -Name 'Carbon.FileSystem'
Import-Module -Name 'Carbon.FileSystem'
```

To install privately:

```powershell
Save-Module -Name 'Carbon.FileSystem' -Path '.'
Import-Module -Name '.\Carbon.FileSystem'
```

## Commands

### Get-CFsHardLink

Gets all the hardlinks to a path.

```powershell
Get-CFsHardlink -Path 'C:\Projects\some_file.txt'
```
