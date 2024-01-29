
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    $script:testDirPath = ''
    $script:testNum = 0
    $script:user = 'CFSTestUser1'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)
}

Describe 'Revoke-CNtfsPermission' {
    BeforeEach {
        $Global:Error.Clear()
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath $script:testNum
        New-Item -Path $script:testDirPath -ItemType 'Directory'
        Grant-CNtfsPermission -Path $script:testDirPath -Identity $script:user -Permission 'FullControl'
    }

    AfterEach {
        $script:testNum += 1
    }

    It 'when user has multiple access control entries on an item' {
        Grant-CNtfsPermission -Path $script:testDirPath -Identity $script:user -Permission 'Read'
        $perm = Get-CNtfsPermission -Path $script:testDirPath -Identity $script:user
        Mock -CommandName 'Get-CNtfsPermission' -ModuleName 'Carbon.FileSystem' -MockWith { $perm ; $perm }.GetNewClosure()
        $Global:Error.Clear()
        Revoke-CNtfsPermission -Path $script:testDirPath -Identity $script:user
        $Global:Error | Should -BeNullOrEmpty
        Carbon.FileSystem\Get-CNtfsPermission -Path $script:testDirPath -Identity $script:user | Should -BeNullOrEmpty
    }

    It 'revokes permission' {
        Revoke-CNtfsPermission -Path $script:testDirPath -Identity $script:user
        $Global:Error.Count | Should -Be 0
        (Test-CNtfsPermission -Path $script:testDirPath -Identity $script:user -Permission 'FullControl') |
            Should -BeFalse
    }

    It 'does not revoke inherited permissions' {
        Get-CNtfsPermission -Path $script:testDirPath -Inherited |
            Where-Object { $_.IdentityReference -notlike ('*{0}*' -f $script:user) } |
            ForEach-Object {
                $result = Revoke-CNtfsPermission -Path $script:testDirPath -Identity $_.IdentityReference
                $Global:Error.Count | Should -Be 0
                $result | Should -BeNullOrEmpty
                Test-CNtfsPermission -Identity $_.IdentityReference `
                                     -Path $script:testDirPath `
                                     -Inherited `
                                     -Permission $_.FileSystemRights |
                    Should -BeTrue
            }
    }

    It 'writes no error when revoking missing permission' {
        Revoke-CNtfsPermission -Path $script:testDirPath -Identity $script:user
        (Test-CNtfsPermission -Path $script:testDirPath -Identity $script:user -Permission 'FullControl') |
            Should -BeFalse
        Revoke-CNtfsPermission -Path $script:testDirPath -Identity $script:user
        $Global:Error.Count | Should -Be 0
        (Test-CNtfsPermission -Path $script:testDirPath -Identity $script:user -Permission 'FullControl') |
            Should -BeFalse
    }

    It 'resolves relative path' {
        Push-Location -Path (Split-Path -Parent -Path $script:testDirPath)
        try
        {
            $path = Join-Path -Path '.' -ChildPath (Split-Path -Leaf -Path $script:testDirPath)
            Revoke-CNtfsPermission -Path $path -Identity $script:user
            Test-CNtfsPermission -Path $script:testDirPath -Identity $script:user -Permission 'FullControl' |
                Should -BeFalse
        }
        finally
        {
            Pop-Location
        }
    }

    It 'supports WhatIf' {
        Revoke-CNtfsPermission -Path $script:testDirPath -Identity $script:user -WhatIf
        Test-CNtfsPermission -Path $script:testDirPath -Identity $script:user -Permission 'FullControl' | Should -BeTrue
    }
}
