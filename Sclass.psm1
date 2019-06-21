class SClass
{
    static [hashtable] MakePgHash ([psobject] $pgroups )
    #  Put the proper object in for Protection Groups replacing psobject
    {
        $pghash = @{}
        foreach ($p in $pgroups)
        {
            $pghash.Add($p.ListProtectedDatastores().Moref,$p)
        }
        return $pghash
    }

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

    static [pscustomobject] MakeObj( [hashtable] $oinfo , [string] $VMname, [string] $VMmoref )
    {
        $lo = [pscustomobject]@{
            VM = $VMname
            VMMoRef = $VMmoref
            Status = $oinfo.State
            Error = $oinfo.Error.LocalizedMessage
            Task = $oinfo.Name
            TaskMoRef = $oinfo.TaskMoRef
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.SRM.Protect.Info')
        return $lo
    }
}
