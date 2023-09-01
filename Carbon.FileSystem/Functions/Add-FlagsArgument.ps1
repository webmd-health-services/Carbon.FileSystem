
function Add-FlagsArgument
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [IDictionary] $Argument,

        [Parameter(Mandatory)]
        [ValidateSet('FolderOnly', 'FolderSubfoldersAndFiles', 'FolderAndSubfolders', 'FolderAndFiles',
            'SubfoldersAndFilesOnly', 'SubfoldersOnly', 'FilesOnly')]
        [String] $ApplyTo,

        [switch] $OnlyApplyToChildFilesAndFolders
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    # ApplyTo                   OnlyApplyToChildFilesAndFolders  InheritanceFlags                 PropagationFlags
    # -------                   -------------------------------  ----------------                 ----------------
    # FolderOnly                true                             None                             None
    # FolderSubfoldersAndFiles  true                             ContainerInherit, ObjectInherit  NoPropagateInherit
    # FolderAndSubfolders       true                             ContainerInherit                 NoPropagateInherit
    # FolderAndFiles            true                             ObjectInherit                    NoPropagateInherit
    # SubfoldersAndFilesOnly    true                             ContainerInherit, ObjectInherit  NoPropagateInherit, InheritOnly
    # SubfoldersOnly            true                             ContainerInherit                 NoPropagateInherit, InheritOnly
    # FilesOnly                 true                             ObjectInherit                    NoPropagateInherit, InheritOnly
    # FolderOnly                false                            None                             None
    # FolderSubfoldersAndFiles  false                            ContainerInherit, ObjectInherit  None
    # FolderAndSubfolders       false                            ContainerInherit                 None
    # FolderAndFiles            false                            ObjectInherit                    None
    # SubfoldersAndFilesOnly    false                            ContainerInherit, ObjectInherit  InheritOnly
    # SubfoldersOnly            false                            ContainerInherit                 InheritOnly
    # FilesOnly                 false                            ObjectInherit                    InheritOnly

    $inheritanceFlags = [InheritanceFlags]::None
    $propagationFlags = [PropagationFlags]::None

    switch ($OnlyApplyToChildFilesAndFolders.IsPresent)
    {
        $true
        {
            switch ($ApplyTo)
            {
                'FolderOnly'
                {
                    $inheritanceFlags = [InheritanceFlags]::None
                    $propagationFlags = [PropagationFlags]::None
                }
                'FolderSubfoldersAndFiles'
                {
                    $inheritanceFlags = [InheritanceFlags]::ContainerInherit -bor [InheritanceFlags]::ObjectInherit
                    $propagationFlags = [PropagationFlags]::NoPropagateInherit
                }
                'FolderAndSubfolders'
                {
                    $inheritanceFlags = [InheritanceFlags]::ContainerInherit
                    $propagationFlags = [PropagationFlags]::NoPropagateInherit
                }
                'FolderAndFiles'
                {
                    $inheritanceFlags = [InheritanceFlags]::ObjectInherit
                    $propagationFlags = [PropagationFlags]::NoPropagateInherit
                }
                'SubfoldersAndFilesOnly'
                {
                    $inheritanceFlags = [InheritanceFlags]::ContainerInherit -bor [InheritanceFlags]::ObjectInherit
                    $propagationFlags = [PropagationFlags]::NoPropagateInherit -bor [PropagationFlags]::InheritOnly
                }
                'SubfoldersOnly'
                {
                    $inheritanceFlags = [InheritanceFlags]::ContainerInherit
                    $propagationFlags = [PropagationFlags]::NoPropagateInherit -bor [PropagationFlags]::InheritOnly
                }
                'FilesOnly'
                {
                    $inheritanceFlags = [InheritanceFlags]::ObjectInherit
                    $propagationFlags = [PropagationFlags]::NoPropagateInherit -bor [PropagationFlags]::InheritOnly
                }
            }
        }
        $false
        {
            switch ($ApplyTo)
            {
                'FolderOnly'
                {
                    $inheritanceFlags = [InheritanceFlags]::None
                    $propagationFlags = [PropagationFlags]::None
                }
                'FolderSubfoldersAndFiles'
                {
                    $inheritanceFlags = [InheritanceFlags]::ContainerInherit -bor [InheritanceFlags]::ObjectInherit
                    $propagationFlags = [PropagationFlags]::None
                }
                'FolderAndSubfolders'
                {
                    $inheritanceFlags = [InheritanceFlags]::ContainerInherit
                    $propagationFlags = [PropagationFlags]::None
                }
                'FolderAndFiles'
                {
                    $inheritanceFlags = [InheritanceFlags]::ObjectInherit
                    $propagationFlags = [PropagationFlags]::None
                }
                'SubfoldersAndFilesOnly'
                {
                    $inheritanceFlags = [InheritanceFlags]::ContainerInherit -bor [InheritanceFlags]::ObjectInherit
                    $propagationFlags = [PropagationFlags]::InheritOnly
                }
                'SubfoldersOnly'
                {
                    $inheritanceFlags = [InheritanceFlags]::ContainerInherit
                    $propagationFlags = [PropagationFlags]::InheritOnly
                }
                'FilesOnly'
                {
                    $inheritanceFlags = [InheritanceFlags]::ObjectInherit
                    $propagationFlags = [PropagationFlags]::InheritOnly
                }
            }
        }
    }

    $Argument['InheritanceFlag'] = $inheritanceFlags
    $Argument['PropagationFlag'] = $propagationFlags
}