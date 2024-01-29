function Get-CNtfsHardLink
{
    <#
    .SYNOPSIS
    Retrieves hard link targets from a file.

    .DESCRIPTION
    Get-CNtfsHardLink retrieves hard link targets from a file given a file path. This fixes compatibility issues between
    Windows PowerShell and PowerShell Core when retrieving targets from a hard link.

    .EXAMPLE
    Get-CNtfsHardLink -Path $Path

    Demonstrates how to retrieve a hard link given a file path.
    #>
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

    try
    {
        $sbPath = [Text.StringBuilder]::New([Carbon.FileSystem.Kernel32]::MAX_PATH)
        $charCount = [uint32]$sbPath.Capacity; # in/out character-count variable for the WinAPI calls.
        # Get the volume (drive) part of the target file's full path (e.g., @"C:\")
        [void][Carbon.FileSystem.Kernel32]::GetVolumePathName($Path, $sbPath, $charCount)
        $volume = $sbPath.ToString();
        # Trim the trailing "\" from the volume path, to enable simple concatenation
        # with the volume-relative paths returned by the FindFirstFileNameW() and FindFirstFileNameW() functions,
        # which have a leading "\"
        $volume = $volume.Substring(0, $volume.Length - 1);
        # Loop over and collect all hard links as their full paths.
        [IntPtr]$findHandle = [IntPtr]::Zero
        $findHandle = [Carbon.FileSystem.Kernel32]::FindFirstFileNameW($Path, 0, [ref]$charCount, $sbPath)
        if( [Carbon.FileSystem.Kernel32]::INVALID_HANDLE_VALUE -eq $findHandle)
        {
            $errorCode = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
            $msg = "Failed to find hard links to path ""$($Path | Split-Path -Relative)"": the system error code is ""$($errorCode)""."
            Write-Error $msg -ErrorAction $ErrorActionPreference
            return
        }

        do
        {
            Join-Path -Path $volume -ChildPath $sbPath.ToString() | Write-Output # Add the full path to the result list.
            $charCount = [uint32]$sbPath.Capacity; # Prepare for the next FindNextFileNameW() call.
        }
        while( [Carbon.FileSystem.Kernel32]::FindNextFileNameW($findHandle, [ref]$charCount, $sbPath) )
        [void][Carbon.FileSystem.Kernel32]::FindClose($findHandle);
    }
    catch
    {
        Write-Error -Message $_ -ErrorAction $ErrorActionPreference
    }
}

function Get-FileHardLink
{
    <#
    .SYNOPSIS
    ***OBSOLETE.*** Use Get-CNtfsHardLink instead.

    .DESCRIPTION
    ***OBSOLETE.*** Use Get-CNtfsHardLink instead.

    .EXAMPLE
    Get-CNtfsHardLink -Path $Path

    Demonstrates that you should use `Get-CNtfsHardLink` instead.
    #>
    [CmdletBinding()]
    param(
        # The path whose hard links to get/return. Must exist.
        [Parameter(Mandatory)]
        [String] $Path
    )

    $msg = 'The Get-FileHardLink function is obsolete and will removed in the next major version of ' +
           'Carbon.FileSystem. Please use Get-CNtfsHardLink instead.'
    Write-Warning -Message $msg

    Get-CNtfsHardLink @PSBoundParameters
}