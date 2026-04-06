
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon.FileSystem' -Resolve) -Verbose:$false

    $script:testDirPath = $null
    $script:testNum = 0

    function GivenItem
    {
        param(
            $Named,

            [switch] $IsFile
        )

        $newItemArgs = @{ 'ItemType' = 'Directory' }
        if ($IsFile)
        {
            $newItemArgs['ItemType'] = 'File'
        }
        $path = Join-Path -Path $script:testDirPath -ChildPath $Named
        New-Item -Path $path @newItemArgs -Force
    }

    function ThenError
    {
        param(
            [string] $MatchesRegex,

            [switch] $IsEmpty
        )

        if ($IsEmpty)
        {
            $Global:Error | Should -BeNullOrEmpty
            return
        }

        $Global:Error | Should -Not -BeNullOrEmpty
        $Global:Error | Should -Match $MatchesRegex
    }

    function ThenItem
    {
        param(
            $Named,

            [switch] $Not,

            [switch] $Exists,

            [switch] $IsFile
        )

        if (-not [IO.Path]::IsPathRooted($Named))
        {
            $Named = Join-Path -Path $script:testDirPath -ChildPath $Named
        }

        if ($Not)
        {
            $Named | Should -Not -Exist
            return
        }

        $Named | Should -Exist

        if ($IsFile)
        {
            [IO.File]::Exists($Named) | Should -BeTrue
        }
        else
        {
            [IO.Directory]::Exists($Named) | Should -BeTrue
        }
    }

    function WhenInstalling
    {
        param(
            [hashtable] $WithArgs
        )

        Push-Location -Path $script:testDirPath
        try
        {
            Install-CDirectory @WithArgs
        }
        finally
        {
            Pop-Location
        }
    }
}

Describe 'Install-CDirectory' {
    BeforeEAch {
        $Global:Error.Clear()
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
        New-Item -Path $script:testDirPath -ItemType 'Directory' | Out-Null
    }

    It 'creates directory' {
        $dir = Join-Path -Path $script:testDirPath -ChildPath ([IO.Path]::GetRandomFileName())
        $dir | Should -Not -Exist
        try
        {
            Install-CDirectory -Path $dir | Should -BeNullOrEmpty
            $Global:Error | Should -BeNullOrEmpty
            [IO.Directory]::Exists($dir) | Should -BeTrue
        }
        finally
        {
            Remove-Item $dir
        }
    }

    It 'preserves existing directory' {
        $dir = Join-Path -Path $script:testDirPath -ChildPath ([IO.Path]::GetRandomFileName())
        $dir | Should -Not -Exist
        try
        {
            Install-CDirectory -Path $dir
            Install-CDirectory -Path $dir
            $Global:Error | Should -BeNullOrEmpty
            [IO.Directory]::Exists($dir) | Should -BeTrue
        }
        finally
        {
            Remove-Item $dir
        }
    }

    It 'creates nested directory'{
        $dir = Join-Path -Path $script:testDirPath -ChildPath ([IO.Path]::GetRandomFileName())
        $dir = Join-Path -Path $dir -ChildPath ([IO.Path]::GetRandomFileName())
        try
        {
            Install-CDirectory -Path $dir
            $Global:Error | Should -BeNullOrEmpty
            [IO.Directory]::Exists($dir) | Should -BeTrue
        }
        finally
        {
            Remove-Item $dir
        }
    }

    It 'can return directory' {
        $dir = Join-Path -Path $script:testDirPath -ChildPath ([IO.Path]::GetRandomFileName())
        try
        {
            $result = Install-CDirectory -Path $dir -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [IO.DirectoryInfo]
            $result.FullName | Should -Be $dir
            $Global:Error | Should -BeNullOrEmpty
            [IO.Directory]::Exists($dir) | Should -BeTrue
        }
        finally
        {
            Remove-Item $dir
        }
    }

    It 'validates path is not a file' {
        GivenItem 'file.txt' -IsFile
        WhenInstalling -WithArgs @{ Path = 'file.txt' ; ErrorAction = 'SilentlyContinue' }
        ThenItem 'file.txt' -Exists -IsFile
        ThenError -Matches 'failed to install directory "file.txt" because that path exists and is a file'
    }

    It 'ignores error about path being a file' {
        GivenItem 'file2.txt' -IsFile
        WhenInstalling -WithArgs @{ Path = 'file2.txt' ; ErrorAction = 'Ignore' }
        ThenItem 'file2.txt' -Exists -IsFile
        ThenError -IsEmpty
    }

    It 'can delete file that is in the way' {
        GivenItem 'file3.txt' -IsFile
        WhenInstalling -WithArgs @{ Path = 'file3.txt' ; Force = $true }
        ThenItem 'file3.txt' -Exists
        ThenError -IsEmpty
    }

    It 'supports absolute paths' {
        $fullPath = Join-Path -Path (Get-CTempPath) -ChildPath ([IO.Path]::GetRandomFileName())
        try
        {
            WhenInstalling -WithArgs @{ Path = $fullPath }
            ThenItem $fullPath -Exists
            ThenError -IsEmpty
        }
        finally
        {
            if (Test-Path -Path $fullPath)
            {
                Remove-Item -Path $fullPath -Recurse -Force
            }
        }
    }

    It 'ignores wildcards' {
        GivenItem 'dir4a'
        GivenItem 'dir4b' -IsFile
        $dir = WhenInstalling -WithArgs @{ Path = 'dir4[a-b]' ; PassThru = $true }
        ThenError -IsEmpty
        ThenItem 'dir4a' -Exists
        ThenItem 'dir4[a-b]' -Exists
        ThenItem 'dir4b' -Exists -IsFile
        $dir | Should -HaveCount 1
        $dir.Name | Should -Be 'dir4[a-b]'
    }

    It 'ignores wildcards when replacing file' {
        GivenItem 'dir4a' -IsFile
        GivenItem 'dir4b' -IsFile
        GivenItem 'dir4[a-b]' -IsFile
        $dir = WhenInstalling -WithArgs @{ Path = 'dir4[a-b]' ; Force = $true ; PassThru = $true }
        ThenError -IsEmpty
        ThenItem 'dir4a' -Exists -IsFile
        ThenItem 'dir4b' -Exists -IsFile
        ThenItem 'dir4[a-b]' -Exists
        $dir | Should -HaveCount 1
        $dir.Name | Should -Be 'dir4[a-b]'
    }

    It 'accepts paths from the pipeline' {
        $dir = Join-Path -Path (Get-CTempPath) -ChildPath ([IO.Path]::GetRandomFileName())
        Push-Location -Path $script:testDirPath
        try
        {
            $result = $dir,'dir5' | Install-CDirectory -PassThru
            ThenItem $dir -Exists
            ThenItem 'dir5' -Exists
            $result | Should -HaveCount 2
            $result[0].FullName | Should -Be $dir
            $result[1].FullName | Should -Be (Join-Path -Path $script:testDirPath -ChildPath 'dir5')
            ThenError -IsEmpty
        }
        finally
        {
            Remove-Item -Path $dir
            Pop-Location
        }
    }

    It 'supports WhatIf' {
        WhenInstalling -WithArgs @{ Path = 'dir6' ; WhatIf = $true ; PassThru = $true }
        ThenItem 'dir6' -Not -Exists | Should -BeNullOrEmpty
        ThenError -IsEmpty
    }
}