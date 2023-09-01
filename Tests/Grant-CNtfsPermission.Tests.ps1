
using namespace System.Security.AccessControl;

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)

    $script:testDirPath = $null
    $script:testNum = 0

    $script:path = $null
    $script:user = 'CFSTestUser1'
    $script:user2 = 'CFSTestUser1'
    $script:containerPath = $null

    function Assert-InheritanceFlags
    {
        param(
            [string]
            $ContainerInheritanceFlags,

            [Security.AccessControl.InheritanceFlags]
            $InheritanceFlags,

            [Security.AccessControl.PropagationFlags]
            $PropagationFlags
        )

        $ace = Get-CNtfsPermission $script:containerPath -Identity $script:user

        $ace | Should -Not -BeNullOrEmpty
        $expectedRights = [Security.AccessControl.FileSystemRights]::Read -bor [Security.AccessControl.FileSystemRights]::Synchronize
        $ace.FileSystemRights | Should -Be $expectedRights
        $ace.InheritanceFlags | Should -Be $InheritanceFlags
        $ace.PropagationFlags | Should -Be $PropagationFlags
    }

    function Assert-Permissions
    {
        param(
            $identity,
            [FileSystemRights] $Permission,
            $Path,
            $Type = 'Allow',
            [InheritanceFlags] $InheritanceFlag,
            [PropagationFlags] $PropagationFlag
        )

        $ace = Get-CNtfsPermission -Path $Path -Identity $identity
        $ace | Should -Not -BeNullOrEmpty

        if ($InheritanceFlag)
        {
            $ace.InheritanceFlags | Should -Be $InheritanceFlag
        }

        if ($PropagationFlag)
        {
            $ace.PropagationFlags | Should -Be $PropagationFlag
        }

        $ace | Format-List * -Force | Out-String | Write-Debug
        ($ace.FileSystemRights -band $Permission) | Should -Be $Permission
        $ace.AccessControlType | Should -Be ([Security.AccessControl.AccessControlType]$Type)
    }

    function Invoke-GrantPermissions
    {
        param(
            $Identity,
            $Permissions,
            $Path,
            $ApplyTo,
            [switch] $OnlyApplyToChildFilesAndFolders,
            [switch] $Clear,
            $ExpectedPermission,
            $Type,
            [InheritanceFlags] $InheritanceFlag,
            [PropagationFlags] $PropagationFlag
        )

        $optionalParams = @{ }
        $assertOptionalParams = @{ }
        if( $ApplyTo )
        {
            $optionalParams['ApplyTo'] = $ApplyTo
        }

        if( $OnlyApplyToChildFilesAndFolders )
        {
            $optionalParams['OnlyApplyToChildFilesAndFolders'] = $OnlyApplyToChildFilesAndFolders
        }

        if( $Clear )
        {
            $optionalParams['Clear'] = $Clear
        }

        if ($InheritanceFlag)
        {
            $assertOptionalParams['InheritanceFlag'] = $InheritanceFlag
        }

        if ($PropagationFlag)
        {
            $assertOptionalParams['PropagationFlag'] = $PropagationFlag
        }

        if( $Type )
        {
            $optionalParams['Type'] = $Type
            $assertOptionalParams['Type'] = $Type
        }

        $expectedRuleType = 'Security.AccessControl.FileSystemAccessRule' -as [Type]
        $result = Grant-CNtfsPermission -Identity $Identity `
                                        -Permission $Permissions `
                                        -Path $Path `
                                        -PassThru `
                                        @optionalParams
        $result = $result | Select-Object -Last 1
        $result | Should -Not -BeNullOrEmpty
        $result.IdentityReference | Should -Be (Resolve-CIdentityName $Identity)
        $result | Should -BeOfType $expectedRuleType
        if( -not $ExpectedPermission )
        {
            $ExpectedPermission = $Permissions
        }

        Assert-Permissions -Identity $Identity `
                           -Permission $ExpectedPermission `
                           -Path $Path `
                           @assertOptionalParams
    }

    function New-TestDirectory
    {
        param(
        )

        $path = Join-Path -Path $script:testDirPath -ChildPath ([IO.Path]::GetRandomFileName())
        Install-CDirectory -Path $path
        return $path
    }

    function New-TestFile
    {
        param(
        )

        $script:containerPath = New-TestDirectory

        $leafPath = Join-Path -Path $script:containerPath -ChildPath ([IO.Path]::GetRandomFileName())
        $null = New-Item -ItemType 'File' -Path $leafPath
        return $leafPath
    }
}

Describe 'Grant-CNtfsPermission' {
    BeforeEach {
        $Global:Error.Clear()
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath $script:testNum
        New-Item -Path $script:testDirPath -ItemType 'Directory'
    }

    AfterEach {
        $script:testNum += 1
    }

    It 'grants permissions on files' {
        $file = New-TestFile
        $identity = 'BUILTIN\Administrators'
        $permissions = 'Read','Write'

        Invoke-GrantPermissions -Identity $identity `
                                -Permissions $permissions `
                                -Path $file `
                                -InheritanceFlag 'None' `
                                -PropagationFlag 'None'
    }

    It 'grants permissions on directories' {
        $dir = New-TestDirectory
        $identity = 'BUILTIN\Administrators'
        $permissions = 'Read','Write'

        Invoke-GrantPermissions -Identity $identity `
                                -Permissions $permissions `
                                -Path $dir `
                                -InheritanceFlag ('ContainerInherit', 'ObjectInherit') `
                                -PropagationFlag 'None'
    }

    It 'clears existing permissions' {
        $script:path = New-TestFile
        Invoke-GrantPermissions $script:user 'FullControl' -Path $script:path -InheritanceFlag None -PropagationFlag None
        Invoke-GrantPermissions $script:user2 'FullControl' -Path $script:path -InheritanceFlag None -PropagationFlag None

        $result =
            Grant-CNtfsPermission -Identity 'Everyone' -Permission 'Read','Write' -Path $script:path -Clear -PassThru
        $result | Should -Not -BeNullOrEmpty
        $result.Path | Should -Be $script:path

        $acl = Get-Acl -Path $script:path

        $rules = $acl.Access | Where-Object { -not $_.IsInherited }
        $rules | Should -Not -BeNullOrEmpty
        $rules.IdentityReference.Value | Should -Be 'Everyone'
    }

    It 'handles no permissions to clear' {
        $script:path = New-TestFile

        $acl = Get-Acl -Path $script:path
        $rules = $acl.Access | Where-Object { -not $_.IsInherited }
        if( $rules )
        {
            $rules | ForEach-Object { $acl.RemoveAccessRule( $_ ) }
            Set-Acl -Path $script:path -AclObject $acl
        }

        $result = Grant-CNtfsPermission -Identity 'Everyone' `
                                        -Permission 'Read','Write' `
                                        -Path $script:path `
                                        -Clear `
                                        -PassThru `
                                        -ErrorAction SilentlyContinue
        $result | Should -Not -BeNullOrEmpty
        $result.IdentityReference | Should -Be 'Everyone'

        $error.Count | Should -Be 0

        $acl = Get-Acl -Path $script:path
        $rules = $acl.Access | Where-Object { -not $_.IsInherited }
        $rules | Should -Not -BeNullOrEmpty
        ($rules.IdentityReference.Value -like 'Everyone') | Should -BeTrue
    }

    # Applied manually in the Windows Explorer UI to determine corresponding inheritance and propagation flags.
    $testCases = @(
        @{
            ApplyTo = 'FolderSubfoldersAndFiles';
            InheritanceFlags = 'ContainerInherit,ObjectInherit';
            PropagationFlags = 'None';
        },
        @{
            ApplyTo = 'FolderOnly';
            InheritanceFlags = 'None';
            PropagationFlags = 'None';
        },
        @{
            ApplyTo = 'FolderAndSubfolders';
            InheritanceFlags = 'ContainerInherit';
            PropagationFlags = 'None';
        },
        @{
            ApplyTo = 'FolderAndFiles';
            InheritanceFlags = 'ObjectInherit';
            PropagationFlags = 'None';
        },
        @{
            ApplyTo = 'SubfoldersAndFilesOnly';
            InheritanceFlags = 'ContainerInherit,ObjectInherit';
            PropagationFlags = 'InheritOnly';
        },
        @{
            ApplyTo = 'SubfoldersOnly';
            InheritanceFlags = 'ContainerInherit';
            PropagationFlags = 'InheritOnly';
        }
    )


    It 'applies to <ApplyTo>' -TestCases $testCases {
        $script:containerPath = New-TestDirectory
        Invoke-GrantPermissions -Identity $script:user `
                                -Path $script:containerPath `
                                -Permission Read `
                                -ApplyTo $ApplyTo `
                                -InheritanceFlag $InheritanceFlags `
                                -PropagationFlag $PropagationFlags
    }

    $testCases = @(
        @{
            ApplyTo = 'FolderSubfoldersAndFiles';
            InheritanceFlags = 'ContainerInherit,ObjectInherit';
            PropagationFlags = 'NoPropagateInherit';
        },
        @{
            # Not allowed by UI.
            ApplyTo = 'FolderOnly';
            InheritanceFlags = 'None';
            PropagationFlags = 'None';
        },
        @{
            ApplyTo = 'FolderAndSubfolders';
            InheritanceFlags = 'ContainerInherit';
            PropagationFlags = 'NoPropagateInherit';
        },
        @{
            ApplyTo = 'FolderAndFiles';
            InheritanceFlags = 'ObjectInherit';
            PropagationFlags = 'NoPropagateInherit';
        },
        @{
            ApplyTo = 'SubfoldersAndFilesOnly';
            InheritanceFlags = 'ContainerInherit,ObjectInherit';
            PropagationFlags = 'NoPropagateInherit,InheritOnly';
        },
        @{
            ApplyTo = 'SubfoldersOnly';
            InheritanceFlags = 'ContainerInherit';
            PropagationFlags = 'NoPropagateInherit,InheritOnly';
        },
        @{
            ApplyTo = 'FilesOnly';
            InheritanceFlags = 'ObjectInherit';
            PropagationFlags = 'NoPropagateInherit,InheritOnly';
        }
    )

    It 'applies to <ApplyTo> and only child files/folders' -TestCases $testCases {
        $script:containerPath = New-TestDirectory
        Invoke-GrantPermissions -Identity $script:user `
                                -Path $script:containerPath `
                                -Permission Read `
                                -ApplyTo $ApplyTo `
                                -OnlyApplyToChildFilesAndFolders `
                                -InheritanceFlag $InheritanceFlags `
                                -PropagationFlag $PropagationFlags
    }

    It 'updates existing permission' {
        $script:containerPath = New-TestDirectory
        Invoke-GrantPermissions -Identity $script:user `
                                -Permission FullControl `
                                -Path $script:containerPath `
                                -ApplyTo FolderOnly `
                                -InheritanceFlag None `
                                -PropagationFlag None
        Invoke-GrantPermissions -Identity $script:user `
                                -Permission Read `
                                -Path $script:containerPath `
                                -Apply FolderSubfoldersAndFiles `
                                -InheritanceFlag 'ContainerInherit,ObjectInherit' `
                                -PropagationFlag None
    }

    It 'does nothing when permission exists' {
        $script:containerPath = New-TestDirectory

        Invoke-GrantPermissions -Identity $script:user `
                                -Permission FullControl `
                                -Path $script:containerPath

        Mock -CommandName 'Set-Acl' -Verifiable -ModuleName 'Carbon'

        Invoke-GrantPermissions -Identity $script:user -Permission FullControl -Path $script:containerPath
        Assert-MockCalled -CommandName 'Set-Acl' -Times 0 -ModuleName 'Carbon'
    }

    It 'updates existing permissions when forced' {
        $script:containerPath = New-TestDirectory

        Invoke-GrantPermissions -Identity $script:user `
                                -Permission FullControl `
                                -Path $script:containerPath `
                                -ApplyTo FolderAndFiles

        Mock -CommandName 'Set-Acl' -Verifiable -ModuleName 'Carbon.Permissions'

        Grant-CNtfsPermission -Identity $script:user `
                              -Permission FullControl `
                              -Path $script:containerPath `
                              -Apply FolderAndFiles `
                              -Force

        Should -Invoke 'Set-Acl' -Times 1 -Exactly -ModuleName 'Carbon.Permissions'
    }

    It 'sets permissions on hidden items' {
        $script:path = New-TestFile
        $item = Get-Item -Path $script:path
        $item.Attributes = $item.Attributes -bor [IO.FileAttributes]::Hidden

        $result = Invoke-GrantPermissions -Identity $script:user -Permission Read -Path $script:path
        $Global:Error.Count | Should -Be 0
    }

    It 'fails if the path does not exist' {
        $result = Grant-CNtfsPermission -Identity $script:user `
                                    -Permission Read `
                                    -Path 'C:\I\Do\Not\Exist' `
                                    -PassThru `
                                    -ErrorAction SilentlyContinue
        $result | Should -BeNullOrEmpty
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should -Match 'Cannot find path'
    }

    It 'clears permissions on files' {
        $script:path = New-TestFile
        Invoke-GrantPermissions -Identity $script:user -Permission Read -Path $script:path
        Invoke-GrantPermissions -Identity $script:user -Permission Read -Path $script:path -Clear
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'clears permissions on directories' {
        $script:containerPath = New-TestDirectory

        Invoke-GrantPermissions -Identity $script:user -Permission Read -Path $script:containerPath
        Invoke-GrantPermissions -Identity $script:user -Permission Read -Path $script:containerPath -Clear

        $Global:Error | Should -BeNullOrEmpty
    }

    It 'sets Deny rules' {
        $filePath = New-TestFile
        Invoke-GrantPermissions -Identity $script:user -Permissions 'Write' -Path $filePath -Type 'Deny'
    }

    It 'grant multiple permissions to an user/group' {
        $dirPath = New-TestDirectory
        Grant-CNtfsPermission -Path $dirPath `
                              -Identity $script:user `
                              -Permission 'Read' `
                              -ApplyTo FolderSubfoldersAndFiles `
                              -Append
        Grant-CNtfsPermission -Path $dirPath `
                              -Identity $script:user `
                              -Permission 'Write' `
                              -ApplyTo FolderAndFiles `
                              -Append
        $perm = Get-CNtfsPermission -Path $dirPath -Identity $script:user
        $perm | Should -HaveCount 2
    }
}
