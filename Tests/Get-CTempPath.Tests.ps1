
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeDiscovery {
    if (-not (Test-Path -Path 'variable:IsWindows'))
    {
        $script:IsWindows = $true
        $script:IsLinux = $script:IsMacOS = $false
    }
}

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon.FileSystem' -Resolve) -Verbose:$false
}

Describe 'Get-CTempPath' {
    It 'gets temp path' {
        Get-CTempPath | Should -Be ([IO.Path]::GetTempPath())
    }

    It 'creates temp directory' {
        $envVarName = 'TMPDIR'
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

        $originalTempPath = [NullString]::Value
        if (Test-Path -Path "env:${envVarName}")
        {
            $originalTempPath = [Environment]::GetEnvironmentVariable($envVarName, [EnvironmentVariableTarget]::Process)
        }

        $nonExistentTempPath =
            Join-Path -Path $TestDrive -ChildPath ([IO.Path]::GetRandomFileName() + [IO.Path]::DirectorySeparatorChar)

        [Environment]::SetEnvironmentVariable($envVarName, $nonExistentTempPath, [EnvironmentVariableTarget]::Process)
        try
        {
            $path = Get-CTempPath -Create
            $path | Should -Be $nonExistentTempPath
            [IO.Directory]::Exists($path) | Should -BeTrue
        }
        finally
        {
            [Environment]::SetEnvironmentVariable($envVarName, $originalTempPath, [EnvironmentVariableTarget]::Process)
        }
    }
}