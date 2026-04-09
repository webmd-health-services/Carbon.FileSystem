
function Uninstall-CDirectory
{
    <#
    .SYNOPSIS
    Removes a directory, if it exists.

    .DESCRIPTION
    The `Uninstall-CDirectory` function removes a directory. If the directory doesn't exist, it does nothing. If the
    directory has any files or sub-directories, you will be prompted to confirm the deletion of the directory and all
    its contents. To avoid the prompt, use the `-Recurse` switch.

    If the path to delete is to a file, the function writes an error. Use the `-Force` switch to delete the path even
    if it is a file.

    .EXAMPLE
    Uninstall-CDirectory -Path 'C:\Projects\Carbon'

    Demonstrates how to remove/delete a directory. In this case, the directory `C:\Projects\Carbon` will be deleted, if
    it exists.

    .EXAMPLE
    Uninstall-CDirectory -Path 'C:\Projects\Carbon' -Recurse

    Demonstrates how to remove/delete a directory that has items in it. In this case, the directory `C:\Projects\Carbon`
    *and all of its files and sub-directories* will be deleted, if the directory exists.

    .EXAMPLE
    Get-ChildItem -Path 'C:\Projects' -Directory | Uninstall-CDirectory -Recurse

    Demonstrates that you can pipe paths or directory objects to `Uninstall-CDirectory`.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The path to the directory to delete. Wildcards *not* supported.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [String] $Path,

        # Delete the directory *and* everything under it.
        [switch] $Recurse,

        # Delete the directory even if it is a file.
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
                $msg = "Failed to delete directory ""${Path}"" because that path is a file. Use the -Force switch to " +
                       'delete that path even if it is a file.'
                Write-Error $msg -ErrorAction $ErrorActionPreference
                return
            }

            Write-Information "Deleting file ""${Path}""." -InformationAction $InformationPreference
            Remove-Item -LiteralPath $Path -Force
            return
        }

        if ((Test-Path -LiteralPath $Path -PathType Container))
        {
            Write-Information "Deleting directory ""${Path}""." -InformationAction $InformationPreference
            Remove-Item -LiteralPath $Path -Recurse:$Recurse
        }
    }
}
