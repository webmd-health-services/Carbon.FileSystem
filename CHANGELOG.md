<!--markdownlint-disable MD012 no-multiple-blanks-->

# Carbon.FileSystem Changelog

## 1.1.1

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
