<#

The Below is old code that needs to be refactored!  

#>




<#.Synopsis
Obtains SRM VM Protection Information
.DESCRIPTION
Returns an object of VM, MoRef, Status, ProtectionGroup, ProtectedVM and PeerProtectedVm.
Must be connected to both the local and remote SRM servers.
.PARAMETER VM
Enter or Pipe VM names to check.
.OUTPUTS
PSCUSTOMOBJECT SupSkiFun.SRMVMInfo
.EXAMPLE
Returns object for one VM to the screen:
Get-SRMVM -VM Server01
.EXAMPLE
Places an object of several VMs into a variable:
$myVar = Get-VM -Name Test* | Get-SRMVM
#>
function Get-SRMVM
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true,
			ValueFromPipelineByPropertyName=$true,
			HelpMessage = "Enter one or more VM names"
		)]
		[Alias("Name")]
        [string[]]$VM
	)

    Begin
    {
		$srm=$global:DefaultSrmServers
		if(!$srm)
		{
			Write-Host -ForegroundColor Cyan "Connect to an SRM server first"
			break
		}
		$srmed = $srm.extensiondata
		$pgrps = $srmed.Protection.ListProtectionGroups()
		$nodata = "No Data"
		$errenc = "Error Encountered"
    }

	Process
	{
		foreach ($v in $vm)
		{
			$pinfo = $null ; $vmgds = $null; $tgrp = $null
			try
			{
				$vmg = Get-VM -Name $v -EV err -EA SilentlyContinue
				$vmgds = $vmg.ExtensionData.Config.DatastoreUrl.Name
				$tgrp = $pgrps | where {$_.getinfo().name -match $vmgds}
				if($tgrp -ne $null)
				{
					$pinfo = $tgrp.QueryVmProtection($vmg.ExtensionData.MoRef)
					$loopobj=[pscustomobject]@{
						VM = $vmg.Name
						MoRef = $vmg.ExtensionData.Moref
						Status = $pinfo.Status
						ProtectionGroup = $pinfo.ProtectionGroupName
						ProtectedVm	= $pinfo.ProtectedVm
						PeerProtectedVm = $pinfo.PeerProtectedVm
 					}
				}
				elseif($tgrp -eq $null)
				{
				  	$loopobj=[pscustomobject]@{
						VM = $v
						MoRef = $errenc
						Status = "Protection Group Not Found for Datastore $vmgds"
						ProtectionGroup = $nodata
						ProtectedVm	= $nodata
						PeerProtectedVm = $nodata
 					}
				}
				$loopobj.PSObject.TypeNames.Insert(0,'SupSkiFun.SRMVMInfo')
				$loopobj
			}
			catch
			{
				$errmesg = $err.exception.ToString().split("`t")[3]
				$loopobj=[pscustomobject]@{
					VM = $v
					MoRef = $errenc
					Status = $errmesg
					ProtectionGroup = $nodata
					ProtectedVm	= $nodata
					PeerProtectedVm = $nodata
 				}
				$loopobj.PSObject.TypeNames.Insert(0,'SupSkiFun.SRMVMInfo')
				$loopobj
			}
		}
	}
}

