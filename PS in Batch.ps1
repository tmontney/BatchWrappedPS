function ConvertTo-PSBatchScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $PSScriptContents,
        [Parameter(Mandatory = $false)]
        [String[]]
        $Arguments = @(),
        # Consider using delayed expansion on variables
        # If you explicitly specify $env:TEMP and run this as another user, it will map to the wrong user's temp folder
        [Parameter(Mandatory = $false)]
        [String]
        $CurrentWorkingDirectory = "%TEMP%"
    )
    
    try 
    { [void]([ScriptBlock]::Create($PSScriptContents)) }
    catch 
    { Write-Warning -Message "There was a problem parsing 'PSScriptContents' as a PowerShell script."; Write-Error $_; return }

    if ($Arguments.Count -gt 0) {
        $ArgumentsAL = [System.Collections.ArrayList]::new()
        $ArgumentsAL.AddRange($Arguments)

        $cliXml = [System.Management.Automation.PSSerializer]::Serialize($ArgumentsAL)
        $ArgsBase64 = "-EncodedArguments " + ([Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($cliXml)))
    }

    $BatchBase64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($PSScriptContents))
    $InvokePSLine = "%WINDIR%\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -EncodedCommand $BatchBase64 $ArgsBase64"

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
ConvertTo-PSBatchScript -PSScriptContents $PSScriptContents -Arguments @("Hello world!") | Set-Content -LiteralPath "$Script:ScriptCWD\Sample PS Script.bat" -Force