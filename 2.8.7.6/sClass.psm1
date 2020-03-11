class sClass
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
            Status = $protstat.Status.ToString()
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