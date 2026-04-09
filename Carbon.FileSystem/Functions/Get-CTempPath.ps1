
function Get-CTempPath
{
    <#
    .SYNOPSIS
    Gets the path to the current user's temporary directory.

    .DESCRIPTION
    The `Get-CTempPath` function gets the path to the current user's temporary directory, as returned by
    `[IO.Path]::GetTempPath()`, which works across operating systems. The path is not guaranteed to actually exist. To
    ensure the temp path exists, use the `-Create` switch, and `Get-CTempPath` will ensure the path it returns exists.

    On Windows, the `System.IO.Path.GetTempPath()` function uses the [GetTempPath2
    function](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-gettemppath2a), which, for
    non-system processes, checks for the existence of environment variables in the following order and uses the first
    path found:

    * `TMP`
    * `TEMP`
    * `USERPROFILE`
    * The Windows directory

    For system processes, returns the value of the `SystemTemp` environment variable if it is set, or
    `C:\Windows\SystemTemp` if it is not.

    On Linux and macOS, returns the value of the `TMPDIR` environment variable if it is set, or `/tmp/` if it is not.

    .EXAMPLE
    Get-CTempPath

    Demonstrates how to get the path to the current user's temporary directory.
    #>
    [CmdletBinding()]
    param(
        # If set, and the temp path does not exist, it is created.
        [switch] $Create
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $path = [IO.Path]::GetTempPath()

    if ($Create)
    {
        Install-CDirectory -Path $path
    }

    return $path
}
