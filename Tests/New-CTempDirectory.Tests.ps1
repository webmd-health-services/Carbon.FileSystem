
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon.FileSystem' -Resolve) -Verbose:$false
}

Describe 'New-CTempDirectory' {
    It 'creates new temp directory' {
        $tmpDir = New-CTempDirectory
        try
        {
            [IO.Directory]::Exists($tmpDir.FullName) | Should -BeTrue
        }
        finally
        {
            Uninstall-CDirectory -Path $tmpDir.FullName -Recurse
        }
    }

    It 'prefixes directory name'{
        $tempDir = New-CTempDirectory -Prefix 'fubar'
        try
        {
            [IO.Directory]::Exists($tempDir.FullName) | Should -BeTrue
            $tempDir.Name | Should -BeLike 'fubar*'
        }
        finally
        {
            Uninstall-CDirectory -Path $tempDir.FullName -Recurse
        }
    }

    It 'sanitizes prefix'{
        $tempDir = New-CTempDirectory -Prefix $PSCommandPath
        try
        {
            [IO.Directory]::Exists($tempDir.FullName) | Should -BeTrue
            $tempDir.Name | Should -BeLike "$(Split-Path -Leaf -Path $PSCommandPath)*"
        }
        finally
        {
            Uninstall-CDirectory -Path $tempDir.FullName -Recurse
        }
    }

    It 'supports WhatIf' {
        $tempDir = New-CTempDirectory -WhatIf
        $tempDir | Should -BeNullOrEmpty
    }
}
