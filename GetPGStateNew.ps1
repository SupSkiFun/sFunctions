class sClassNew     #Change
{
    static [pscustomobject] GetProtGrpInfo ([psobject] $pgrp)
    {
        <#
            Break this up or leave it be?
            $pgcn , $pgnm , $pgok, $pgpn , $pgst , $pgvm = $null
        #>
        $pgpn = $null
        $pgnm = $pgrp.GetInfo().Name.ToString()
        $pgvm = $pgrp.ListProtectedVms()
        $pgcn = $pgvm.where({$_.NeedsConfiguration -eq $true}).VmName #    | Sort-Object   Just leave it?
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
                $pgpn = "Run on Protected Site for more info."
                break
            }
        }

        $lo = [pscustomobject]@{
            Name = $pgnm
            State = $pgst
            ConfigOK = $pgok
            ConfigNeeded = $pgcn
            ProtectionNeeded = $pgpn
        }
        return $lo
    }

    static [array] GetUnProtVM ( [psobject] $pgrp , [psobject] $pgvn )
    {
        $dss = Get-Datastore -id ($pgrp.ListProtectedDatastores().Moref)
        $vms = (Get-VM -Datastore $dss).Name
        return $vms.Where({$pgvn -notcontains $_})
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
            $lo = [sClassNew]::GetProtGrpInfo($pgrp)
			$lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.Protection.Group.State')
            $lo
		}
	}
}