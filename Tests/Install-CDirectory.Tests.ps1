
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon.FileSystem' -Resolve) -Verbose:$false

    $script:root = [IO.Path]::GetTempPath()
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
            Install-CDirectory -Path $dir
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
}