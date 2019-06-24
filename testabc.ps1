<#
.SYNOPSIS
Retrieves SRM Protection Groups
.DESCRIPTION
Retrieves SRM Protection Groups
.OUTPUTS
VMware.VimAutomation.Srm.Views.SrmProtectionGroup
.EXAMPLE
Place all the SRM Protection Groups into a variable:
$allRP = Get-SRMProtectionGroup
.EXAMPLE
Place SRM Protection Groups matching a criteria into a variable:
$myRP = Get-SRMProtectionGroup | Where-Object -Property Name -Match "DS1"
#>
function Get-SRMProtectionGroup
{
    Begin
    {
        $srmED =  $DefaultSrmServers.ExtensionData
        if(!$srmED)
		{
			Write-Output "Terminating.  Session is not connected to a SRM server."
			break
		}
        $pgrps = $srmED.Protection.ListProtectionGroups()
    }

    Process
	{
        foreach ($pgrp in $pgrps)
        {
            $pnom = $pgrp.GetInfo().Name
            Add-Member -InputObject $pgrp -MemberType NoteProperty -Name "Name" -Value $pnom
        }
    }
    
    End
    {
        $pgrps
    }
}

<#
.SYNOPSIS
Retrieves SRM Recovery Plans
.DESCRIPTION
Retrieves SRM Recovery Plans
.OUTPUTS
VMware.VimAutomation.Srm.Views.SrmRecoveryPlan
.EXAMPLE
Place all the SRM Recovery Plans into a variable:
$allRP = Get-SRMRecoveryPlan
.EXAMPLE
Place SRM Recovery Plans matching a criteria into a variable:
$myRP = Get-SRMRecoveryPlan | Where-Object -Property Name -Match "CL07*"
#>

Function Get-SRMRecoveryPlan
{
    [cmdletbinding()]
    param()

    Begin
    {
        $srmED =  $DefaultSrmServers.ExtensionData
        $plans = $srmED.Recovery.ListPlans()
    }

    Process
    {
        foreach ($plan in $plans)
        {
            $pnom = $plan.GetInfo().Name
            Add-Member -InputObject $plan -MemberType NoteProperty -Name "Name" -Value $pnom
        }
    }

    End
    {
        $plans
    }
}