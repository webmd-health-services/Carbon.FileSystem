<#
.SYNOPSIS
Gets your computer ready to develop the Carbon.FileSystem module.

.DESCRIPTION
The init.ps1 script makes the configuraion changes necessary to get your computer ready to develop for the
Carbon.FileSystem module. It:


.EXAMPLE
.\init.ps1

Demonstrates how to call this script.
#>
[CmdletBinding()]
param(
)

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

prism install | Format-Table

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'PSModules\Carbon' -Resolve) `
              -Function @('Install-CGroup', 'Install-CUser')

$user1 = [pscredential]::New('CFSTestUser1', (ConvertTo-SecureString -String 'a1z2b3y4!' -AsPlainText -Force))
$user2 = [pscredential]::New('CFSTestUser2', (ConvertTo-SecureString -String 'a1z2b3y4!' -AsPlainText -Force))
$group1 = 'CFSTestGroup1'

Install-CUser -Credential $user1 -Description 'Carbon.FileSystem test user 1.'
Install-CUser -Credential $user2 -Description 'Carbon.FileSystem test user 2.'
Install-CGroup -Name $script:group1 -Description 'Carbon.FileSystem test group 1.'

