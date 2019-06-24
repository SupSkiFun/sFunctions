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
        $pghash = [sClass]::MakePgHash($pgroups)
    }

    Process
    {
            Function UnProtVM
            {
                param($targetpg,$VMmoref)

                $ptask = $targetpg.UnProtectVms($VMmoref)
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
                switch ($VMdsID)
                #  Switch loops if more than one $VMdsID.
                {
                    {$pghash.ContainsKey($($_)) -eq $false}
                    {
                        $VMdsName = (Get-Datastore -Id $_).Name
                        $reason = "Protection Group not found for DataStore $VMdsName($_) ."
                        $lo = [sClass]::MakeObj( $reason , $VMname , $VMmoref )
                        $lo
                    }

                    {$pghash.ContainsKey($($_)) -eq $true}
                    {
                        $targetpg = $pghash.Item($($_))
                        $protstat = $targetpg.QueryVmProtection($VMmoref)
                        if ($protstat.Status -match $stat)
                        {
                            $tinfo = UnProtVM -targetpg $targetpg -VMmoref $VMmoref
                            $lo = [sClass]::MakeObj( $tinfo , $VMname , $VMmoref )
                            $lo
                        }

                        else
                        {
                            $reason = "State is $($protstat.Status).  State should be $stat."
                            $lo = [sClass]::MakeObj( $reason , $VMname , $VMmoref )
                            $lo
                        }
                    }
                }

            $tinfo , $lo  = $null
        }
    }
}