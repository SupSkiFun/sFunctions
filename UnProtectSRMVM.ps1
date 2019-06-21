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
        $na = "Not Attempted."
        $stat = "IsProtected"
        $nil = "None"
        # Move this all to Process if SupposrtShouldProcess is used.

        $pgroups = $srmED.Protection.ListProtectionGroups()
        $pghash = @{}
        foreach ($p in $pgroups)
        {
            $pghash.Add($p.ListProtectedDatastores().Moref,$p)
        }
    }

    Process
    {
        Function MakeObj
        {
            param($tinfo)
            $lo=[pscustomobject]@{
                VM = $v.Name
                VMMoRef = $v.ExtensionData.Moref
                Status = $tinfo.State
                Error = $tinfo.Error.LocalizedMessage
                Task = $tinfo.Name
                TaskMoRef = $tinfo.TaskMoRef
            }
            $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.Protect.Info')
            $lo
        }

        Function MakeErr
        {
            param($reason)
            $tinfo = @{
                State = $na +"  "+$reason ;
                Name = $nil ;
                TaskMoRef = $nil ;
                Error = @{
                    LocalizedMessage = $nil ;
                }
            }
            $tinfo
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
                    $ttask = $targetpg.UnProtectVms($VMmoref)
                    while(-not $ttask.IsComplete())
                    {
                        Start-Sleep -Seconds 1
                    }
                    $tinfo = $ttask.getresult()
                    MakeObj $tinfo
                }
                else
                {
                    $reason = "State is $($protstat.Status).  State should be $stat."
                    MakeObj(MakeErr($reason))
                }
            }
            else
            {
                $reason = "Protection Group not found for DataStore $VMdsName($VMdsID) ."
                MakeObj(MakeErr($reason))
            }

            $tinfo = $null
        }
    }
}