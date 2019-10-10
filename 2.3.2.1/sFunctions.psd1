#
# Module manifest for module 'sFunctions'
#
# Generated by: Joe Acosta
#
# Generated on: 10/04/2019
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'sFunctions.psm1'

# Version number of this module.
ModuleVersion = '2.3.2.1'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '3bf19050-12e9-4233-9ed1-27792c9b7333'

# Author of this module
Author = 'Joe Acosta'

# Company or vendor of this module
CompanyName = 'SupSkiFun'

# Copyright statement for this module
Copyright = '(c) 2019 Joe Acosta. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Various functions for administering VMware Site Recovery Manager (SRM).'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @('VMware.VimAutomation.Core',
               'VMware.VimAutomation.Srm')

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Get-SRMProtectionGroup' , 'Get-SrmRecoveryPlan', 'Get-SRMTestState' ,
'Get-SRMVM' , 'Protect-SRMVM' , 'Send-SRMDismiss' , 'Show-SRMProtectedVM' , 'Show-SRMRelationship' ,
'Start-SRMCleanUp', 'Start-SRMTest' , 'Stop-SRMTest' , 'UnProtect-SRMVM'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
FileList = @( 'sFunctions.psd1' , 'sFunctions.psm1' , 'sClass.psm1' )

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'PowerCLI', 'Protection' , 'Group' , 'Recovery', 'Site' ,
        'SRM', 'Test' , 'vSphere' , 'VMware'

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/SupSkiFun/sFunctions'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = 'Read examples for function use.
        Removed function csrm.
        Start-SRMTest was modified to allow SyncData to be set True or False.  Defaults to false.
        This module has been tested against Virtual Center (VCSA) 6.7 U3 / Build 9313458 , SRM 8.2.0 / Build 14761905 / ApiVersion 8.0.'

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

