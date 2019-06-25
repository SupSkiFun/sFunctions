Function Get-SRMUnProtectedVM{}

<#
Below is from MeadowCroft - need to test and tailor

#>


<#
.SYNOPSIS
Get the unprotected VMs that are associated with a protection group

.PARAMETER ProtectionGroup
Return unprotected VMs associated with particular protection
groups. For VR protection groups this is VMs that are associated
with the PG but not configured, For ABR protection groups this is
VMs on replicated datastores associated with the group that are not
configured.
#>
Function Get-UnProtectedVM {
    [cmdletbinding()]
    Param(
        [Parameter (ValueFromPipeline=$true)][VMware.VimAutomation.Srm.Views.SrmProtectionGroup[]] $ProtectionGroup,
        [Parameter (ValueFromPipeline=$true)][VMware.VimAutomation.Srm.Views.SrmRecoveryPlan[]] $RecoveryPlan,
        [string] $ProtectionGroupName,
        [VMware.VimAutomation.Srm.Types.V1.SrmServer] $SrmServer
    )

    if ($null -eq $ProtectionGroup) {
        $ProtectionGroup = Get-ProtectionGroup -Name $ProtectionGroupName -RecoveryPlan $RecoveryPlan -SrmServer $SrmServer
    }

    $associatedVMs = @()
    $protectedVmRefs = @()

    $ProtectionGroup | ForEach-Object {
        $pg = $_
        # For VR listAssociatedVms to get list of VMs
        if ($pg.GetInfo().Type -eq 'vr') {
            $associatedVMs += @($pg.ListAssociatedVms() | Get-VIObjectByVIView)
        }
        # TODO test this: For ABR get VMs on GetProtectedDatastore
        if ($pg.GetInfo().Type -eq 'san') {
            $pds = @(Get-ProtectedDatastore -ProtectionGroup $pg)
            $pds | ForEach-Object {
                $ds = Get-Datastore -id $_.MoRef
                $associatedVMs += @(Get-VM -Datastore $ds)
            }
        }

        # get protected VMs
        $protectedVmRefs += @(Get-ProtectedVM -ProtectionGroup $pg | ForEach-Object { $_.Vm.MoRef } | Select-Object -Unique)
    }

    # get associated but unprotected VMs
    $associatedVMs | Where-Object { $protectedVmRefs -notcontains $_.ExtensionData.MoRef }
}


#Untested as I don't have ABR setup in my lab yet 