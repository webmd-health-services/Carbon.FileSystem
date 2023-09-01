function Grant-CNtfsPermission
{
    <#
    .SYNOPSIS
    Grants permission on folders and files.

    .DESCRIPTION
    The `Grant-CNtfsPermission` functions grants permissions to folders and files. Pass the folder/file path to the
    `Path` parameter, the user/group name to the `Identity` parameter, and the permissions to the `Permission`
    parameter. By default, the permissions are applied to the folder and inherited to all its subfolders and files. To
    control how the permissions are applied, use the `ApplyTo` parameter. If you want permissions to only apply to child
    files and folders, use the `OnlyApplyToChildFilesAndFolders` switch.

    By default, an "Allow" permission is granted. To add a "Deny" permission, set the value of the `Type` parameter to
    `Deny`.

    All existing, non-inherited permissions for the given identity are removed first. If you want to preserve a
    user/group's existing permissions, use the `Append` switch.

    To remove *all* non-inherited permissions except the permission being granted, use the `Clear` switch.

    The permission is only granted if it doesn't exist. To always grant the permission, use the `Force` switch.

    To get the permission back as a `[System.Security.AccessControl.FileSystemAccessRule]` object, use the `PassThru`
    switch.

    .OUTPUTS
    System.Security.AccessControl.FileSystemAccessRule.

    .LINK
    Get-CNtfsPermission

    .LINK
    Revoke-CNtfsPermission

    .LINK
    Test-CNtfsPermission

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx

    .LINK
    http://msdn.microsoft.com/en-us/magazine/cc163885.aspx#S3

    .EXAMPLE
    Grant-CNtfsPermission -Identity ENTERPRISE\Engineers -Permission FullControl -Path C:\EngineRoom

    Grants the Enterprise's engineering group full control on the engine room.  Very important if you want to get
    anywhere.

    .EXAMPLE
    Grant-CNtfsPermission -Identity ENTERPRISE\Engineers -Permission FullControl -Path C:\EngineRoom -Clear

    Grants the Enterprise's engineering group full control on the engine room.  Any non-inherited, existing access rules
    are removed from `C:\EngineRoom`.

    .EXAMPLE
    Grant-CNtfsPermission -Identity BORG\Locutus -Permission FullControl -Path 'C:\EngineRoom' -Type Deny

    Demonstrates how to grant deny permissions on an objecy with the `Type` parameter.

    .EXAMPLE
    Grant-CNtfsPermission -Path C:\Bridge -Identity ENTERPRISE\Wesley -Permission 'Read' -ApplyTo ContainerAndSubContainersAndLeaves -Append
    Grant-CNtfsPermission -Path C:\Bridge -Identity ENTERPRISE\Wesley -Permission 'Write' -ApplyTo ContainerAndLeaves
    -Append

    Demonstrates how to grant multiple access rules to a single identity with the `Append` switch. In this case,
    `ENTERPRISE\Wesley` will be able to read everything in `C:\Bridge` and write only in the `C:\Bridge` directory, not
    to any sub-directory.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '')]
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([Security.AccessControl.FileSystemAccessRule])]
    param(
        # The folder/file path on which the permissions should be granted.
        [Parameter(Mandatory)]
        [String] $Path,

        # The user or group getting the permissions.
        [Parameter(Mandatory)]
        [String] $Identity,

        # The permissions to grant. See
        # [System.Security.AccessControl.FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx)
        # for the list of rights with descriptions.
        [Parameter(Mandatory)]
        [FileSystemRights[]] $Permission,

        # How to apply the permissions. The default is `FolderSubfoldersAndFiles`. Valid values are:
        #
        # * FolderOnly
        # * FolderSubfoldersAndFiles
        # * FolderAndSubfolders
        # * FolderAndFiles
        # * SubfoldersAndFilesOnly
        # * SubfoldersOnly
        # * FilesOnly
        [ValidateSet('FolderOnly', 'FolderSubfoldersAndFiles', 'FolderAndSubfolders', 'FolderAndFiles',
            'SubfoldersAndFilesOnly', 'SubfoldersOnly', 'FilesOnly')]
        [String] $ApplyTo = 'FolderSubfoldersAndFiles',

        # Only apply the permissions to files and/or folders within the folder. Don't set this if the Path parameter is
        # to a file.
        [switch] $OnlyApplyToChildFilesAndFolders,

        # The type of rule to apply, either `Allow` or `Deny`. The default is `Allow`, which will allow access to the
        # item. The other option is `Deny`, which will deny access to the item.
        [AccessControlType] $Type = [AccessControlType]::Allow,

        # Removes all non-inherited permissions on the item.
        [switch] $Clear,

        # Returns an object representing the permission created or set on the `Path`. The returned object will have a
        # `Path` propery added to it so it can be piped to any cmdlet that uses a path.
        [switch] $PassThru,

        # Grants permissions, even if they are already present.
        [switch] $Force,

        # When set, adds the permissions as a new access rule instead of replacing any existing access rules.
        [switch] $Append
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $PSBoundParameters.Remove('ApplyTo') | Out-Null
    $PSBoundParameters.Remove('OnlyApplyToChildFilesAndFolders') | Out-Null

    Add-FlagsArgument -Argument $PSBoundParameters `
                      -ApplyTo $ApplyTo `
                      -OnlyApplyToChildFilesAndFolders:$OnlyApplyToChildFilesAndFolders

    Grant-CPermission @PSBoundParameters
}
