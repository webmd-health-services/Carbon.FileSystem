
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

    $script:testDirPath = ''
    $script:testNum = 0
    $script:originalTempPath = [NullString]::Value
    $script:tempPathEnvVarName = 'TMPDIR'
    if ($IsWindows)
    {
        if ([Security.Principal.WindowsIdentity]::GetCurrent().IsSystem)
        {
            $script:tempPathEnvVarName = 'SystemTemp'
        }
        else
        {
            $script:tempPathEnvVarName = 'TMP'
        }
    }

    if (Test-Path -Path "env:${script:tempPathEnvVarName}")
    {
        $script:originalTempPath =
            [Environment]::GetEnvironmentVariable($script:tempPathEnvVarName, [EnvironmentVariableTarget]::Process)
    }
}

AfterAll {
    [Environment]::SetEnvironmentVariable($script:tempPathEnvVarName, $script:originalTempPath, [EnvironmentVariableTarget]::Process)
}

Describe 'Set-CTempPath' {
    BeforeEach {
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
        $script:testDirPath = Join-Path -Path $script:testDirPath -ChildPath ([IO.Path]::DirectorySeparatorChar)
        Install-CDirectory -Path $script:testDirPath -InformationAction Ignore
    }

    It 'sets temp path environment variable' {
        Set-CTempPath -Path $script:testDirPath
        Get-CTempPath | Should -Be $script:testDirPath
    }

    It 'does not create temp path' {
        $tempPath = Join-Path -Path $script:testDirPath -ChildPath 'idonotexist'
        $tempPath = Join-Path -Path $tempPath -ChildPath ([IO.Path]::DirectorySeparatorChar)
        $tempPath | Should -Not -Exist
        Set-CTempPath -Path $tempPath
        Get-CTempPath | Should -Be $tempPath
    }

    It 'can create temp path' {
        $tempPath = Join-Path -Path $script:testDirPath -ChildPath 'idonotexist'
        $tempPath = Join-Path -Path $tempPath -ChildPath ([IO.Path]::DirectorySeparatorChar)
        $tempPath | Should -Not -Exist
        Set-CTempPath -Path $tempPath -Create
        $tempPath | Should -Exist
        Get-CTempPath | Should -Be $tempPath
    }

    It 'converts relative paths to absolute paths' {
        Push-Location -Path $script:testDirPath
        try
        {
            Set-CTempPath -Path 'fubar'
            $expectedPath = Join-Path -Path $script:testDirPath -ChildPath 'fubar'
            $expectedPath = Join-Path $expectedPath -ChildPath ([IO.Path]::DirectorySeparatorChar)
            Get-CTempPath | Should -Be $expectedPath
        }
        finally
        {
            Pop-Location
        }
    }

    It 'supports WhatIf' {
        $originalTempPath = Get-CTempPath
        Set-CTempPath -Path $script:testDirPath -WhatIf
        Get-CTempPath | Should -Be $originalTempPath
    }

    It 'sanitizes the path' {
        $testDirName = $script:testDirPath | Split-Path -Leaf
        $tempPath = Join-Path -Path $script:testDirPath -ChildPath "\..\${testDirName}\"
        Set-CTempPath -Path $tempPath
        Get-CTempPath | Should -Be $script:testDirPath
    }

    It 'accepts paths from the pipeline' {
        $script:testDirPath | Set-CTempPath
        Get-CTempPath | Should -Be $script:testDirPath
    }

    It 'accepts directory info objects from the pipeline' {
        Get-Item -Path $script:testDirPath | Set-CTempPath
        Get-CTempPath | Should -Be $script:testDirPath
    }
}