
function Set-CNtfsOwner
{
    <#
    .SYNOPSIS
    Sets the owner of an NTFS file or directory.

    .DESCRIPTION
    The `Set-CNtfsOwner` function sets the owner of an NTFS file or directory. Pass the path of the file or directory to
    the `Path` parameter. Pass the new owner to the `Identity` parameter. If the file or directory isn't owned by the
    new owner, its ACL is updated. Otherwise, nothing happens.

    You can also pipe file system objects to the function in place of passing a path.

    This function requires administrative privileges.

    .EXAMPLE
    Set-CNtfsOwner -Path $Path -Identity $username

    Demonstrates how to set the owner of a file system object to a specific principal. In this example, the file or
    directory at `$Path` will be owned by `$username`.

    .EXAMPLE
    Get-ChildItem -Path $directory | Set-CNtfsOwner -Identity $username

    Demonstrates that you can pipe items to `Set-CNtfsOwner` to mass change the owner.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [String] $Path,

        [Parameter(Mandatory)]
        [String] $Identity
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        if (-not $IsWindows)
        {
            $msg = 'The Set-CNtfsOwner function is only supported on Windows.'
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }
    }

    process
    {
        if (-not $IsWindows)
        {
            return
        }

        if (-not (Test-Path -Path $Path))
        {
            $msg = "Failed to set owner on ""${Path}"" to ""${Identity}"" because that path does not exist."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        $newOwner = Resolve-CPrincipal -Name $Identity
        if (-not $newOwner)
        {
            Write-Error -Message "Principal ""${Identity}"" not found." -ErrorAction $ErrorActionPreference
            return
        }

        $paths = Resolve-Path -Path $Path

        foreach ($pathItem in $paths)
        {
            $acl = Get-Acl -LiteralPath $pathItem

            $currentOwner = Resolve-CPrincipalName -Name $acl.Owner

            if ($currentOwner -eq $newOwner.FullName)
            {
                Write-Verbose "Principal ""$($newOwner.FullName)"" already owns ""${pathItem}""."
                return
            }

            Write-Information "Changing owner of ""${pathItem}"" from ""${currentOwner}"" to ""$($newOwner.FullName)""."
            $acl.SetOwner($newOwner.Sid)
            Set-Acl -LiteralPath $pathItem -AclObject $acl
        }
    }
}
