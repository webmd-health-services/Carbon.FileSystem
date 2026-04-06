<!--markdownlint-disable MD012 no-multiple-blanks-->

# Carbon.FileSystem Changelog

## 1.2.0

### Upgrade Instructions

If upgrading from Carbon, inspect usages of `Install-CDirectory`, `Uninstall-CDirectory`, and `New-CTempDirectory`.

* Inspect usages of `Install-CDirectory` for file paths. In Carbon, `Install-CDirectory` would ignore when the path to
  install was to a file. Now, it will write an error. Update usages with the `-Force` switch to delete the file or
  `-ErrorAction Ignore`
* `Uninstall-CDirectory` no longer supports wildcard characters in paths. Updates usages with wildcard pathsto use
  PowerShell's native cmdlets to convert wildcard paths into actual paths and pipe those into `Uninstall-CDirectory`,
  e.g. `Get-Item -Path $paths | Uninstall-CDirectory`.
* Inspect usages of `Uninstall-CDirectory` for file paths. In Carbon, `Uninstall-CDirectory` would ignore file
  paths. Now, it will write an error. To force it to delete files, too, use the new `-Force` switch. To ignore when it
  tries to delete files, use `-ErrorAction Ignore` .

### Added

* `Set-CNtfsOwner` function for setting the owner of an NTFS file or directory.
* `Install-CDirectory` functon for creating directories. Migrated from Carbon.
* `New-CTempDirectory` function for creating temp directories. Migrated from Carbon.
* `Uninstall-CDirectory` function for removing directories. Migrated from Carbon.
* `Get-CTempPath` function for getting the current user's temp path.
* `Set-CTempPath` function for setting the current user's temp path.

If you're migrating from Carbon, this functionality was added:

`Install-CDirectory`:

* `-PassThru` switch to return an `[IO.DirectoryInfo]` object for the directory
* `-Force` switch to replace an existing file with a directory
* Linux and macOS support
* accept paths from the pipeline
* `-WhatIf` support

`Uninstall-CDirectory`:

* `-Force` switch to force it to delete a file
* Linux and macOS support
* accept directory objects and paths from the pipeline
* `-WhatIf` support

`New-CTempDirectory`:

* Linux and macOS support

### Changed

If migrating from Carbon, this functionality was changed:

* `Install-CDirectory` now writes an error if the path is to a file. Use the `-Force` switch to replace the file with a
  directory.
* `Uninstall-CDirectory` no longer supports wildcard patterns. Use PowerShell's native cmdlets to convert any paths with
  wildcards to actual paths and pipe those to `Uninstall-CDirectory`, e.g.
  `Get-Item -Path $paths | Uninstall-CDirectory`.

### Deprecated

Import-Carbon.FileSystem.ps1. Use `Import-Module` instead.

### Fixed

If migrating from Carbon, this functionalty was fixed:

* `Install-CDirectory` would fail to create a directory if the path contained wildcard characters that would match the
  path of an existing file or directory. Wildcard patterns in paths are no longer supported.

## 1.1.2

> Released 20 Dec 2024

Updating dependencies.

## 1.1.1

> Released 3 Dec 2024

Reducing directory nesting of internal, private, nested modules.

## 1.1.0

> Released 10 Jun 2024

### Upgrade Instructions

Added `Get-CNtfsPermission`, `Grant-CNtfsPermission`, `Revoke-CNtfsPermission`, and `Test-CNtfsPermission`, migrated
from Carbon's `Get-CPermission`, `Grant-CPermission`, `Revoke-CPermission`, and `Test-CPermission`. If you are switching
from Carbon to Carbon.FileSystem, do the following:

* Rename usages of `Get-CPermission`, `Grant-CPermission`, `Revoke-CPermission`, and `Test-CPermission` to
  `Get-CNtfsPermission`, `Grant-CNtfsPermission`, `Revoke-CNtfsPermission`, and `Test-CNtfsPermission`.
* Replace usages of the `Test-CNtfsPermission` function's `-Exact` switch to `-Strict`.
* Using the table below, replace usages of `Grant-CNtfsPermission` and `Test-CNtfsPermission` arguments in the left
  column with the new arguments from the right column.

  | Old Argument                                         | New Argument(s)
  |------------------------------------------------------|---------------------------------------------------------------------
  | `-ApplyTo Container`                                 | `-ApplyTo FolderOnly`
  | `-ApplyTo SubContainers`                             | `-ApplyTo SubfoldersOnly`
  | `-ApplyTo Leaves`                                    | `-ApplyTo FilesOnly`
  | `-ApplyTo ChildContainers`                           | `-ApplyTo SubfoldersOnly -OnlyApplyToChildFilesAndFolders`
  | `-ApplyTo ChildLeaves`                               | `-ApplyTo FilesOnly -OnlyApplyToChildFilesAndFolders`
  | `-ApplyTo ContainerAndSubContainers`                 | `-ApplyTo FolderAndSubfolders`
  | `-ApplyTo ContainerAndLeaves`                        | `-ApplyTo FolderAndFiles`
  | `-ApplyTo SubContainerAndLeaves`                     | `-ApplyTo SubfoldersAndFilesOnly`
  | `-ApplyTo ContainerAndChildContainers`               | `-ApplyTo FolderAndSubfolders -OnlyApplyToChildFilesAndFolders`
  | `-ApplyTo ContainerAndChildLeaves`                   | `-ApplyTo FolderAndFiles -OnlyApplyToChildFilesAndFolders`
  | `-ApplyTo ContainerAndChildContainersAndChildLeaves` | `-ApplyTo FolderSubfoldersAndFiles -OnlyApplyToChildFilesAndFolders`
  | `-ApplyTo ContainerAndSubContainersAndLeaves`        | `-ApplyTo FolderSubfoldersAndFiles`
  | `-ApplyTo ChildContainersAndChildLeaves`             | `-ApplyTo SubfoldersAndFilesOnly -OnlyApplyToChildFilesAndFolders`

### Added

* `Get-CNtfsHardLink`. Replaces `Get-FileHardLink`.

### Deprecated

* Function `Get-FileHardLink`. Use the new `Get-CNtfsHardLink` function.


## 1.0.1

> Released 5 May 2022

Adding Guid to `Carbon.FileSystem.psd1` which is needed to publish to PSGallery.


## 1.0.0

> Released 5 May 2022

* Added `Get-CNtfsHardLink` which is used to retrieve hard link targets.  This fixes a breaking change from Windows
  PowerShell where the `Target` property is not populated in PowerShell Core when using `Get-Item` to retrieve a
  previously linked file.
