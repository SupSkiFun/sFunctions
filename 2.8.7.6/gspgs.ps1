<#
.SYNOPSIS
Returns the State of Protection Groups
.DESCRIPTION
Returns the State of Protection Groups as an object of Name, State, ConfigOK, and ConfigNeeded.
.PARAMETER ProtectionGroup
[VMware.VimAutomation.Srm.Views.SrmProtectionGroup]  Protection Group Object.  See Examples.
.INPUTS
[VMware.VimAutomation.Srm.Views.SrmProtectionGroup]
.OUTPUTS
[pscustomobject] SupSkiFun.SRM.Protection.Group.State
.EXAMPLE
Return Protection Group State from specific Protection Group(s) into the myInfo variable:
$myPG = Get-SRMProtectionGroup | Where-Object -Property Name -Match "DS1"
$myInfo = $myPG | Get-SRMProtectionGroupState
.EXAMPLE
Return Protection Group State from all Protection Groups into the myInfo variable:
$myPG = Get-SRMProtectionGroup
$myInfo = $myPG | Get-SRMProtectionGroupState
#>
function Get-SRMProtectionGroupState
{
	[CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true , ValueFromPipeline = $true)]
        [VMware.VimAutomation.Srm.Views.SrmProtectionGroup[]] $ProtectionGroup
	)

	Process
	{
		foreach ($pgrp in $ProtectionGroup)
		{
            $pgst = $null
            $pgst = $pgrp.ListProtectedVms().where({$_.NeedsConfiguration -eq "True"}).VmName
            $lo = [pscustomobject]@{
                Name = $pgrp.GetInfo().Name.ToString()
                State = $pgrp.GetProtectionState().ToString()
                ConfigOK = $pgrp.CheckConfigured()
                ConfigNeeded = $pgst
            }
			$lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.Protection.Group.State')
            $lo
		}
	}
}