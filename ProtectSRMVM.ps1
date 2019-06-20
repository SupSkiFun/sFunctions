Function Protect-SRMVM {}


$srmED = $DefaultSrmServers.ExtensionData
$abc = $srmED.Protection.ListProtectionGroups()
$fff = @{}
foreach ($a in $abc) {$fff.Add($a.ListProtectedDatastores().Moref,$a)}
foreach ($v in $vm)
{
    $cle = $v.ExtensionData.DataStore
    $vmo = $v.ExtensionData.Moref
    if ($fff.ContainsKey($($cle)))
    {
        $ggg = $fff.Item($($cle))
        $hhh = $ggg.QueryVmProtection($vmo)
        if ($hhh.Status -match "CanBeProtected")
        {
            $y = [VMware.VimAutomation.Srm.Views.SrmProtectionGroupVmProtectionSpec]::new()
            $y.Vm = $vmo
            $ggg.ProtectVms($y)
        }
