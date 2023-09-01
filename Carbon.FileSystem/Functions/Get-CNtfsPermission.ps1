
function Get-CNtfsPermission
{
    <#
    .SYNOPSIS
    Gets the permissions (access control rules) for a file or directory.

    .DESCRIPTION
    Permissions for a specific identity can also be returned. Access control entries are for a path's discretionary
    access control list.

    To return inherited permissions, use the `Inherited` switch.  Otherwise, only non-inherited (i.e. explicit)
    permissions are returned.

    .OUTPUTS
    System.Security.AccessControl.FileSystemAccessRule.

    .LINK
    Get-CNtfsPermission

    .LINK
    Grant-CNtfsPermission

    .LINK
    Revoke-CNtfsPermission

    .LINK
    Test-CNtfsPermission

    .EXAMPLE
    Get-CNtfsPermission -Path 'C:\Windows'

    Returns `System.Security.AccessControl.FileSystemAccessRule` objects for all the non-inherited rules on
    `C:\windows`.

    .EXAMPLE
    Get-CNtfsPermission -Path 'C:\Windows' -Inherited

    Returns `System.Security.AccessControl.RegistryAccessRule` objects for all the inherited and non-inherited rules on
    `hklm:\software`.

    .EXAMPLE
    Get-CNtfsPermission -Path 'C:\Windows' -Idenity Administrators

    Returns `System.Security.AccessControl.FileSystemAccessRule` objects for all the `Administrators'` rules on
    `C:\windows`.
    #>
    [CmdletBinding()]
    [OutputType([Security.AccessControl.FileSystemAccessRule])]
    param(
        # The path to the file/directory whose permissions (i.e. access control rules) to return. Wildcards supported.
        [Parameter(Mandatory, ValueFromPipeline)]
        [String] $Path,

        # The identity whose permissiosn (i.e. access control rules) to return. By default, all non-inherited
        # permissions are returned.
        [String] $Identity,

        # Return inherited permissions in addition to explicit permissions.
        [switch] $Inherited
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        Get-CPermission @PSBoundParameters
    }
}
