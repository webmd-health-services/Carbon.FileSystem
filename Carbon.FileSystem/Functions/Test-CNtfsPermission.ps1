
function Test-CNtfsPermission
{
    <#
    .SYNOPSIS
    Tests if permissions are set on a folder or file.

    .DESCRIPTION
    The `Test-CNtfsPermission` function tests if an identity has a permission on a file/folder. Pass the path to check
    to the `Path` parameter, the user/group name to the `Identity` parameter, and the permission to check for to the
    `Permission` parameter. If the user/group has the given permission on the given path, the function returns `$true`,
    otherwise it returns `$false`.

    Inherited permissions are *not* checked by default. To check inherited permission, use the `-Inherited` switch.

    By default, the permission check is not exact, i.e. the user may have additional permissions to what you're
    checking.  If you want to make sure the user has *exactly* the permission you want, use the `-Strict` switch.
    Please note that by default, NTFS will automatically add/grant `Synchronize` permission on an item, which is handled
    by this function.

    You can also test how the permission is inherited by using the `ApplyTo` and `OnlyApplyToChildFilesAndFolders`
    parameters.

    .OUTPUTS
    System.Boolean.

    .LINK
    Get-CNtfsPermission

    .LINK
    Grant-CNtfsPermission

    .LINK
    Revoke-CNtfsPermission

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx

    .EXAMPLE
    Test-CNtfsPermission -Identity 'STARFLEET\JLPicard' -Permission 'FullControl' -Path 'C:\Enterprise\Bridge'

    Demonstrates how to check that Jean-Luc Picard has `FullControl` permission on the `C:\Enterprise\Bridge`.

    .EXAMPLE
    Test-CNtfsPermission -Identity 'STARFLEET\Worf' -Permission 'Write' -ApplyTo 'FolderOnly' -Path 'C:\Enterprise\Brig'

    Demonstrates how to test for inheritance/propogation flags, in addition to permissions.
    #>
    [CmdletBinding(DefaultParameterSetName='SkipAppliesToFlags')]
    param(
        # The path to a folder/file on which the permissions should be checked.
        [Parameter(Mandatory)]
        [String] $Path,

        # The user or group name whose permissions to check.
        [Parameter(Mandatory)]
        [String] $Identity,

        # The permission to test for: e.g. FullControl, Read, etc. See
        # [System.Security.AccessControl.FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx)
        # for the list of rights with descriptions.
        [Parameter(Mandatory)]
        [FileSystemRights[]] $Permission,

        # Checks how the permission is inherited. By default, the permission's inheritance is ignored.
        #
        # Valid values are:
        #
        # * FolderOnly
        # * FolderSubfoldersAndFiles
        # * FolderAndSubfolders
        # * FolderAndFiles
        # * SubfoldersAndFilesOnly
        # * SubfoldersOnly
        # * FilesOnly
        [Parameter(Mandatory, ParameterSetName='TestAppliesToFlags')]
        [ValidateSet('FolderOnly', 'FolderSubfoldersAndFiles', 'FolderAndSubfolders', 'FolderAndFiles',
            'SubfoldersAndFilesOnly', 'SubfoldersOnly', 'FilesOnly')]
        [String] $ApplyTo,

        # Checks that the permissions are only applied to child files and folders. By default, the permission's
        # inheritnace is ignored.
        [Parameter(ParameterSetName='TestAppliesToFlags')]
        [switch] $OnlyApplyToChildFilesAndFolders,

        # Include inherited permissions in the check.
        [switch] $Inherited,

        # Check for the exact permissions and how the permission is applied, i.e. make sure the identity has
        # *only* the permissions you specify.
        [switch] $Strict
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ($PSCmdlet.ParameterSetName -eq 'TestAppliesToFlags')
    {
        if ($ApplyTo)
        {
            $PSBoundParameters['ApplyTo'] = $ApplyTo | ConvertTo-CarbonPermissionsApplyTo
        }
        $PSBoundParameters.Remove('OnlyApplyToChildFilesAndFolders') | Out-Null
        $PSBoundParameters['OnlyApplyToChildren'] = $OnlyApplyToChildFilesAndFolders
    }

    Test-CPermission @PSBoundParameters
}

