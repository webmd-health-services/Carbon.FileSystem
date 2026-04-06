

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon.FileSystem' -Resolve) -Verbose:$false

    $script:dir = $null
    $script:testDirPath = $null
    $script:testNum = 0

    function GivenItem
    {
        param(
            [String] $Named,

            [switch] $IsFile
        )

        $path = $Named
        if (-not [IO.Path]::IsPathRooted($Named))
        {
            $path = Join-Path -Path $script:testDirPath -ChildPath $path
        }

        if ($IsFile)
        {
            New-Item -Path $path -ItemType 'File' -Force
        }
        else
        {
            Install-CDirectory -Path $path -PassThru -InformationAction 'Ignore'
        }
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
            [String] $Named,

            [switch] $Not,

            [switch] $Exists,

            [switch] $IsFile
        )

        $path = $Named
        if (-not [IO.Path]::IsPathRooted($Named))
        {
            $path = Join-Path -Path $script:testDirPath -ChildPath $path
        }

        if ($Not)
        {
            [wildcardpattern]::Escape($path) | Should -Not -Exist
            return
        }

        if ($Exists)
        {
            [wildcardpattern]::Escape($path) | Should -Exist

            if ($IsFile)
            {
                [IO.File]::Exists($path) | Should -BeTrue
            }
            else
            {
                [IO.Directory]::Exists($path) | Should -BeTrue
            }
        }
    }

    function WhenUninstalling
    {
        param(
            [hashtable] $WithArgs
        )

        Push-Location $script:testDirPath
        try
        {
            Uninstall-CDirectory @WithArgs
        }
        finally
        {
            Pop-Location
        }
    }
}

Describe 'Uninstall-CDirectory' {
    BeforeEach {
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
        Install-CDirectory -Path $script:testDirPath -InformationAction 'Ignore'

        $script:dir = Join-Path -Path (Get-CTempPath) -ChildPath ([IO.Path]::GetRandomFileName())
        Install-CDirectory -Path $dir -InformationAction 'Ignore'

        $Global:Error.Clear()
    }

    AfterEach{
        if( (Test-Path -Path $script:dir -PathType Container) )
        {
            Remove-Item -Path $script:dir -Recurse
        }
    }

    It 'removes directory'{
        Uninstall-CDirectory -Path $script:dir
        $Global:Error | Should -BeNullOrEmpty
        $script:dir | Should -Not -Exist
    }

    It 'ignores non-existent directory' {
        Uninstall-CDirectory -Path $script:dir
        Uninstall-CDirectory -Path $script:dir
        $Global:Error | Should -BeNullOrEmpty
        $script:dir | Should -Not -Exist
    }

    It 'deletes recursively' {
        $filePath = Join-Path -Path $script:dir -ChildPath 'file'
        New-Item -Path $filePath -ItemType 'File'
        Uninstall-CDirectory -Path $script:dir -Recurse
        $Global:Error | Should -BeNullOrEmpty
        $script:dir | Should -Not -Exist
    }

    It 'validates directory is not a file' {
        GivenItem 'dir4' -IsFile
        WhenUninstalling -WithArgs @{ Path = 'dir4' ; ErrorAction = 'SilentlyContinue' }
        ThenError -MatchesRegex 'delete directory "dir4" because that path is a file'
        ThenItem 'dir4' -Exists -IsFile
    }

    It 'can ignore error when directory is a file' {
        GivenItem 'dir4' -IsFile
        WhenUninstalling -WithArgs @{ Path = 'dir4' ; ErrorAction = 'Ignore' }
        ThenError -IsEmpty
        ThenItem 'dir4' -Exists -IsFile
    }

    It 'can delete directory that is a file' {
        GivenItem 'dir5' -IsFile
        WhenUninstalling -WithArgs @{ Path = 'dir5' ; Force = $true }
        ThenError -IsEmpty
        ThenItem 'dir5' -Not -Exist
    }

    It 'ignores wildcards' {
        GivenItem 'dir6a'
        GivenItem 'dir6b' -IsFile
        GivenItem 'dir6[a-b]'
        WhenUninstalling -WithArgs @{ Path = 'dir6[a-b]' ; Force = $true }
        ThenError -IsEmpty
        ThenItem 'dir6[a-b]' -Not -Exist
        ThenItem 'dir6a' -Exists
        ThenItem 'dir6b' -Exists -IsFile
    }

    It 'accepts pipeline input' {
        # Make sure accepts DirectoryInfo objects, full path strings, and relative path strings.
        $dir1 = GivenItem 'dir7a'
        GivenItem 'dir7b'
        $dir2Path = (Join-Path -Path (Get-CTempPath) -ChildPath ([IO.Path]::GetRandomFileName()))
        GivenItem $dir2Path
        Push-Location $script:testDirPath
        try
        {
            $dir1 | Should -BeOfType [IO.DirectoryInfo]
            $dir1,'dir7b',$dir2Path | Uninstall-CDirectory
            ThenItem 'dir7a' -Not -Exist
            ThenItem 'dir7b' -Not -Exist
            ThenItem $dir2Path -Not -Exist
        }
        finally
        {
            Remove-Item -Path $dir2Path -ErrorAction Ignore
            Pop-Location
        }
    }

    It 'supports WhatIf' {
        GivenITem 'dir8'
        WhenUninstalling -WithArgs @{ Path = 'dir8' ; WhatIf = $true }
        ThenItem 'dir8' -Exists
        ThenError -IsEmpty
    }
}