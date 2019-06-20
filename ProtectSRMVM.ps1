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
        $stok = "CanBeProtected"
        $stbad        
        $na = "Not Attempted."
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
            param($uinfo)
            $lo=[pscustomobject]@{
                VM = $v.Name
                VMMoRef = $v.ExtensionData.Moref
                Status = $uinfo.State
                Error = $uinfo.Error.LocalizedMessage
                Task = $uinfo.Name
                TaskMoRef = $uinfo.TaskMoRef
            }
            $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.UnProtect.Info')
            $lo
        }

        Function MakeErr
        {
            #Better idea?
            param($reason)
            $uinfo = @{
                State = $na +"  "+$reason ;
                Name = $nil ;
                TaskMoRef = $nil ;
                Error = @{
                    LocalizedMessage = $nil ;
                }
            }
            $uinfo
        }

        

        foreach ($v in $vm)
        {
            $cle = $v.ExtensionData.DataStore
            $nom = $v.ExtensionData.Config.DataStoreURL.Name
            $vmo = $v.ExtensionData.Moref
            if ($pghash.ContainsKey($($cle)))
            {
                $targetpg = $pghash.Item($($cle))
                $protstat = $targetpg.QueryVmProtection($vmo)
                if ($protstat.Status -match $stok)
                {
                    $vspec = [VMware.VimAutomation.Srm.Views.SrmProtectionGroupVmProtectionSpec]::new()
                    $vspec.Vm = $vmo
                    $utask = $targetpg.ProtectVms($vspec)
                    while(-not $utask.IsComplete())
                    {
                        Start-Sleep -Seconds 1
                    }
                    $uinfo = $utask.getresult()
                    MakeObj $uinfo
                }
                else
                {
                    $reason = "State is $($protstat.Status).  State should be $stat."
                    MakeObj(MakeErr($reason))
                }
            }
            else
            {
                $reason = "Protection Group not found for DataStore $nom , $cle"
                MakeObj(MakeErr($reason))
            }

            $uinfo = $null
        }
    }
}