[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]
    $Message
)

if ($MyInvocation.MyCommand.Path) {
    $ScriptCWD = (Get-Item -Path $MyInvocation.MyCommand.Path).Directory.FullName
}
elseif ($PSScriptRoot) {
    $ScriptCWD = $PSScriptRoot
}
else {
    throw "Cannot determine script's working directory"
}

Write-Output -InputObject "Script current working directory: $ScriptCWD"

Write-Output -InputObject $Message
$Message | Out-File -FilePath "$ScriptCWD\SamplePSScript.txt" -Encoding ascii

Write-Output -InputObject "Starting a loop 1 through 9..."
for ($i = 1; $i -lt 10; $i++) {
    Write-Output -InputObject $i.ToString()
    Start-Sleep -Milliseconds 150
}

PAUSE