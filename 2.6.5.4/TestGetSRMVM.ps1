class sClasss   # Trailing S
{
    static [hashtable] MakeHash( [string] $quoi )
    {
        $src = $null
        $shash = @{}

        switch ($quoi)
        {
            ds { $src = Get-Datastore -Name * }
            ex { $src = Get-VMHost -Name * }
            vm { $src = Get-VM -Name * }
        }

        foreach ($s in $src)
        {
            $shash.add($s.Id , $s.Name)
        }
        return $shash
    }

    static [hashtable] MakePgHash ([psobject] $pgroups )
    {
        $pghash = @{}
        foreach ($p in $pgroups)
        {
            $pghash.Add($p.ListProtectedDatastores().Moref,$p)
        }
        return $pghash
    }

    static [pscustomobject] MakeObj( [string] $reason , [string] $VMname, [string] $VMmoref )
    {
        $nil = "None"
        $lo = [pscustomobject]@{
            VM = $VMname
            VMMoRef = $VMmoref
            Status = "Not Attempted. "+$reason
            Error = $nil
            Task = $nil
            TaskMoRef = $nil
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.Protect.Info')
        return $lo
    }

    static [pscustomobject] MakeObj( [psobject] $protstat , [string] $VMname, [string] $VMmoref , [string] $VMdsName)
    {
        $lo = [pscustomobject]@{
            VM = $VMname
            VMMoRef = $VMmoref
            Status = $protstat.Status
            DataStore = $VMdsName
            ProtectionGroup = $protstat.ProtectionGroupName
            RecoveryPlan = $protstat.RecoveryPlanNames
            ProtectedVm	= $protstat.ProtectedVm
            PeerProtectedVm = $protstat.PeerProtectedVm
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.VM.Info')
        return $lo
    }
    
    static [pscustomobject] MakeObj( [string] $reason , [string] $VMname, [string] $VMmoref , [string] $VMdsName , [string] $nd )
    {
        $lo = [pscustomobject]@{
            VM = $VMname
            VMMoRef = $VMmoref
            Status = "Not Attempted. "+$reason
            DataStore = $VMdsName
            ProtectionGroup = $nd
            RecoveryPlan = $nd
            ProtectedVm	= $nd
            PeerProtectedVm = $nd
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.VM.Info')
        return $lo
    }
}

<#
.SYNOPSIS
Obtains SRM VM Protection Information
.DESCRIPTION
Returns an object of VM, VMMoRef, Status, DataStore, ProtectionGroup, RecoveryPlan, ProtectedVM and PeerProtectedVm.
Run on protected site to obtain full information.  Can be run on recovery site, but information is limited.
.PARAMETER VM
Output from VMWare PowerCLI Get-VM.  See Examples.
[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]
.INPUTS
VMWare PowerCLI VM from Get-VM:
[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]
.OUTPUTS
[pscustomobject] SupSkiFun.SRM.VM.Info
.EXAMPLE
Returns object for one VM to the screen:
Get-VM -Name Server01 | Get-SRMVM
.EXAMPLE
Places an object of several VMs into a variable:
$myVar = Get-VM -Name Test* | Get-SRMVM
#>
function Get-SRMVMTest # Remove trailing Test
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true , ValueFromPipeline = $true)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]] $VM
	)

    Begin
    {
        $srmED = $DefaultSrmServers.ExtensionData
		if(!$srmED)
		{
			Write-Output "Terminating.  Session is not connected to a SRM server."
			break
		}
        $pgroups = $srmED.Protection.ListProtectionGroups()
        $pghash = [sClasss]::MakePgHash($pgroups)   # Trailing S
        $dshash = [sClasss]::MakeHash('ds')     # Trailing S
		$nd = "No Data"
	}

	Process
	{
		foreach ($v in $vm)
		{

			$VMdsID = $v.ExtensionData.DataStore
            $VMmoref = $v.ExtensionData.Moref
            $VMname = $v.Name
            foreach ($vmd in $VMdsID)
            {
                $ici = $pghash.GetEnumerator().where({ $_.Name -eq $($vmd).ToString() })
                $VMdsName = $dshash.($($vmd).ToString())

                if ($ici)
                {
                        $targetpg = $pghash.Item($($vmd))  # change to $vmd?
                        $protstat = $targetpg.QueryVmProtection($VMmoref)
                          # Move this up?!
                        $lo = [sClasss]::MakeObj( $protstat , $VMname , $VMmoref , $VMdsName )    # Trailing S
                        $lo
                }
                else
				{
					$reason = "Protection Group not found for DataStore $VMdsName."
					$lo = [sClasss]::MakeObj( $reason , $VMname , $VMmoref , $VMdsName , $nd )   # Trailing S
					$lo
				}

                $protstat , $lo  = $null
            }
		}
	}
}