Function Get-SRMProtectedVM{}

<#

BELOW is the old AF - this needs to be refactored!

#>

<#
.SYNOPSIS
Outputs an object of Protected VMs and relevant information.
.DESCRIPTION
Outputs an object of Protected VM, MoRef, Protection Group, State, Config Status and Faults from SRM Server.
Must be connected to SRM server.
.OUTPUTS
PSCUSTOMOBJECT SupSkiFun.ProtectedVMInfo
.EXAMPLE
Get-ProtectedVM
.EXAMPLE
$myvar = Get-ProtectedVM
#>
function Get-ProtectedVM
{
	Process
	{
		$srm=$global:DefaultSrmServers
		if(!$srm)
		{
			Write-Host -ForegroundColor Cyan "Connect to an SRM server first"
			break
		}
		$srmed = $srm.extensiondata
		$pgrps = $srmed.Protection.ListProtectionGroups()
		foreach ($pgrp in $pgrps)
		{
			$pvms = $pgrp.ListProtectedVms()
			foreach ($pvm in $pvms)
			{
			   	$pvm.vm.UpdateViewData()
				$loopobj=[pscustomobject]@{
					VM = $pvm.vm.config.name
					MoRef = $pvm.Vm.Moref
					ProtectionGroup = $pgrp.GetInfo().Name
					State = $pvm.State
					NeedsConfig = $pvm.NeedsConfiguration
					Faults = $pvm.Faults
				}
			$loopobj.PSObject.TypeNames.Insert(0,'SupSkiFun.ProtectedVMInfo')
			$loopobj
			}
		}
	}
}


