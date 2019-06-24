using module .\sClass.psm1
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
                        break
                    }
                }

            $tinfo , $lo  = $null
        }
    }
}