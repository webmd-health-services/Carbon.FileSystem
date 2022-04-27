
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)

    $script:testRoot = $null
    $script:testNum = 0

    function CreateHardlink
    {
        param(
            [Parameter(Mandatory)]
            [String] $RepoRoot,

            [Parameter(Mandatory)]
            [String] $Driver
        )

        if( -not (Test-Path -Path $RepoRoot -PathType Container) )
        {
            Write-Error -Message ('Repository root "{0}" does not exist.' -f $RepoRoot) -ErrorAction $ErrorActionPreference
            return
        }

        Push-Location -Path $RepoRoot

        try
        {
            $linkPath = Join-Path -Path '.' -ChildPath '.kitchen.local.yml'
            $targetPath = Join-Path -Path '.' -ChildPath ('.kitchen.{0}.yml' -f $Driver)
            if( -not (Test-Path -Path $targetPath -PathType Leaf) )
            {
                Write-Error -Message ('Target driver file "{0}" does not exist,' -f $targetPath) -ErrorAction $ErrorActionPreference
                return
            }

            $targetPath = Resolve-Path -Path $targetPath | Select-Object -ExpandProperty 'ProviderPath'

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

            [String]$In,

            [Object]$HasLinkType,

            [Object]$Targets
        )

        $fullPath = $Path
        if( $In )
        {
            $fullPath = Join-Path -Path $In -ChildPath $Path
        }

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
            if( $In -and $Targets -and -not [IO.Path]::IsPathRooted($Targets) )
            {
                $Targets = Join-Path -Path $In -ChildPath $Targets -Resolve
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
        CreateHardlink -RepoRoot $testRoot -Driver 'testDriver' -ErrorAction SilentlyContinue
        ThenFailed -WithErrorMatching '\.kitchen\.testDriver\.yml" does not exist'
        ThenFile '.kitchen.local.yml' -Not -Exists -In $testRoot
    }

    It 'should retrieve targets from link when there is a driver file' {
        GivenFile '.kitchen.somedriver.yml' -In $testRoot
        CreateHardlink -RepoRoot $testRoot -Driver 'somedriver'
        ThenFile '.kitchen.local.yml' -Exists `
                                      -In $testRoot `
                                      -HasLinkType 'HardLink' `
                                      -Targets '.kitchen.somedriver.yml'
    }
}