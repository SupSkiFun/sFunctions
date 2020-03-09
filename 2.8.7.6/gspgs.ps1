<#
.SYNOPSIS
Returns an object of Protection Group State
.DESCRIPTION
Returns an object of Protection Group State from submitted Protection Groups.
Returns an object of Name, State, ConfigOK, and NeedConfigVM.

Look into below items.  Verify VMs for above item.

Can be run on recovery or protected site.?

Note:  VM Name is Not Available from the Recovery Site; it is only available from the Protection Site ?


.PARAMETER ProtectionGroup
[VMware.VimAutomation.Srm.Views.SrmProtectionGroup]  See Examples.
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
                NeedsConfigVM = $pgst
            }
			$lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.Protection.Group.State')
            $lo
		}
	}
}