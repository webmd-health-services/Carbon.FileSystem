
function Get-FileHardLink
{
    <#
    .SYNOPSIS
    ***OBSOLETE.*** Use `Get-CFsHardLink` instead.
    .DESCRIPTION
    ***OBSOLETE.*** Use `Get-CFsHardLink` instead.
    .EXAMPLE
    ***OBSOLETE.*** Use `Get-CFsHardLink` instead.
    #>
    [CmdletBinding()]
    param(
        # ***OBSOLETE***. Use `Get-CfsHardLink` function instead.
        [Parameter(Mandatory)]
        [String] $Path
    )

    $msg = 'The Carbon.FileSystem module''s Get-FileHardLink function is obsolete. Use "Get-CFsHardLink" instead.'
    Write-Warning -Message $msg

    Get-CFsHardLink @PSBoundParameters
}
