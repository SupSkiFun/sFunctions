<#
.SYNOPSIS
Starts a Test SRM Recovery Plan.
.DESCRIPTION
Starts a Test SRM Recovery Plan, optionally synching data.
Does not attempt if submitted plan is not in a Ready state.  Must be run on the recovery site.
.PARAMETER RecoveryPlan
SRM Recovery Plan.  VMware.VimAutomation.Srm.Views.SrmRecoveryPlan
.PARAMETER SyncData
Defaults to False.  Can be set True to Sync Data.
.INPUTS
VMware.VimAutomation.Srm.Views.SrmRecoveryPlan
.EXAMPLE
Start SRM Test meeting a selection criteria:
$p = Get-SRMRecoveryPlan | Where-Object -Property Name -eq "PlanXYZ"
$p | Start-SRMTest
.EXAMPLE
Start SRM Test(s) meeting a selection criteria, synchronizing storage:
$p = Get-SRMRecoveryPlan | Where-Object -Property Name -match "ProdWeb*"
$p | Start-SRMTest -SyncData True
#>

Function Start-SRMTestNEW   # Start-SRMTest
{
    [cmdletbinding(SupportsShouldProcess = $True , ConfirmImpact = 'High')]
    Param
    (
        [Parameter (Mandatory = $true, ValueFromPipeline = $true, Position = 1)]
        [VMware.VimAutomation.Srm.Views.SrmRecoveryPlan[]] $RecoveryPlan,

        [Parameter (ValidateSet = 'True' , 'False')] $SyncData = 'False'
    )

    Begin
    {
        [VMware.VimAutomation.Srm.Views.SrmRecoveryPlanRecoveryMode] $RecoveryMode = [VMware.VimAutomation.Srm.Views.SrmRecoveryPlanRecoveryMode]::Test
        $ReqState = "Ready"
        $rpOpt = [VMware.VimAutomation.Srm.Views.SrmRecoveryOptions]::new()
        $rpOpt.SyncData = [bool] $SyncData
    }

    Process
    {
        foreach ($rp in $RecoveryPlan)
        {
            $rpinfo = $rp.GetInfo()

            if ($pscmdlet.ShouldProcess($rpinfo.Name, $RecoveryMode))
            {
                if ($rpinfo.State -eq $ReqState)
                {
                    $rp.Start($RecoveryMode,$rpOpt)
                }

                else
                {
                    $mesg = "Not Starting Test of $($rpinfo.Name).  State is $($rpinfo.State).  State should be $ReqState."
                    Write-Output "`n`t`t$mesg`n"
                }
            }
        }
    }
}