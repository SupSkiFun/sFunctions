<#
.SYNOPSIS
Returns current state of SRM Test.
.DESCRIPTION
Returns current state of SRM Test.  Can be run on the recovery or protected site.
.PARAMETER RecoveryPlan
SRM Recovery Plan.  VMware.VimAutomation.Srm.Views.SrmRecoveryPlan
.INPUTS
VMware.VimAutomation.Srm.Views.SrmRecoveryPlan
.OUTPUTS
[pscustomobject] SupSkiFun.SRM.Test.Status
.EXAMPLE
$p = Get-SRMRecoveryPlan | Where-Object -Property Name -eq "PlanXYZ"
$p | Get-SRMTestState
#>
Function Get-SRMTestState
{
    [cmdletbinding()]
    Param
    (
        [Parameter (Mandatory = $true , ValueFromPipeline = $true )]
        [VMware.VimAutomation.Srm.Views.SrmRecoveryPlan[]] $RecoveryPlan
    )

    Process
    {
        foreach ($rp in $RecoveryPlan)
        {
            $st = $rp.GetInfo().State
            $lo = [pscustomobject]@{
                Name = $rp.Name
                State = $st
            }
            $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.Test.Status')
            $lo
        }
    }
}