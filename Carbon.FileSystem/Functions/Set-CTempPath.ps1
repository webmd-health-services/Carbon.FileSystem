
function Set-CTempPath
{
    <#
    .SYNOPSIS
    Sets the path to the current user's temp directory.

    .DESCRIPTION
    The `Set-CTempPath` function sets the path to the current user's temp directory. Pass the path for the temp
    directory to the `Path` parameter. On Windows, for non-system processes, sets the `TMP` environment variable to the
    path. For system processes, sets the `SystemTemp` environment variable. On Linux and macOS, sets the `TMPDIR`
    environment variable. If path is a relative path, it will be assumed to be relative to PowerShell's current
    directory (i.e. the return value of `Get-Location`), and converted to an absolute path.

    Use the `-Create` switch to create the temp path if it doesn't exist.

    Note that on Windows, if setting the system user's temp path, the directory should only be accessible to the system
    user: ACL inheritance should be turned off and the only permission granted should be full control to the SYSTEM
    account. Otherwise, unprivileged users may be able to view sensitive files.

    .EXAMPLE
    Set-CTempPath -Path 'C:\MyTemp'

    Demonstrates how to set the current user's temp path by passing the path to the `Path` parameter.

    .EXAMPLE
    Set-CTempPath -Path 'C:\MyTemp' -Create

    Demonstrates how to ensure the temp path exists by using the `-Create` switch.

    .EXAMPLE
    'C:\MyTemp' | Set-CTempPath

    Demonstrates that you can pipe the path to `Set-CTempPath`.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The path to set as the current user's temp path. Can be piped in or passed as an argument. If a relative path
        # is passed, it is assumed to be relative to PowerShell's current directory (i.e. the return value of
        # `Get-Location`), and converted to an absolute path.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $Path,

        # If set, creates the temp path if it doesn't exist.
        [switch] $Create
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not [IO.Path]::IsPathRooted($Path))
        {
            $Path = Join-Path -Path (Get-Location) -ChildPath $Path
        }

        $Path = [IO.Path]::GetFullPath($Path)

        $Path = Join-Path -Path $Path -ChildPath ([IO.Path]::DirectorySeparatorChar)

        if ($Create)
        {
            Install-CDirectory -Path $Path
        }

        $envVarName  = 'TMPDIR'

        if ($IsWindows)
        {
            if ([Security.Principal.WindowsIdentity]::GetCurrent().IsSystem)
            {
                $envVarName = 'SystemTemp'
            }
            else
            {
                $envVarName = 'TMP'
            }
        }

        $currentTempPath = Get-CTempPath
        if ($currentTempPath -eq $Path)
        {
            Write-Verbose "Temp path environment variable ${envVarName} already set to ""${Path}""."
            return
        }

        $action = "Creating"
        if ((Test-Path -Path "env:${envVarName}"))
        {
            $action = "Setting"
        }

        $target = "${envVarName} environment variable"
        $actionMsg = "$($action.ToLowerInvariant()) to ""${Path}"""
        if ($PSCmdlet.ShouldProcess($target, $actionMsg))
        {
            $msg = "${action} temp path environment variable ${envVarName} to ""${Path}""."
            Write-Information $msg -InformationAction $InformationPreference
            [Environment]::SetEnvironmentVariable($envVarName, $Path, [EnvironmentVariableTarget]::Process)
        }
    }
}