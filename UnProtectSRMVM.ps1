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
        #$stat = "CanBeProtected"
        $na = "Not Attempted"
        $stat = "IsProtected"
        $nil = "None"
        # Move this all to Process if SupposrtShouldProcess is used.
        $srmED = $DefaultSrmServers.ExtensionData
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
            #  Maybe just send the entire error object of $uinfo.Error?
            $lo=[pscustomobject]@{
                VM = $v.Name
                VMMoRef = $v.ExtensionData.Moref
                Status = $uinfo.State
                Error = $uinfo.Error.LocalizedMessage  # More to glean Here?
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
                State = $na  ;
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
            $vmo = $v.ExtensionData.Moref
            if ($pghash.ContainsKey($($cle)))
            {
                $targetpg = $pghash.Item($($cle))
                $protstat = $targetpg.QueryVmProtection($vmo)
                if ($protstat.Status -match $stat)
                {
                    $utask = $targetpg.UnProtectVms($vmo)
                    while(-not $utask.IsComplete()) 
                    { 
                        Start-Sleep -Seconds 1 
                    }
                    $uinfo = $utask.getresult()
                    MakeObj $uinfo
                }
                else
                {
                    $reason = "State is $($tms.Status).  State should be $stat."
                    MakeObj(MakeErr($reason)) 
                }
            }
            else
            {
                Write-Output "Not attempted Missing Protection Group USE VARIABLES for better message"
            }

            $uinfo = $null




        }
    }
}