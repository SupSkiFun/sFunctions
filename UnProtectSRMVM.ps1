using module .\sClass.psm1
Function UnProtect-SRMVM
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
        $stat = "IsProtected"
        $pgroups = $srmED.Protection.ListProtectionGroups()
        $pghash = [Sclass]::MakePgHash($pgroups)
    }

    Process
    {
        foreach ($v in $vm)
        {
            Function UnProtVM
            {
                param($targetpg,$VMmoref)

                $ptask = $targetpg.UnProtectVms($VMmoref)
                while(-not $ptask.IsComplete())
                {
                    Start-Sleep -Seconds 1
                }
                $tinfo = $ptask.getresult()
                $tinfo
            }

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
                    $tinfo = UnProtVM -targetpg $targetpg -VMmoref $VMmoref
                    $lo = [Sclass]::MakeObj( $tinfo , $VMname , $VMmoref )
                }
                else
                {
                    $reason = "State is $($protstat.Status).  State should be $stat."
                    $lo = [Sclass]::MakeObj( $reason , $VMname , $VMmoref )
                }
            }
            else
            {
                $reason = "Protection Group not found for DataStore $VMdsName($VMdsID) ."
                $lo = [Sclass]::MakeObj( $reason , $VMname , $VMmoref )
            }

            $lo
            $tinfo , $lo  = $null
        }
    }
}