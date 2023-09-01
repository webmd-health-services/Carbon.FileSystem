

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)

    $script:user = 'CFSTestUser1'
    $script:group1 = 'CFSTestGroup1'
    $script:containerPath = $null
    $script:childPath = $null
}

Describe 'Get-CNtfsPermission' {
    BeforeEach {
        $script:containerPath = 'Carbon-Test-GetPermissions-{0}' -f ([IO.Path]::GetRandomFileName())
        $script:containerPath = Join-Path $env:Temp $script:containerPath

        Install-CDirectory $script:containerPath
        Grant-CNtfsPermission -Path $script:containerPath -Identity $script:group1 -Permission Read

        $script:childPath = Join-Path $script:containerPath 'Child1'
        $null = New-Item $script:childPath -ItemType File
        Grant-CNtfsPermission -Path $script:childPath -Identity $script:user -Permission Read

        $Global:Error.Clear()
    }

    It 'should get permissions' {
        $perms = Get-CNtfsPermission -Path $script:childPath
        $perms | Should -Not -BeNullOrEmpty
        $group1Perms = $perms | Where-Object { $_.IdentityReference.Value -like "*\$($script:group1)" }
        $group1Perms | Should -BeNullOrEmpty

        $userPerms = $perms | Where-Object { $_.IdentityReference.Value -like "*\$($script:user)" }
        $userPerms | Should -Not -BeNullOrEmpty
        $userPerms | Should -BeOfType [Security.AccessControl.FileSystemAccessrule]
    }

    It 'should get inherited permissions' {
        $perms = Get-CNtfsPermission -Path $script:childPath -Inherited
        $perms | Should -Not -BeNullOrEmpty
        $group1Perms = $perms | Where-Object { $_.IdentityReference.Value -like "*\$($script:group1)" }
        $group1Perms | Should -Not -BeNullOrEmpty
        $group1Perms | Should -BeOfType [Security.AccessControl.FileSystemAccessrule]

        $userPerms = $perms | Where-Object { $_.IdentityReference.Value -like "*\$($script:user)" }
        $userPerms | Should -Not -BeNullOrEmpty
        $userPerms | Should -BeOfType [Security.AccessControl.FileSystemAccessRule]
    }

    It 'should get specific user permissions' {
        $perms = Get-CNtfsPermission -Path $script:childPath -Identity $script:group1
        $perms | Should -BeNullOrEmpty

        $perms = @( Get-CNtfsPermission -Path $script:childPath -Identity $script:user )
        $perms | Should -Not -BeNullOrEmpty
        $perms | Should -HaveCount 1
        $perms[0] | Should -Not -BeNullOrEmpty
        $perms[0] | Should -BeOfType [Security.AccessControl.FileSystemAccessrule]
    }

    It 'should get specific users inherited permissions' {
        $perms = Get-CNtfsPermission -Path $script:childPath -Identity $script:group1 -Inherited
        $perms | Should -Not -BeNullOrEmpty
        $perms | Should -BeOfType [Security.AccessControl.FileSystemAccessRule]
    }
}
