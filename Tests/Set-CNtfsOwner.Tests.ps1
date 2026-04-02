
#Requires -Version 5.1
#Requires -RunAsAdministrator
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon.FileSystem' -Resolve) `
                  -Function @('Set-CNtfsOwner') `
                  -Verbose:$false

    $psModulesPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon.FileSystem\M' -Resolve

    Import-Module -Name (Join-Path -Path $psModulesPath -ChildPath 'Carbon.Accounts' -Resolve) `
                  -Function @('Resolve-CPrincipal', 'Resolve-CPrincipalName') `
                  -Prefix 'T' `
                  -Verbose:$false

    $script:currentUserName =
        Resolve-TCPrincipalName -Name "$([Environment]::UserDomainName)\$([Environment]::UserName)"

    function GivenFile
    {
        param(
            [String] $Named,
            [String] $ownedBy
        )

        $path = Join-Path -Path $TestDrive -ChildPath $Named
        New-Item -Path $path -ItemType File
        $acl = Get-Acl -Path $path
        $owner = Resolve-TCPrincipal -Name $ownedBy
        $acl.SetOwner($owner.Sid)
        Set-Acl -Path $path -AclObject $acl
    }

    function ThenOwner
    {
        param(
            [String] $Of,
            [String] $Is
        )

        $acl = Get-Acl -Path (Join-Path -Path $TestDrive -ChildPath $Of)
        $acl.Owner | Should -Be (Resolve-TCPrincipalName -Name $Is)
    }

    function WhenSettingOwner
    {
        param(
            [Parameter(Mandatory)]
            [hashtable] $WithArgs
        )

        Push-Location -Path $TestDrive
        try
        {
            Set-CNtfsOwner @WithArgs
        }
        finally
        {
            Pop-Location
        }
    }
}

Describe 'Set-CNtfsOwner' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'changes the owner' {
        GivenFile '001.txt' -OwnedBy 'Users'
        WhenSettingOwner -WithArgs @{ Path = '001.txt' ; Identity = $script:currentUserName }
        ThenOwner -Of '001.txt' -Is $script:currentUserName
    }

    It 'does not change owner' {
        GivenFile '002.txt' -OwnedBy $script:currentUserName
        Mock -CommandName 'Set-Acl' -ModuleName 'Carbon.FileSystem'
        WhenSettingOwner -WithArgs @{ Path  = '002.txt' ; Identity = $script:currentUserName}
        Should -Invoke 'Set-Acl' -ModuleName 'Carbon.FileSystem' -Times 0
    }

    It 'validates path exists' {
        WhenSettingOwner -WithArgs @{ Path = '003.txt' ; Identity = $script:currentUserName } `
                         -ErrorAction SilentlyContinue
        $Global:Error | Should -Match 'does not exist'
    }

    It 'validates principal exists' {
        GivenFile '004.txt' -OwnedBy 'Users'
        WhenSettingOwner -WithArgs @{ Path = '004.txt' ; Identity = 'fjdskfsdaflklsdsfj' } -ErrorAction SilentlyContinue
        $Global:Error | Select-Object -First 1 | Should -Match 'not found'
    }

    It 'accepts pipeline input' {
        GivenFile '105.txt' -OwnedBy 'Users'
        GivenFile '106.txt' -OwnedBy 'Users'
        GivenFile '107.txt' -OwnedBy 'Users'

        Get-ChildItem -Path $TestDrive -Filter '10*.txt' | Set-CNtfsOwner -Identity $script:currentUserName
        ThenOwner -Of '105.txt' -Is $script:currentUserName
        ThenOwner -Of '106.txt' -Is $script:currentUserName
        ThenOwner -Of '107.txt' -Is $script:currentUserName
    }

    It 'supports WhatIf' {
        GivenFile '008.txt' -OwnedBy 'Users'
        WhenSettingOwner -WithArgs @{ Path = '008.txt'; Identity = $script:currentUserName; WhatIf = $true; }
        ThenOwner -Of '008.txt' -Is 'Users'
    }

    It 'supports wildcards' {
        GivenFile '209.txt' -OwnedBy 'Users'
        GivenFile '210.txt' -OwnedBy 'Users'
        WhenSettingOwner -WithArgs @{ Path = '2*.txt'; Identity = $script:currentUserName; }
        ThenOwner -Of '209.txt' -Is $script:currentUserName
        ThenOwner -Of '210.txt' -Is $script:currentUserName
    }
}