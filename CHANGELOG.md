# 1.0.1

* Adding Guid to `Carbon.FileSystem.psd1` which is needed to publish to PSGallery.

# 1.0.0

* Added `Get-FileHardLink` which is used to retrieve hard link targets.  This fixes a breaking change from Windows PowerShell where the `Target` property is not populated in PowerShell Core when using `Get-Item` to retrieve a previously linked file.