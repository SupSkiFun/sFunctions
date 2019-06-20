using module .\SRMhelp.psm1

$a = [SRMhelp]::ColInfo((get-service winrm))
$a