function ConvertTo-BatchWrapped([String]$PSScriptPath, [Hashtable]$Arguments) {
    $PSScriptContents = Get-Content -Path $PSScriptPath -Raw -ErrorAction Stop
    $BatchBase64 = ConvertTo-MultilineBatchBase64 -VarName "TargetScript" -VarText $PSScriptContents

    $TempBase64OutputLine = @()
    for ($i = 1; $i -le $BatchBase64.VarCount; $i++) {
        $TempBase64OutputLine += "echo !TargetScript$i! > %TempBase64Output%"
    }

    $InvokePSLine = "%WINDIR%\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File ""%TempTargetScript%"""
    if ($Arguments) {
        $Arguments.Keys | ForEach-Object {
            if ($Arguments[$_] -is [String]) {
                $InvokePSLine += " -$_ ""$($Arguments[$_])"""
            }
            else {
                $InvokePSLine += " -$_ $($Arguments[$_])"
            }
        }
    }

    $BatchContents = @"
@echo off
setlocal EnableDelayedExpansion
set LF=^


REM !!! Do not remove the two lines above this; required to make a newline variable !!!

REM To generate the following, use certutil -decode or ConvertTo-MultilineBatchBase64 in PowerShell.Common.psm1
REM At this time, it isn't possible to decode with certutil using Base64 encoded by [System.Convert]::ToBase64String
REM certutil appears to keep lines to ~64 characters; recommended maximium line length is 127

REM Set the Base64 of the target script
$($BatchBase64.Var)

REM Set the temporary file paths
set "TempBase64Output=%temp%\TargetScript.%random%.txt"
set "TempTargetScript=%temp%\TargetScript.%random%.ps1"

REM Decode the TargetScript variable
$($TempBase64OutputLine -join "`n")
certutil -decode %TempBase64Output% %TempTargetScript% > NUL

REM Execute TargetScript
$InvokePSLine

REM Clean up temporary files
del %TempBase64Output%
del %TempTargetScript%
"@

    Set-Content -Path "$Script:ScriptCWD\$(([System.IO.Path]::GetFileNameWithoutExtension($PSScriptPath))).bat" -Value $BatchContents -Force
}

function ConvertTo-MultilineBatchBase64([String]$VarName, [String]$VarText) {
    #$VarBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Text))

    $VarTextTempFile = New-TemporaryFile
    $VarBase64TempFile = New-TemporaryFile
    Set-Content -Path $VarTextTempFile -Value $VarText
    [void](certutil.exe -f -encode $VarTextTempFile $VarBase64TempFile)

    $Var = @()
    $VarCount = 1
    $VarBase64 = Get-Content -Path $VarBase64TempFile | Select-Object -Skip 1 | Select-Object -SkipLast 1

    Remove-Item -Path $VarTextTempFile -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $VarBase64TempFile -Force -ErrorAction SilentlyContinue

    if ($VarBase64) {
        $Var = @("set $VarName$VarCount=$($VarBase64[0])!LF!")
        if ($VarBase64.Length -gt 1) {
            for ($i = 1; $i -lt $VarBase64.Length; $i++) {
                if ($i % 100 -eq 0) {
                    $VarCount += 1
                    $Var += "set $VarName$VarCount=$($VarBase64[$i])!LF!"
                }
                else {
                    $Var += "set $VarName$VarCount=!$VarName$VarCount!$($VarBase64[$i])!LF!"
                }
            }
        }
    }

    return [PSCustomObject]@{
        VarCount = $VarCount
        Var      = ($Var -join "`n")
    }
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

ConvertTo-BatchWrapped -PSScriptPath "$Script:ScriptCWD\Sample PS Script.ps1" -Arguments @{"Message" = "Hello world!" }