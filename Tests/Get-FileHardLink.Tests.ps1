
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

        $targetPath = Join-Path -Path $testRoot -ChildPath $ThatTargets
        if( -not (Test-Path -Path $targetPath -PathType Leaf) )
        {
            Write-Error -Message ('Target file "{0}" does not exist,' -f $targetPath) -ErrorAction $ErrorActionPreference
            return
        }

        foreach( $linkPathItem in $LinkPath )
        {
            if( (Test-Path -Path $linkPathItem -PathType Leaf) )
            {
                Write-Verbose -Message ('Removing "{0}": this file exists.' -f $linkPathItem)
                Remove-Item -Path $linkPathItem
            }

            if( -not (Test-Path -Path $linkPathItem -PathType Leaf) )
            {
                Write-Verbose ('Creating hardlink "{0}" -> "{1}".' -f $linkPathItem,$targetPath)
                New-Item -ItemType HardLink -Path (Join-Path -Path $testRoot -ChildPath $linkPathItem) -Value $targetPath
            }
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
        else 
        {
            $Path = Join-Path -Path $testRoot -ChildPath $Path
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
            [String] $Path,

            [switch] $Not,

            [switch] $Exists,

            [Object] $HasLinkType,

            [Object] $Targets
        )

        $fullPath = Join-Path -Path $testRoot -ChildPath $Path

        if( $Exists )
        {
            $fullPath | Should -Not:$Not -Exist
        }

        if( $PSBoundParameters.ContainsKey('HasLinkType') )
        {
            Get-Item -Path $fullPath -Force | Select-Object -Expand 'LinkType' | Should -Not:$Not -Be $HasLinkType
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

    It "should fail when target doesn't exist" {
        $linkPath = 'link.txt'
        GivenHardlink -LinkPath $linkPath -ThatTargets 'testTarget.txt' -ErrorAction SilentlyContinue
        ThenFailed -WithErrorMatching 'testTarget.txt\" does not exist'
        ThenFile 'link.txt' -Not -Exists
    }

    It 'should retrieve hard link targets' {
        $linkPath = @()
        $linkPath += 'link1.txt'
        $linkPath += 'link2.txt'
        GivenFile 'testTarget.txt'
        GivenHardlink -LinkPath $linkPath -ThatTargets 'testTarget.txt'
        ThenFile 'link1.txt' -Exists `
                                      -HasLinkType 'HardLink' `
                                      -Targets 'testTarget.txt'
        ThenFile 'link2.txt' -Exists `
                                      -HasLinkType 'HardLink' `
                                      -Targets 'testTarget.txt'
    }
}