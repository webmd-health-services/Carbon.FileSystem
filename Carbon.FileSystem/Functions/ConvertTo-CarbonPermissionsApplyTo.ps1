
function ConvertTo-CarbonPermissionsApplyTo
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [AllowNull()]
        [ValidateSet('FolderOnly', 'FolderSubfoldersAndFiles', 'FolderAndSubfolders', 'FolderAndFiles',
            'SubfoldersAndFilesOnly', 'SubfoldersOnly', 'FilesOnly')]
        [String] $ApplyTo
    )

    process
    {
        $map = @{
            'FolderOnly' = 'ContainerOnly';
            'FolderSubfoldersAndFiles' = 'ContainerSubcontainersAndLeaves';
            'FolderAndSubfolders' = 'ContainerAndSubcontainers';
            'FolderAndFiles' = 'ContainerAndLeaves';
            'SubfoldersAndFilesOnly' = 'SubcontainersAndLeavesOnly';
            'SubfoldersOnly' = 'SubcontainersOnly';
            'FilesOnly' = 'LeavesOnly';
        }

        if (-not $ApplyTo)
        {
            return
        }

        return $map[$ApplyTo]
    }
}
