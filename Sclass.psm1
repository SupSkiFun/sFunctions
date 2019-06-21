class SClass
{
    static [hashtable] MakePgHash ([psobject] $pgroups )
    {
        $pghash = @{}
        foreach ($p in $pgroups)
        {
            $pghash.Add($p.ListProtectedDatastores().Moref,$p)
        }
        return $pghash
    }

    static [pscustomobject] MakeObj([string] $reason , [string] $VMname, [string] $VMmoref )
    {
        $nil = "None"
        $lo = [pscustomobject]@{
            VM = $VMname
            VMMoRef = $VMmoref
            Status = "Not Attempted. "+$reason
            Error = $nil
            Task = $nil
            TaskMoRef = $nil
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.Protect.Info')
        return $lo
    }

    static [pscustomobject] MakeObj( [VMware.VimAutomation.Srm.Views.SrmTaskInfo] $tinfo , [string] $VMname, [string] $VMmoref )
    {
        $lo = [pscustomobject]@{
            VM = $VMname
            VMMoRef = $VMmoref
            Status = $tinfo.State
            Error = $tinfo.Error.LocalizedMessage
            Task = $tinfo.Name
            TaskMoRef = $tinfo.TaskMoRef
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.Protect.Info')
        return $lo
    }

        <#  Still need this?

        static [hashtable] MakeErr( [string] $reason )
        {
            $nil = "None"
            $einfo = @{
                State = "Not Attempted. "+$reason ;
                Name = $nil ;
                TaskMoRef = $nil ;
                Error = @{
                    LocalizedMessage = $nil ;
                }
            }
            return $einfo
        }
        #>
}
