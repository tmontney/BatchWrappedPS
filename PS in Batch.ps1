function ConvertTo-PSBatchScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ScriptBlock]
        $Action,
        [Parameter(Mandatory = $false)]
        [String[]]
        $ArgumentList = @(),
        # Consider using delayed expansion on variables
        # If you explicitly specify $env:TEMP and run this as another user, it will map to the wrong user's temp folder
        [Parameter(Mandatory = $false)]
        [String]
        $CurrentWorkingDirectory = "%TEMP%", # Ignored if 'AsSingleLine' specified
        [Parameter(Mandatory = $false)]
        [Switch]
        $UsePowerShell7,
        [Parameter(Mandatory = $false)]
        [ValidateSet("AllSigned", "Bypass", "Default", "RemoteSigned", "Restricted", "Undefined", "Unrestricted")]
        [String]
        $ExecutionPolicy = "Default",
        [Parameter(Mandatory = $false)]
        [ValidateSet("Normal", "Minimized", "Maximized", "Hidden")]
        [String]
        $WindowStyle = "Normal",
        [Parameter(Mandatory = $false)]
        [Switch]
        $ScheduledTask # Returns as an array instead: {powershell path} {powershell arguments} {base64 scriptblock} {base64 scriptblock arguments}
    )

    # If PowerShell goes to 8, this will probably break.
    $FilePath = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
    if ($UsePowerShell7)
    { $FilePath = "$env:PROGRAMFILES\PowerShell\7\pwsh.exe" }

    if (-not (Test-Path -Path $FilePath))
    { Write-Warning -Message "'$FilePath' does not exist"; return }

    if ($ArgumentList.Count -gt 0) {
        $ArgumentsAL = [System.Collections.ArrayList]::new()
        $ArgumentsAL.AddRange($ArgumentList)

        $cliXml = [System.Management.Automation.PSSerializer]::Serialize($ArgumentsAL)
        $ArgsBase64 = "-EncodedArguments " + ([Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($cliXml)))
    }

    $BatchBase64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Action.ToString()))
    $InvokePSLine = "$FilePath -ExecutionPolicy Bypass -EncodedCommand $BatchBase64 $ArgsBase64"

    if ($InvokePSLine.Length -gt 32767)
    { Write-Warning -Message "The generated command is greater than 32,767 characters; cmd.exe will fail to run this." }

    if ($ScheduledTask)
    { return @($FilePath, "-ExecutionPolicy $ExecutionPolicy -WindowStyle $WindowStyle", "-EncodedCommand $BatchBase64", $ArgsBase64) }

    return @"
@echo off

REM Set current working directory to a temporary folder
cd $CurrentWorkingDirectory

REM Execute PowerShell script
$InvokePSLine
"@
}

####################

if ($MyInvocation.MyCommand.Path) {
    $Script:ScriptCWD = (Get-Item -Path $MyInvocation.MyCommand.Path).Directory.FullName
}
elseif ($PSScriptRoot) {
    $Script:ScriptCWD = $PSScriptRoot
}
else {
    throw "Cannot determine script's working directory"
}

$PSScriptContents = Get-Content -Path "$Script:ScriptCWD\Sample PS Script.ps1" -Raw
ConvertTo-PSBatchScript -Action ([ScriptBlock]::Create($PSScriptContents)) -ArgumentList @("Hello world!") -ExecutionPolicy Bypass | Set-Content -LiteralPath "$Script:ScriptCWD\Sample PS Script.bat" -Force