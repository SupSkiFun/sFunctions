<#
.SYNOPSIS
Returns an object of Protected VMs.
.DESCRIPTION
Returns an object of Protected VMs from submitted Protection Groups.
Returns an object of VM, MoRef, Protection Group, State, NeedsConfig and Faults.
NEED INPUT ABOUT HOW RUN ON PORTECTED OR RECVOERY SITE!!!
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

	Process
	{
		foreach ($pgrp in $ProtectionGroup)
		{
			$pvms = $pgrp.ListProtectedVms()
			switch ($pgrp.GetProtectionState())
			{
				Shadowing
				Ready
			}
			foreach ($pvm in $pvms)
			{
			   	$pvm.vm.UpdateViewData()
				$lo = [pscustomobject]@{
					#VMName = $pvm.vm.config.name
					VM = $pvm.Vm.Config.Name
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