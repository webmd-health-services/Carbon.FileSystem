<!--markdownlint-disable MD012 no-multiple-blanks-->

# Carbon.FileSystem Changelog

## 1.1.0

### Upgrade Instructions

Added `Get-CNtfsPermission`, `Grant-CNtfsPermission`, `Revoke-CNtfsPermission`, and `Test-CNtfsPermission`, migrated
from Carbon's `Get-CPermission`, `Grant-CPermission`, `Revoke-CPermission`, and `Test-CPermission`. If you are switching
from Carbon to Carbon.FileSystem, do the following:

* Rename usages of `Get-CPermission`, `Grant-CPermission`, `Revoke-CPermission`, and `Test-CPermission` to
  `Get-CNtfsPermission`, `Grant-CNtfsPermission`, `Revoke-CNtfsPermission`, and `Test-CNtfsPermission`.
* Replace usages of the `Test-CNtfsPermission` function's `-Exact` switch to `-Strict`.
* Using the table below, replace usages of `Grant-CNtfsPermission` and `Test-CNtfsPermission` arguments in the left
  column with the new arguments from the right column.
  | Old Argument                                            | New Argument(s)
  |---------------------------------------------------------|---------------------------------------------------------
  | `-Permission Container`                                 | `-Permission FolderOnly`
  | `-Permission SubContainers`                             | `-Permission SubfoldersOnly`
  | `-Permission Leaves`                                    | `-Permission FilesOnly`
  | `-Permission ChildContainers`                           | `-Permission SubfoldersOnly -OnlyApplyToChildFilesAndFolders`
  | `-Permission ChildLeaves`                               | `-Permission FilesOnly -OnlyApplyToChildFilesAndFolders`
  | `-Permission ContainerAndSubContainers`                 | `-Permission FolderAndSubfolders`
  | `-Permission ContainerAndLeaves`                        | `-Permission FolderAndFiles`
  | `-Permission SubContainerAndLeaves`                     | `-Permission SubfoldersAndFilesOnly`
  | `-Permission ContainerAndChildContainers`               | `-Permission FolderAndSubfolders -OnlyApplyToChildFilesAndFolders`
  | `-Permission ContainerAndChildLeaves`                   | `-Permission FolderAndFiles -OnlyApplyToChildFilesAndFolders`
  | `-Permission ContainerAndChildContainersAndChildLeaves` | `-Permission FolderSubfoldersAndFiles -OnlyApplyToChildFilesAndFolders`
  | `-Permission ContainerAndSubContainersAndLeaves`        | `-Permission FolderSubfoldersAndFiles`
  | `-Permission ChildContainersAndChildLeaves`             | `-Permission SubfoldersAndFilesOnly -OnlyApplyToChildFilesAndFolders`



## 1.0.1

> Released 5 May 2022

Adding Guid to `Carbon.FileSystem.psd1` which is needed to publish to PSGallery.


## 1.0.0

> Released 5 May 2022

* Added `Get-FileHardLink` which is used to retrieve hard link targets.  This fixes a breaking change from Windows
  PowerShell where the `Target` property is not populated in PowerShell Core when using `Get-Item` to retrieve a
  previously linked file.
