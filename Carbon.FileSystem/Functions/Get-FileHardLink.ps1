
function Get-FileHardLink
{
    param(
        [Parameter(Mandatory)]
        [String] $Path
    )

    $sbPath = [Text.StringBuilder]::New([Carbon.FileSystem.Kernel32]::MAX_PATH)
    $charCount = [uint]$sbPath.Capacity; # in/out character-count variable for the WinAPI calls.
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
        Write-Warning 'Invalid handle.'
        return
    }
  
    do
    {
        Join-Path -Path $volume -ChildPath $sbPath.ToString() | Write-Output # Add the full path to the result list.
        $charCount = [uint]$sbPath.Capacity; # Prepare for the next FindNextFileNameW() call.
    }
    while( [Carbon.FileSystem.Kernel32]::FindNextFileNameW($findHandle, [ref]$charCount, $sbPath) )
    [void][Carbon.FileSystem.Kernel32]::FindClose($findHandle);
}