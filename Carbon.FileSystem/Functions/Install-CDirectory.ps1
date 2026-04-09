
function Install-CDirectory
{
    <#
    .SYNOPSIS
    Creates a directory, if it doesn't exist.

    .DESCRIPTION
    The `Install-CDirectory` function creates a directory. If the directory already exists, it does nothing. If any
    parent directories don't exist, they are created, too.

    To return a `DirectoryInfo` object for the directory, use the `-PassThru` switch.

    If the path exists and is a file, writes an error. Use the `-Force` switch to delete the file and create the
    directory in its place.

    .EXAMPLE
    Install-CDirectory -Path 'C:\Projects\Carbon'

    Demonstrates how to use create a directory. In this case, the directories `C:\Projects` and `C:\Projects\Carbon`
    will be created if they don't exist.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The path to the directory to create.
        [Parameter(Mandatory, ValueFromPipeline)]
        [String] $Path,

        # If set, returns a `DirectoryInfo` object for the directory.
        [switch] $PassThru,

        # If set and the target path exists and is a file, deletes the file and creates the directory in its place.
        # Otherwise, writes an error that the path exists and is a file.
        [switch] $Force
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if ((Test-Path -LiteralPath $Path -PathType Leaf))
        {
            if (-not $Force)
            {
                $msg = "Failed to install directory ""${Path}"" because that path exists and is a file. Use the -Force " +
                       'switch to replace the file with a directory.'
                Write-Error $msg -ErrorAction $ErrorActionPreference
                return
            }

            Write-Information "Deleting file ""${Path}""." -InformationAction $InformationPreference
            Remove-Item -LiteralPath $Path -Force
        }

        if (-not (Test-Path -LiteralPath $Path -PathType Container))
        {
            Write-Information "Creating directory ""${Path}""." -InformationAction $InformationPreference
            New-Item -Path $Path -ItemType 'Directory' -Force | Out-String | Write-Verbose
        }

        if ($PassThru -and (Test-Path -LiteralPath $Path))
        {
            Get-Item -LiteralPath $Path
        }
    }
}
