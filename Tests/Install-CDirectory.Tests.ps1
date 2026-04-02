
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon.FileSystem' -Resolve) -Verbose:$false

    $script:root = Get-CTempPath
}

Describe 'Install-CDirectory' {
    BeforeEAch {
        $Global:Error.Clear()
    }

    It 'creates directory' {
        $dir = Join-Path -Path $root -ChildPath ([IO.Path]::GetRandomFileName())
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
        $dir = Join-Path -Path $root -ChildPath ([IO.Path]::GetRandomFileName())
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
        $dir = Join-Path -Path $root -ChildPath ([IO.Path]::GetRandomFileName())
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
        $dir = JOin-Path -Path $script:root -ChildPath ([IO.Path]::GetRandomFileName())
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
}