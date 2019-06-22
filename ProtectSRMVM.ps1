using module .\sClass.psm1
Function Protect-SRMVM
{
    [cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true , ValueFromPipeline = $true)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine[]]$VM
    )

    Begin
    {
        $srmED = $DefaultSrmServers.ExtensionData
		if(!$srmED)
		{
			Write-Output "Terminating.  Session is not connected to a SRM server."
			break
		}
        $stat = "CanBeProtected"
        $pgroups = $srmED.Protection.ListProtectionGroups()
        $pghash = [sClass]::MakePgHash($pgroups)
    }


    Process
    {

<#

        Function ChkDS
        {
            param($VMdsID)

            $pgla = $false

            foreach ($cl in $VMdsID)
            {
                if ($pghash.ContainsKey($($cl)))
                {
                    $pgla = $true
                }

            }

        }
#>

        Function ProtVM
        {
            param($targetpg,$VMmoref)

            $vspec = [VMware.VimAutomation.Srm.Views.SrmProtectionGroupVmProtectionSpec]::new()
            $vspec.Vm = $VMmoref
            $ptask = $targetpg.ProtectVms($vspec)
            while(-not $ptask.IsComplete())
            {
                Start-Sleep -Seconds 1
            }
            $pinfo = $ptask.getresult()
            $pinfo
        }

        foreach ($v in $vm)
        {
            $VMdsID = $v.ExtensionData.DataStore
            $VMdsName = $v.ExtensionData.Config.DataStoreURL.Name
            $VMmoref = $v.ExtensionData.Moref
            $VMname = $v.Name
            if ($pghash.ContainsKey($($VMdsID)))
            {
                $targetpg = $pghash.Item($($VMdsID))
                $protstat = $targetpg.QueryVmProtection($VMmoref)
                if ($protstat.Status -match $stat)
                {
                    $tinfo = ProtVM -targetpg $targetpg -VMmoref $VMmoref
                    $lo = [sClass]::MakeObj( $tinfo , $VMname , $VMmoref )
                }
                else
                {
                    $reason = "State is $($protstat.Status).  State should be $stat."
                    $lo = [sClass]::MakeObj( $reason , $VMname , $VMmoref )
                }
            }
            else
            {
                $reason = "Protection Group not found for DataStore $VMdsName($VMdsID) ."
                $lo = [sClass]::MakeObj( $reason , $VMname , $VMmoref )
            }

            $lo
            $tinfo , $lo  = $null
        }
    }
}