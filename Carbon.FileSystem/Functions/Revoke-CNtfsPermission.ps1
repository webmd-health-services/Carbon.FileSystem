
function Revoke-CNtfsPermission
{
    <#
    .SYNOPSIS
    Revokes *explicit* permissions on folders and files.

    .DESCRIPTION
    Revokes all of user/group's *explicit* permissions on a folder or file. Only explicit permissions are considered;
    inherited permissions are ignored.

    If the identity doesn't have permission, nothing happens, not even errors written out.

    .LINK
    Get-CNtfsPermission

    .LINK
    Grant-CNtfsPermission

    .LINK
    Test-CNtfsPermission

    .EXAMPLE
    Revoke-CNtfsPermission -Identity ENTERPRISE\Engineers -Path 'C:\EngineRoom'

    Demonstrates how to revoke all of the 'Engineers' permissions on the `C:\EngineRoom` directory.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The folder or file path on which the permissions should be revoked.
        [Parameter(Mandatory)]
        [String] $Path,

        # The identity losing permissions.
        [Parameter(Mandatory)]
        [String] $Identity
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Revoke-CPermission @PSBoundParameters
}
