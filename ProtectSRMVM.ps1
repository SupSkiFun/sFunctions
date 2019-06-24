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
            $VMmoref = $v.ExtensionData.Moref
            $VMname = $v.Name

            # maybe switch just on $VMdsID or revert to for loop starting
            # driectly above the upper for loop?
            # don't think below is going to work.
            switch ($VMdsID)
            #  Allows looping if more than one $VMdsID.  Right?  :)
            #  Is the continue returning to the for loop?  Despite all of this, still just processing one $VMdsID!

            {
                {$pghash.ContainsKey($($_)) -eq $false}
                {
                    #$reason = "Protection Group not found for DataStore $VMdsName($VMdsID) ."
                    $VMdsName = (Get-Datastore -Id $_).Name
                    $reason = "Protection Group not found for DataStore $VMdsName($_) ."
                    $lo = [sClass]::MakeObj( $reason , $VMname , $VMmoref )
                    continue
                }
                {$pghash.ContainsKey($($_)) -eq $true}
                {
                    #$targetpg = $pghash.Item($($VMdsID))
                    $targetpg = $pghash.Item($($_))
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
                    break
                }
            }


            $lo
            $tinfo , $lo  = $null
        }
    }
}