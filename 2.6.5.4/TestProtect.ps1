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

Function MakeTobj
{
    <#  Helper Function used by Protect-SRMVM and UnProtect-SRMVM   #>

    param($tinfo , $VMname, $VMmoref )

    $lo = [pscustomobject]@{
        VM = $VMname
        VMMoRef = $VMmoref
        Status = $tinfo.State
        Error = $tinfo.Error.LocalizedMessage
        Task = $tinfo.Name
        TaskMoRef = $tinfo.TaskMoRef
    }
    $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.Protect.Info')
    $lo
}

<#
.SYNOPSIS
Protects SRM VMs
.DESCRIPTION
Protects SRM VMs.  Must be run on the protected site.
Attempts only if VM Protection State is "CanBeProtected" and an affiliated Protection Group can be located.
.PARAMETER VM
Output from VMWare PowerCLI Get-VM.  See Examples.
[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]
.INPUTS
VMWare PowerCLI VM from Get-VM:
[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]
.OUTPUTS
[pscustomobject] SupSkiFun.SRM.Protect.Info
.EXAMPLE
Protect one VM:
Get-VM -Name SYS01 | Protect-SRMVM
.EXAMPLE
Protect multiple VMS, returning the object into a variable:
$myVar = Get-VM -Name WEB* | Protect-SRMVM
#>
Function Protect-SRMVMTEST  # Remove Trailing TEST
{
    [cmdletbinding()]
    Param
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
        $stat = "CanBeProtected"
        $pgroups = $srmED.Protection.ListProtectionGroups()
        $pghash = [sClasss]::MakePgHash($pgroups)   # Remove trailing s
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
            switch ($VMdsID)
            #  Switch loops if more than one $VMdsID.
            {
                {$pghash.ContainsKey($($_)) -eq $false}
                {
                    $VMdsName = (Get-Datastore -Id $_).Name
                    $reason = "Protection Group not found for DataStore $VMdsName($_) ."
                    $lo = [sClasss]::MakeObj( $reason , $VMname , $VMmoref ) # Remove trailing s
                    $lo
                }

                {$pghash.ContainsKey($($_)) -eq $true}
                {
                    $targetpg = $pghash.Item($($_))
                    $protstat = $targetpg.QueryVmProtection($VMmoref)
                    if ($protstat.Status -match $stat)
                    {
                        $tinfo = ProtVM -targetpg $targetpg -VMmoref $VMmoref
                        $lo = MakeTObj -tinfo $tinfo -VMname $VMname -VMmoref $VMmoref
                        $lo
                    }
                    else
                    {
                        $reason = "State is $($protstat.Status).  State should be $stat."
                        $lo = [sClasss]::MakeObj( $reason , $VMname , $VMmoref ) # Remove trailing s
                        $lo
                    }
                    break
                }
            }

            $tinfo , $lo  = $null
        }
    }
}

<#
.SYNOPSIS
UnProtects SRM VMs
.DESCRIPTION
UnProtects SRM VMs.  Must be run on the protected site.
Attempts only if VM Protection State is "IsProtected" and an affiliated Protection Group can be located.
.PARAMETER VM
Output from VMWare PowerCLI Get-VM.  See Examples.
[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]
.INPUTS
VMWare PowerCLI VM from Get-VM:
[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]
.OUTPUTS
[pscustomobject] SupSkiFun.SRM.Protect.Info
.EXAMPLE
UnProtect one VM:
Get-VM -Name SYS01 | UnProtect-SRMVM
.EXAMPLE
UnProtect multiple VMS, returning the object into a variable:
$myVar = Get-VM -Name WEB* | UnProtect-SRMVM
#>
Function UnProtect-SRMVMTEST    # Remove Trailing TEST
{
    [cmdletbinding()]
    Param
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
        $stat = "IsProtected"
        $pgroups = $srmED.Protection.ListProtectionGroups()
        $pghash = [sClasss]::MakePgHash($pgroups)    # Remove trailing s
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
                        $lo = [sClasss]::MakeObj( $reason , $VMname , $VMmoref ) # Remove trailing s
                        $lo
                    }

                    {$pghash.ContainsKey($($_)) -eq $true}
                    {
                        $targetpg = $pghash.Item($($_))
                        $protstat = $targetpg.QueryVmProtection($VMmoref)
                        if ($protstat.Status -match $stat)
                        {
                            $tinfo = UnProtVM -targetpg $targetpg -VMmoref $VMmoref
                            $lo = MakeTObj -tinfo $tinfo -VMname $VMname -VMmoref $VMmoref
                            $lo
                        }

                        else
                        {
                            $reason = "State is $($protstat.Status).  State should be $stat."
                            $lo = [sClasss]::MakeObj( $reason , $VMname , $VMmoref ) # Remove trailing s
                            $lo
                        }
                        break
                    }
                }

            $tinfo , $lo  = $null
        }
    }
}