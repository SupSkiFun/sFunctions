using module .\sClass.psm1

<#
.SYNOPSIS
Connects to the SRM instance of the currently connected VCenter
.DESCRIPTION
Connects to the SRM instance of the currently connected VCenter and its paired partner with the current
session username.  Prompts for a SRM password.  Password is applied locally and remotely.
Can be run on recovery or protected site.
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
Retrieves SRM Protection Groups
.DESCRIPTION
Retrieves SRM Protection Groups.  Can be run on recovery or protected site.
.OUTPUTS
VMware.VimAutomation.Srm.Views.SrmProtectionGroup
.EXAMPLE
Place all the SRM Protection Groups into a variable:
$allPG = Get-SRMProtectionGroup
.EXAMPLE
Place SRM Protection Groups matching a criteria into a variable:
$myPG = Get-SRMProtectionGroup | Where-Object -Property Name -Match "DS1"
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
Retrieves SRM Recovery Plans.  Can be run on recovery or protected site.
.OUTPUTS
VMware.VimAutomation.Srm.Views.SrmRecoveryPlan
.EXAMPLE
Place all the SRM Recovery Plans into a variable:
$allRP = Get-SRMRecoveryPlan
.EXAMPLE
Place SRM Recovery Plans matching a criteria into a variable:
$myRP = Get-SRMRecoveryPlan | Where-Object -Property Name -Match "CL07"
#>

Function Get-SRMRecoveryPlan
{
    [cmdletbinding()]
    param()

    Begin
    {
        $srmED =  $DefaultSrmServers.ExtensionData
        if(!$srmED)
		{
			Write-Output "Terminating.  Session is not connected to a SRM server."
			break
		}
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
Obtains SRM VM Protection Information
.DESCRIPTION
Returns an object of VM, VMMoRef, Status, DataStore, ProtectionGroup, RecoveryPlan, ProtectedVM and PeerProtectedVm.
Run on protected site to obtain full information.  Can be run on recovery site, but information is limited.
.PARAMETER VM
Output from VMWare PowerCLI Get-VM.  See Examples.
[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]
.INPUTS
VMWare PowerCLI VM from Get-VM:
[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]
.OUTPUTS
[pscustomobject] SupSkiFun.SRM.VM.Info
.EXAMPLE
Returns object for one VM to the screen:
Get-VM -Name Server01 | Get-SRMVM
.EXAMPLE
Places an object of several VMs into a variable:
$myVar = Get-VM -Name Test* | Get-SRMVM
#>
function Get-SRMVM
{
    [CmdletBinding()]
    param
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
        $pgroups = $srmED.Protection.ListProtectionGroups()
		$pghash = [sClass]::MakePgHash($pgroups)
		$nd = "No Data"
	}

	Process
	{
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
					$lo = [sClass]::MakeObj( $reason , $VMname , $VMmoref , $VMdsName , $nd )
					$lo
				}

                {$pghash.ContainsKey($($_)) -eq $true}
                {
                    $targetpg = $pghash.Item($($_))
					$protstat = $targetpg.QueryVmProtection($VMmoref)
					$VMdsName = (Get-Datastore -Id $_).Name
					$lo = [sClass]::MakeObj( $protstat , $VMname , $VMmoref , $VMdsName )
					$lo
				}
			}
			$protstat , $lo  = $null
		}
	}
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
Function Protect-SRMVM
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
        $stat = "CanBeProtected"
        $pgroups = $srmED.Protection.ListProtectionGroups()
        $pghash = [sClass]::MakePgHash($pgroups)
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
                    $lo = [sClass]::MakeObj( $reason , $VMname , $VMmoref )
                    $lo
                }

                {$pghash.ContainsKey($($_)) -eq $true}
                {
                    $targetpg = $pghash.Item($($_))
                    $protstat = $targetpg.QueryVmProtection($VMmoref)
                    if ($protstat.Status -match $stat)
                    {
                        $tinfo = ProtVM -targetpg $targetpg -VMmoref $VMmoref
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
Returns an object of Protected VMs.
.DESCRIPTION
Returns an object of Protected VMs from submitted Protection Groups.
Returns an object of VM, VMMoRef, ProtectedVM, PeerProtectedVm, ProtectionGroup, VMState,
PeerState, NeedsConfig and Faults.  Can be run on recovery or protected site.
Note:  VM Name is Not Available from the Recovery Site; it is only available from the Protection Site.
.PARAMETER ProtectionGroup
[VMware.VimAutomation.Srm.Views.SrmProtectionGroup]  See Examples.
.INPUTS
[VMware.VimAutomation.Srm.Views.SrmProtectionGroup]
.OUTPUTS
[pscustomobject] SupSkiFun.SRM.Protect.Info
.EXAMPLE
Return an object of VMs from specific Protection Group(s) into the myInfo variable:
$myPG = Get-SRMProtectionGroup | Where-Object -Property Name -Match "DS1"
$myInfo = $myPG | Show-SRMProtectedVM
.EXAMPLE
Return an object of VMs from all Protection Groups into the myInfo variable:
$myPG = Get-SRMProtectionGroup
$myInfo = $myPG | Show-SRMProtectedVM
#>
function Show-SRMProtectedVM
{
	[CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true , ValueFromPipeline = $true)]
        [VMware.VimAutomation.Srm.Views.SrmProtectionGroup[]] $ProtectionGroup
	)

	Begin
    {
        $nota = "Not Available on Recovery Site; only available from the Protection Site"
    }

	Process
	{
		foreach ($pgrp in $ProtectionGroup)
		{
			$pvms = $pgrp.ListProtectedVms()
			$pgst = $pgrp.GetProtectionState()
			foreach ($pvm in $pvms)
			{
				switch ($pgst)
				{
					Ready
					{
						$pvm.vm.UpdateViewData()
						$vmnom = $pvm.Vm.Config.Name
					}
					Shadowing
					{
						$vmnom = $nota
					}
				}

				$lo = [pscustomobject]@{
					VM = $vmnom
					VMMoRef = $pvm.Vm.Moref
					ProtectedVM = $pvm.ProtectedVm
					PeerProtectedVm = $pvm.PeerProtectedVm
					ProtectionGroup = $pgrp.Name
					VMState = $pvm.State
					PeerState = $pvm.PeerState
					NeedsConfig = $pvm.NeedsConfiguration
					Faults = $pvm.Faults
				}
			$lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.Protect.Info')
			$lo
			}
		}
	}
}

<#
.SYNOPSIS
Shows Relationship amongst Recovery Plans, Protection Groups, and DataStores.
.DESCRIPTION
Shows Relationship amongst Recovery Plans, Protection Groups, and DataStores.  Returns an object of RecoveryPlan,
ProtectionGroup, DataStore, RecoveryPlanMoRef, ProtectionGroupMoref, DataStoreMoRef, PeerMoRef and PeerState.
Can be run on recovery or protected site.
Note:  DataStore Name is Not Available from the Recovery Site; it is only available from the Protection Site.
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
            $pi = $plan.GetPeer()

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
                PeerMoRef = $pi.PlanMoRef
                PeerState = $pi.State
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

Export-ModuleMember -Function * -Alias * -Cmdlet * -Variable *