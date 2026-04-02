
function Install-CDirectory
{
    <#
    .SYNOPSIS
    Creates a directory, if it doesn't exist.

    .DESCRIPTION
    The `Install-CDirectory` function creates a directory. If the directory already exists, it does nothing. If any
    parent directories don't exist, they are created, too.

    To return a `DirectoryInfo` object for the directory, use the `-PassThru` switch.

    .EXAMPLE
    Install-CDirectory -Path 'C:\Projects\Carbon'

    Demonstrates how to use create a directory. In this case, the directories `C:\Projects` and `C:\Projects\Carbon`
    will be created if they don't exist.
    #>
    [CmdletBinding()]
    param(
        # The path to the directory to create.
        [Parameter(Mandatory)]
        [String] $Path,

        # If set, returns a `DirectoryInfo` object for the directory.
        [switch] $PassThru
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not (Test-Path -Path $Path -PathType Container))
    {
        New-Item -Path $Path -ItemType 'Directory' | Out-String | Write-Verbose
    }

    if ($PassThru)
    {
        Get-Item -LiteralPath $Path
    }
}
