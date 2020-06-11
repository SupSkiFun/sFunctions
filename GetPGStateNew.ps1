class sClassNew     #Change
{
    static [pscustomobject] GetProtGrpInfo ([psobject] $pgrp)
    {
        $pgpn = $null
        $pgnm = $pgrp.GetInfo().Name.ToString()
        $pgvm = $pgrp.ListProtectedVms()
        $pgcn = $pgvm.Where({$_.NeedsConfiguration -eq $true}).VmName
        $pgfl = $pgvm.Where({$null -ne $_.Faults}).VmName
        $pgok = $pgrp.CheckConfigured()
        $pgst = $pgrp.GetProtectionState().ToString()

        switch ($pgok)
        {
            {$_ -eq $false -and $pgst -ne 'Shadowing'}
            {
                $pgpn = [sClassNew]::GetUnProtVM( ($pgrp.ListProtectedDatastores().Moref) , ($pgvm.VmName) )    #Change
                break
            }

            {$_ -eq $false -and $pgst -eq 'Shadowing'}
            {
                $pgpn = "See Help"
                break
            }
        }

        $lo = [pscustomobject]@{
            Name = $pgnm
            State = $pgst
            ConfigOK = $pgok
            ConfigNeeded = $pgcn
            ProtectionNeeded = $pgpn
            Faults = $pgfl
        }
        return $lo
    }

    static [psobject] GetUnProtVM ( [psobject] $pgds , [psobject] $pgvn )
    {
        $dss = Get-Datastore -id $pgds
        $vms = (Get-VM -Datastore $dss).Name
        $npt = $vms.Where({$pgvn -notcontains $_})
        
        if ($npt)
        {
            return $npt
        }
        else
        {
            return $null
        }
    }
}

function Get-SRMProtectionGroupStateNew     #  Change
{
	[CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true , ValueFromPipeline = $true)]
        [VMware.VimAutomation.Srm.Views.SrmProtectionGroup[]] $ProtectionGroup
	)

	Process
	{
		foreach ($pgrp in $ProtectionGroup)
		{
            $lo = [sClassNew]::GetProtGrpInfo($pgrp)  #Change
			$lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.Protection.Group.State')
            $lo
		}
	}
}