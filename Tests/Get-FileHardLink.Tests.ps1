
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)

    $script:testRoot = $null
    $script:testNum = 0

    function GivenHardlink
    {
        param(
            [Parameter(Mandatory, Position=0)]
            [String[]] $LinkPath,

            [Parameter(Mandatory)]
            [String] $ThatTargets
        )

        if( -not (Test-Path -Path $testRoot -PathType Container) )
        {
            Write-Error -Message ('Repository root "{0}" does not exist.' -f $testRoot) -ErrorAction $ErrorActionPreference
            return
        }

        Push-Location -Path $testRoot

        try
        {
            $targetPath = Join-Path -Path '.' -ChildPath ('.kitchen.{0}.yml' -f $ThatTargets)
            if( -not (Test-Path -Path $targetPath -PathType Leaf) )
            {
                Write-Error -Message ('Target file "{0}" does not exist,' -f $targetPath) -ErrorAction $ErrorActionPreference
                return
            }

            $targetPath = Resolve-Path -Path $targetPath | Select-Object -ExpandProperty 'ProviderPath'

            foreach( $linkPath in $LinkPath )
            {
                if( (Test-Path -Path $linkPath -PathType Leaf) )
                {
                    Write-Verbose -Message ('Removing "{0}": this file exists.' -f $linkPath)
                    Remove-Item -Path $linkPath
                }

                if( Test-Path -Path $linkPath -PathType Leaf )
                {
                    $link = Get-Item -Path $linkPath
                    if( -not $link.Target )
                    {
                        Write-Error -Message ('File "{0}" exists but is not a hardlink to "{1}". Remove this file, or use the -Force switch to delete it and re-create.' -f $linkPath, $targetPath) -ErrorAction $ErrorActionPreference
                        return
                    }

                    if( $link.Target -notcontains $targetPath )
                    {
                        Write-Verbose ('Removing "{0}": exists but links to "{1}".' -f $linkPath,($link.Target -join '", "'))
                        Remove-Item -Path $linkPath
                    }
                }

                if( -not (Test-Path -Path $linkPath -PathType Leaf) )
                {
                    Write-Verbose ('Creating hardlink "{0}" -> "{1}".' -f $linkPath,$targetPath)
                    New-Item -ItemType HardLink -Path $linkPath -Value $targetPath
                }
            }
        }
        finally
        {
            Pop-Location
        }
    }

    function GivenFile
    {
        param(
            [Parameter(Mandatory)]
            [String] $Path,

            [String] $In
        )

        if( $In )
        {
            $Path = Join-Path -Path $In -ChildPath $Path
        }

        New-Item -Path $Path -ItemType 'File'
    }

    function ThenFailed
    {
        param(
            [Parameter(Mandatory)]
            [string] $WithErrorMatching
        )

        $Global:Error[-1] | Should -Match $WithErrorMatching
    }

    function ThenFile
    {
        param(
            [Parameter(Mandatory)]
            [String]$Path,

            [switch]$Not,

            [switch]$Exists,

            [Object]$HasLinkType,

            [Object]$Targets
        )

        $fullPath = Join-Path -Path $testRoot -ChildPath $Path

        if( $Exists )
        {
            $fullPath | Should -Not:$Not -Exist
        }

        if( $PSBoundParameters.ContainsKey('HasLinkType') )
        {
            Get-Item -Path $fullPath | Select-Object -Expand 'LinkType' | Should -Not:$Not -Be $HasLinkType
        }

        if( $PSBoundParameters.ContainsKey('Targets') )
        {
            if( $Targets -and -not [IO.Path]::IsPathRooted($Targets) )
            {
                $Targets = Join-Path -Path $testRoot -ChildPath $Targets -Resolve
            }
            Get-FileHardLink -Path $fullPath | Should -Not:$Not -Contain $Targets
        }
    }
}

Describe 'Get-FileHardLink' {
    BeforeEach { 
        $script:testRoot = $null
        $script:failed = $false
        $script:testRoot = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
        New-Item -Path $script:testRoot -ItemType 'Directory'
        $Global:Error.Clear()
    }

    It 'should fail when there is no driver file' {
        $linkPath = Join-Path -Path '.' -ChildPath '.kitchen.local.yml'
        GivenHardlink -LinkPath $linkPath -ThatTargets 'testDriver' -ErrorAction SilentlyContinue
        ThenFailed -WithErrorMatching '\.kitchen\.testDriver\.yml" does not exist'
        ThenFile '.kitchen.local.yml' -Not -Exists
    }

    It 'should retrieve targets from link when there is a driver file' {
        $linkPath = @()
        $linkPath += Join-Path -Path '.' -ChildPath '.kitchen.local.yml'
        $linkPath += Join-Path -Path '.' -ChildPath '.kitchen.azure.yml'
        GivenFile '.kitchen.somedriver.yml' -In $testRoot
        GivenHardlink -LinkPath $linkPath -ThatTargets 'somedriver'
        ThenFile '.kitchen.local.yml' -Exists `
                                      -HasLinkType 'HardLink' `
                                      -Targets '.kitchen.somedriver.yml'
        ThenFile '.kitchen.azure.yml' -Exists `
                                      -HasLinkType 'HardLink' `
                                      -Targets '.kitchen.somedriver.yml'
    }
}