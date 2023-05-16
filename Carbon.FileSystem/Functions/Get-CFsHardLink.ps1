<#
.SYNOPSIS
Retrieves hard link targets from a file.

.DESCRIPTION
Get-CFsHardLink retrieves hard link targets from a file given a file path. This fixes compatibility issues between
Windows PowerShell and PowerShell Core when retrieving targets from a hard link.

.EXAMPLE
Get-CFsHardLink -Path $Path

Demonstrates how to retrieve a hard link given a file path.
#>
function Get-CFsHardLink
{
    [CmdletBinding()]
    param(
        # The path whose hard links to get/return. Must exist.
        [Parameter(Mandatory)]
        [String] $Path
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if( -not (Resolve-Path -LiteralPath $Path) )
    {
        return
    }

    $sourceDrive = $Path | Resolve-Path | Select-Object -ExpandProperty 'ProviderPath' | Split-Path -Qualifier
    if (-not $sourceDrive)
    {
        return
    }

    Invoke-KernelFindFileName -Path $Path |
        ForEach-Object { Join-Path -Path $sourceDrive -ChildPath $_ } |
        Write-Output
}
