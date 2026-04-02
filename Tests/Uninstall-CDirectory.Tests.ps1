

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon.FileSystem' -Resolve) -Verbose:$false

    $script:dir = $null
}

Describe 'Uninstall-CDirectory' {
    BeforeEach {
        $script:dir = Join-Path -Path (Get-CTempPath) -ChildPath ([IO.Path]::GetRandomFileName())
        Install-CDirectory -Path $dir
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
}