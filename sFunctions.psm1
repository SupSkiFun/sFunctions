using module .\sClass.psm1
<#
.SYNOPSIS
Connects to the SRM instance of the currently connected VCenter
.DESCRIPTION
Connects to the SRM instance of the currently connected VCenter and its paired partner with the current
session username.  Prompts for a SRM password.  Password is applied locally and remotely.
.EXAMPLE
csrm
#>
Function csrm
{
    $CUser=$env:USERDOMAIN;$CUser=$CUser+"\";$CUser=$CUser+$env:USERNAME
    $CPass=Read-Host -AsSecureString -Prompt "Enter SRM password"
    Connect-SrmServer -SrmServerAddress $DefaultVIServer -User $CUser -Password $CPass -RemoteUser $CUser -RemotePassword $CPass
}

<#
.SYNOPSIS
Lists Protection Groups
.DESCRIPTION
Outputs an object of Protection Group Name, State and MoRef.
.OUTPUTS
PSCUSTOMOBJECT SupSkiFun.SRM.ProtectionGroup.Info
.EXAMPLE
Output to Screen:
Get-SRMProtectionGroup
.EXAMPLE
Output to Variable
$myvar = Get-SRMProtectionGroup
#>
function Get-SRMProtectionGroup
{
    Begin
    {
        $srmED = $DefaultSrmServers.ExtensionData
        if(!$srmED)
        {
            Write-Output "Terminating.  Session is not connected to a SRM server."
            break
        }
        $protgrps=$srmED.Protection.ListProtectionGroups()
    }
    Process
	{
		foreach ($protgrp in $protgrps)
		{
			$lo=[pscustomobject]@{
				Name = $protgrp.GetInfo().Name
				State = $protgrp.GetProtectionState()
                MoRef = $protgrp.MoRef
                Object = $protgrp
			}
			$lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.ProtectionGroup.Info')
			$lo
		}
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

<#
.SYNOPSIS
Sends a Dismiss command to a SRM Recovery Plan
.DESCRIPTION
Sends a Dismiss command to a SRM Recovery Plan Prompt to continue plan execution.
Does not attempt if submitted plan is not in a Prompting state.  Must be run on the recovery site.
.PARAMETER RecoveryPlan
SRM Recovery Plan.  VMware.VimAutomation.Srm.Views.SrmRecoveryPlan
.INPUTS
VMware.VimAutomation.Srm.Views.SrmRecoveryPlan
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
Shows Relationship amongst Recovery Plans, Protection Groups, and DataStores.
.DESCRIPTION
Shows Relationship amongst Recovery Plans, Protection Groups, and DataStores.  Returns an object of RecoveryPlan,
ProtectionGroup, DataStore, RecoveryPlanMoRef, ProtectionGroupMoref, and DataStoreMoRef.  DataStore Name is
Not Available when run from the Recovery Site; it is only available when run from the Protection Site.
.PARAMETER RecoveryPlan
SRM Recovery Plan.  VMware.VimAutomation.Srm.Views.SrmRecoveryPlan
.INPUTS
VMware.VimAutomation.Srm.Views.SrmRecoveryPlan
.OUTPUTS
PSCUSTOMOBJECT SupSkiFun.SRM.Info
.EXAMPLE
Show Relationship of all SRM Recovery Plans returning object into a variable:
$allRP = Get-SRMRecoveryPlan
$MyVar = $allRP | Show-SRMRelationship
.EXAMPLE
Show Relationship of specific SRM Recovery Plan(s) matching a criteria, returning object into a variable:
$myRP = Get-SRMRecoveryPlan | Where-Object -Property Name -Match "CL07*"
$MyVar = $myRP | Show-SRMRelationship
#>
Function Show-SRMRelationship
{
    [cmdletbinding()]
    Param
    (
        [Parameter (Mandatory = $true, ValueFromPipeline = $true)]
        [VMware.VimAutomation.Srm.Views.SrmRecoveryPlan[]] $RecoveryPlan
    )

    Begin
    {
        $nota = "Not Available on Recovery Site; only available from the Protection Site"
    }

    Process
    {
        foreach ($plan in $RecoveryPlan)
        {
            $ap = $plan.GetInfo()
            $pg = $ap.ProtectionGroups.GetInfo().Name
            $ar = $ap.ProtectionGroups.ListProtectedDatastores().Moref

            if ($ap.State -match "Protecting")
            {
                $ds = (get-datastore -id $ar).Name
            }
            else
            {
                $ds = $nota
            }

            $lo = [pscustomobject]@{
                RecoveryPlan = $ap.Name
                RecoveryPlanState = $ap.State
                ProtectionGroup = $pg
                Datastore = $ds
                RecoveryPlanMoRef = $plan.MoRef
                ProtectionGroupMoRef = $ap.ProtectionGroups.Moref
                DataStoreMoRef = $ar
            }
            $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.Info')
            $lo
        }
    }
}

<#
.SYNOPSIS
Starts the SRM Cleanup Process.
.DESCRIPTION
Starts the SRM Cleanup Process for specified SRM Recovery Plans.
Does not attempt if submitted plan is not in a NeedsCleanup state.  Must be run on the recovery site.
.PARAMETER RecoveryPlan
SRM Recovery Plan.  VMware.VimAutomation.Srm.Views.SrmRecoveryPlan
.INPUTS
VMware.VimAutomation.Srm.Views.SrmRecoveryPlan
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
Does not attempt if submitted plan is not in a Ready state.  Must be run on the recovery site.
.PARAMETER RecoveryPlan
SRM Recovery Plan.  VMware.VimAutomation.Srm.Views.SrmRecoveryPlan
.PARAMETER SyncData
Future:  Defaults to False.  Can be set True to Sync Data.  Believe exposed in SRM 6.5 API
.INPUTS
VMware.VimAutomation.Srm.Views.SrmRecoveryPlan
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

<#
.SYNOPSIS
Stops / cancels an SRM Test.
.DESCRIPTION
Stops / cancels an SRM Test for specified SRM Recovery Plans.
Does not attempt if submitted plan is not in a Running or Prompting state.  Must be run on the recovery site.
.PARAMETER RecoveryPlan
SRM Recovery Plan.  VMware.VimAutomation.Srm.Views.SrmRecoveryPlan
.INPUTS
VMware.VimAutomation.Srm.Views.SrmRecoveryPlan
.EXAMPLE
$p = Get-SRMRecoveryPlan | Where-Object -Property Name -eq "PlanXYZ"
$p | Stop-SRMTest
#>
Function Stop-SRMTest
{
    [cmdletbinding(SupportsShouldProcess = $True , ConfirmImpact = "High")]
    Param
    (
        [Parameter (Mandatory = $true , ValueFromPipeline = $true )]
        [VMware.VimAutomation.Srm.Views.SrmRecoveryPlan[]] $RecoveryPlan
    )

    Begin
    {
        $ReqState = "Running" , "Prompting"
    }

    Process
    {
        foreach ($rp in $RecoveryPlan)
        {
            $rpinfo = $rp.GetInfo()

            if ($pscmdlet.ShouldProcess($rpinfo.Name, 'Cancel'))
            {
                if ($rpinfo.State -in $ReqState)
                {
                    $rp.Cancel()
                }

                else
                {
                    $mesg = "Not Stopping $($rpinfo.Name).  State is $($rpinfo.State).  State should be $($ReqState  -join " or ")."
                    Write-Output "`n`t`t$mesg`n"
                }
            }
        }
    }
}

Export-ModuleMember -Function * -Alias * -Cmdlet * -Variable *