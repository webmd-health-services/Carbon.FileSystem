
using namespace System.IO

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)

    $script:identity = 'CFSTestUser1'
    $script:tempDir = Join-Path -Path $TestDrive -ChildPath ([Path]::GetRandomFileName())
    Install-CDirectory (Join-Path -path $script:tempDir -ChildPath 'Directory')
    New-Item (Join-Path -path $script:tempDir -ChildPath 'File') -ItemType File

    $script:dirPath = Join-Path -Path $script:tempDir -ChildPath 'Directory'
    Grant-CNtfsPermission -Identity $script:identity `
                          -Permission ReadAndExecute `
                          -Path $script:dirPath `
                          -ApplyTo FilesOnly `
                          -OnlyApplyToChildFilesAndFolders

    $script:testDirPermArgs = @{
        Path = $script:dirPath;
        Identity = $script:identity;
    }

    $script:filePath = Join-Path -Path $script:dirPath -ChildPath 'File'
    New-Item -Path $script:filePath -ItemType File

    $script:testFilePermArgs = @{
        Path = $script:filePath;
        Identity = $script:identity;
    }
}

AfterAll {
    Remove-Item -Path $script:tempDir -Recurse
}

Describe 'Test-CNtfsPermission' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'fails on non-existent path' {
        Test-CNtfsPermission -Path 'C:\I\Do\Not\Exist' `
                             -Identity $script:identity `
                             -Permission 'FullControl' `
                             -ErrorAction SilentlyContinue |
            Should -BeNullOrEmpty
        $Global:Error | Should -HaveCount 1
        $Global:Error | Should -Match 'path does not exist'
    }

    It 'checks ungranted permission' {
        Test-CNtfsPermission @testDirPermArgs -Permission 'Write' | Should -BeFalse
    }

    It 'checks granted permission' {
        Test-CNtfsPermission @testDirPermArgs -Permission 'Read' | Should -BeTrue
    }

    It 'checks exact partial permission' {
        Test-CNtfsPermission @testDirPermArgs -Permission 'Read' -Strict | Should -BeFalse
    }

    It 'checks exact permission' {
        Test-CNtfsPermission @testDirPermArgs -Permission 'ReadAndExecute' -Strict | Should -BeTrue
    }

    It 'excludes inherited permission' {
        Test-CNtfsPermission @testFilePermArgs -Permission 'ReadAndExecute' | Should -BeFalse
    }

    It 'includes inherited permission' {
        Test-CNtfsPermission @testFilePermArgs -Permission 'ReadAndExecute' -Inherited | Should -BeTrue
    }

    It 'excludes inherited partial permission' {
        Test-CNtfsPermission @testFilePermArgs -Permission 'ReadAndExecute' -Strict | Should -BeFalse
    }

    It 'includes inherited exact permission' {
        Test-CNtfsPermission @testFilePermArgs -Permission 'ReadAndExecute' -Inherited -Strict | Should -BeTrue
    }

    It 'checks ungranted inheritance flags' {
        Test-CNtfsPermission @testDirPermArgs -Permission 'ReadAndExecute' -ApplyTo FolderSubfoldersAndFiles |
            Should -BeFalse
    }

    It 'checks applies to flags' {
        Test-CNtfsPermission @testDirPermArgs -Permission 'ReadAndExecute' -ApplyTo FolderAndFiles |
            Should -BeFalse
        Test-CNtfsPermission @testDirPermArgs `
                             -Permission 'ReadAndExecute' `
                             -ApplyTo FolderAndFiles `
                             -OnlyApplyToChildFilesAndFolders |
            Should -BeFalse
        Test-CNtfsPermission @testDirPermArgs -Permission 'ReadAndExecute' -ApplyTo FilesOnly |
            Should -BeFalse
        Test-CNtfsPermission @testDirPermArgs `
                             -Permission 'ReadAndExecute' `
                             -ApplyTo FilesOnly `
                             -OnlyApplyToChildFilesAndFolders |
            Should -BeTrue
    }
}
