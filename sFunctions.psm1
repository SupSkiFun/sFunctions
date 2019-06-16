<#
.SYNOPSIS
 Connects to the SRM instance of the currently connected VCenter
.DESCRIPTION
 Connects to the SRM instance of the currently connected VCenter and its paired partner	with the current session
 username.  Prompts for a SRM password.  Password is applied locally and remotely.
.EXAMPLE
 csrm
#>
function csrm
{
    $CUser=$env:USERDOMAIN;$CUser=$CUser+"\";$CUser=$CUser+$env:USERNAME
    $CPass=Read-Host -AsSecureString -Prompt "Enter SRM password"
    Connect-SrmServer -SrmServerAddress $DefaultVIServer -User $CUser -Password $CPass -RemoteUser $CUser -RemotePassword $CPass
}

<#
.SYNOPSIS
Retrieves all SRM Recovery Plans
.DESCRIPTION
Retrieves all SRM Recovery Plans
.EXAMPLE
Place all the SRM Recovery Plans into a variable:
$allRP = Get-SRMRecoveryPlan
.EXAMPLE
Place SRM Recovery Plans matching a criteria into a variable:
$myRP = Get-SRMRecoveryPlan | Where-Object -Property Name -Match "CL07*"
#>

Function Get-SrmRecoveryPlan
{
    [cmdletbinding()]
    param()

    Begin
    {
        $srmED =  $DefaultSrmServers.ExtensionData
        #$srmED =  $global:DefaultSrmServers.ExtensionData
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

<#
.SYNOPSIS
Sends a Dismiss command to a SRM Recovery Plan
.DESCRIPTION
Sends a Dismiss command to a SRM Recovery Plan Prompt to continue plan execution.
Does not attempt if submitted plan is not in a Prompting state.
.PARAMETER RecoveryPlan
SRM Recovery Plan.  VMware.VimAutomation.Srm.Views.SrmRecoveryPlan
.EXAMPLE
$p = Get-SRMRecoveryPlan | Where-Object -Property Name -eq "PlanXYZ"
$p | Send-SRMDismiss
#>
Function Send-SRMDismiss
{
    [cmdletbinding(SupportsShouldProcess = $True , ConfirmImpact = "High")]
    Param
    (
        [Parameter (Mandatory = $true , ValueFromPipeline = $true)]
        [VMware.VimAutomation.Srm.Views.SrmRecoveryPlan[]] $RecoveryPlan
    )

    Begin
    {
        $ReqState = "Prompting"
    }
    Process
    {
        foreach ($rp in $RecoveryPlan)
        {
            $rpinfo = $rp.GetInfo()

            if ($pscmdlet.ShouldProcess( $rpinfo.Name , "Dismiss Prompt" ))
            {
                if ($rpinfo.State -eq $ReqState)
                {
                    $rp.AnswerPrompt($rp.ListPrompts().key , $false, "Dismiss")
                }

                else
                {
                    $mesg = "Not Sending Dismissal for $($rpinfo.Name).  State is $($rpinfo.State).  State should be $ReqState."
                    Write-Output "`n`t`t$mesg`n"
                }
            }
        }
    }
}

<#
.SYNOPSIS
Starts the SRM Cleanup Process.
.DESCRIPTION
Starts the SRM Cleanup Process for specified SRM Recovery Plans.
Does not attempt if submitted plan is not in a NeedsCleanup state.
.PARAMETER RecoveryPlan
SRM Recovery Plan.  VMware.VimAutomation.Srm.Views.SrmRecoveryPlan
.EXAMPLE
$p = Get-SRMRecoveryPlan | Where-Object -Property Name -eq "PlanXYZ"
$p | Start-SRMCleanUp
#>
Function Start-SRMCleanUp
{
    [cmdletbinding(SupportsShouldProcess = $True , ConfirmImpact = "High")]
    Param
    (
        [Parameter (Mandatory = $true , ValueFromPipeline = $true )]
        [VMware.VimAutomation.Srm.Views.SrmRecoveryPlan[]] $RecoveryPlan
    )

    Begin
    {
        [VMware.VimAutomation.Srm.Views.SrmRecoveryPlanRecoveryMode] $RecoveryMode = [VMware.VimAutomation.Srm.Views.SrmRecoveryPlanRecoveryMode]::CleanUpTest
        $ReqState = "NeedsCleanup"
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
                    $rp.Start($RecoveryMode)
                }

                else
                {
                    $mesg = "Not Starting Cleanup for $($rpinfo.Name).  State is $($rpinfo.State).  State should be $ReqState."
                    Write-Output "`n`t`t$mesg`n"
                }
            }
        }
    }
}

<#
.SYNOPSIS
Starts a Test SRM Recovery Plan.
.DESCRIPTION
Starts a Test SRM Recovery Plan, optionally synching data.
Does not attempt if submitted plan is not in a Ready state.
.PARAMETER RecoveryPlan
SRM Recovery Plan.  VMware.VimAutomation.Srm.Views.SrmRecoveryPlan
.PARAMETER SyncData
Future:  Defaults to False.  Can be set True to Sync Data.  Believe exposed in SRM 6.5 API
.EXAMPLE
$p = Get-SRMRecoveryPlan | Where-Object -Property Name -eq "PlanXYZ"
$p | Start-SRMTest
.EXAMPLE
Future Functionality Below:
$p = Get-SRMRecoveryPlan | Where-Object -Property Name -eq "PlanXYZ"
$p | Start-SRMTest -SyncData=$False
#>

Function Start-SRMTest
{
    [cmdletbinding(SupportsShouldProcess = $True , ConfirmImpact = "High")]
    Param
    (
        [Parameter (Mandatory = $true, ValueFromPipeline = $true, Position = 1)]
        [VMware.VimAutomation.Srm.Views.SrmRecoveryPlan[]] $RecoveryPlan,

        [bool] $SyncData = $False
    )

    Begin
    {
        [VMware.VimAutomation.Srm.Views.SrmRecoveryPlanRecoveryMode] $RecoveryMode = [VMware.VimAutomation.Srm.Views.SrmRecoveryPlanRecoveryMode]::Test
        $ReqState = "Ready"

        <#
        Below two lines for creating the option to synch or not.  Believe exposed in SRM 6.5 API
        Also modify the entry in the process block.
        $rpOpt = New-Object VMware.VimAutomation.Srm.Views.SrmRecoveryOptions
        $rpOpt.SyncData = $SyncData
        #>

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
                    <#
                    With Synch false purposely set, API 6.5 or Higher hopefully.
                    $rp.Start($RecoveryMode,$rpOpt)
                    #>

                    $rp.Start($RecoveryMode)
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

Export-ModuleMember -Function * -Alias * -Cmdlet * -Variable *