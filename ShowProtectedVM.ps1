<#
.SYNOPSIS
Returns an object of Protected VMs.
.DESCRIPTION
Returns an object of Protected VMs from submitted Protection Groups.
Returns an object of VM, VMMoRef, ProtectedVM, PeerProtectedVm, ProtectionGroup, VMState,
PeerState, NeedsConfig and Faults.  Can be run on recovery or protected site.
Note:  VM Name is Not Available from the Recovery Site; it is only available from the Protection Site.
.PARAMETER ProtectionGroup
[VMware.VimAutomation.Srm.Views.SrmProtectionGroup]  See Examples.
.INPUTS
[VMware.VimAutomation.Srm.Views.SrmProtectionGroup]
.OUTPUTS
[pscustomobject] SupSkiFun.SRM.Protect.Info
.EXAMPLE
Return an object of VMs from specific Protection Group(s) into the myInfo variable:
$myPG = Get-SRMProtectionGroup | Where-Object -Property Name -Match "DS1"
$myInfo = $myPG | Show-SRMProtectedVM
.EXAMPLE
Return an object of VMs from all Protection Groups into the myInfo variable:
$myPG = Get-SRMProtectionGroup
$myInfo = $myPG | Show-SRMProtectedVM
#>
function Show-SRMProtectedVM
{
	[CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true , ValueFromPipeline = $true)]
        [VMware.VimAutomation.Srm.Views.SrmProtectionGroup[]] $ProtectionGroup
	)

	Begin
    {
        $nota = "Not Available on Recovery Site; only available from the Protection Site"
    }

	Process
	{
		foreach ($pgrp in $ProtectionGroup)
		{
			$pvms = $pgrp.ListProtectedVms()
			$pgst = $pgrp.GetProtectionState()
			foreach ($pvm in $pvms)
			{
				switch ($pgst)
				{
					'Ready'
					{
						$pvm.vm.UpdateViewData()
						$vmnom = $pvm.Vm.Config.Name
					}
					'Shadowing'
					{
						$vmnom = $nota
					}
				}

				$lo = [pscustomobject]@{
					VM = $vmnom
					VMMoRef = $pvm.Vm.Moref
					ProtectedVM = $pvm.ProtectedVm
					PeerProtectedVm = $pvm.PeerProtectedVm
					ProtectionGroup = $pgrp.Name
					VMState = $pvm.State
					PeerState = $pvm.PeerState
					NeedsConfig = $pvm.NeedsConfiguration
					Faults = $pvm.Faults
				}
			$lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.Protect.Info')
			$lo
			}
		}
	}
}