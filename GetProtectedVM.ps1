Function Get-SRMProtectedVM{}
<#
.SYNOPSIS
Returns an object of Protected VMs.
.DESCRIPTION
Returns an object of Protected VM, MoRef, Protection Group, State, Config Status and Faults.
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
		$srmed = $DefaultSrmServers.extensiondata
		if(!$srm)
		{
			Write-Host -ForegroundColor Cyan "Connect to an SRM server first"
			break
		}

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


