class sClasss   # Trailing S
{
    static [hashtable] MakeHash( [string] $quoi )
    {
        $src = $null
        $shash = @{}

        switch ($quoi)
        {
            ds { $src = Get-Datastore -Name * }
            ex { $src = Get-VMHost -Name * }
            vm { $src = Get-VM -Name * }
        }

        foreach ($s in $src)
        {
            $shash.add($s.Id , $s.Name)
        }
        return $shash
    }

    static [hashtable] MakePgHash ([psobject] $pgroups )
    {
        $pghash = @{}
        foreach ($p in $pgroups)
        {
            $pghash.Add($p.ListProtectedDatastores().Moref,$p)
        }
        return $pghash
    }
}

$srmED = $DefaultSrmServers.ExtensionData
if(!$srmED)
{
    Write-Output "Terminating.  Session is not connected to a SRM server."
    break
}
$pgroups = $srmED.Protection.ListProtectionGroups()
measure-command {$pghash = [sClasss]::MakePgHash($pgroups)}   # Trailing S
Measure-command {$dshash = [sClasss]::MakeHash('ds') }    # Trailing S

$pghash
$dshash