Function Get-SRMTestStateTEST
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
            
            $lo = [pscustomobject]@{
                Name = $rp.Name
                State = $rp.GetInfo().State.ToString()
                RunningTask = $rp.RecoveryPlanHasRunningTask().ToString()
            }
            $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.Test.Status')
            $lo
        }
    }
}