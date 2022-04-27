# Overview

The "Carbon.FileSystem" module currently only has one function `Get-FileHardLink` which is used to retrieve hard link targets.  This fixes a breaking change from Windows PowerShell where the `Target` property is not populated in PowerShell Core when using `Get-Item` to retrieve a previously linked file.

# System Requirements

* Windows PowerShell 5.1 and .NET 4.6.1+
* PowerShell Core 6+

# Installing

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

# Commands
