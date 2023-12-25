[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [String]
    $Message = "Hello"
)

# For whatever reason it wasn't changed in the batch script
# We don't want to dirty up System32
if ((Get-Location).Path -eq "$env:WINDIR\System32")
{ Set-Location -Path $env:TEMP }

$ScriptCWD = (Get-Location).Path

Write-Output -InputObject "Script current working directory: $ScriptCWD"

Write-Output -InputObject $Message
$Message | Out-File -FilePath "$ScriptCWD\SamplePSScript.txt" -Encoding ascii

Write-Output -InputObject "Starting a loop 1 through 9..."
for ($i = 1; $i -lt 10; $i++) {
    Write-Output -InputObject $i.ToString()
    Start-Sleep -Milliseconds 150
}

PAUSE