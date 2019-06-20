class SRMhelp
{
    static [hashtable] ErrHash([string[]] $r)
    {
        $ht = @{
            Data = "a" ;
            Data2 = "b" ;
            Reason = $r
        }
        return $ht
    }

    static [PSCustomObject] MakeObj([string] $s)
    {
        $lo = [PSCustomObject]@{
            Name = "First"
            Idea = "Working"
            Input = $s
        }
        return $lo
    }

    static [array] ColInfo([psobject] $srv)
    {
        $info = $srv.ServiceType, $srv.StartType, $srv.ServiceName, $srv.Status
        return $info
    }
}