<#
.SYNOPSIS
    "A hobo is a migrant worker or homeless vagrant, especially one who is impoverished."
    HyperHobo is a bit of automation around Windows Hyper-V.

.EXAMPLE
    hh.bat apply "example"
#>
param(
    [Parameter(Position = 0, Mandatory = 1)][string]
    $verb,
    # Collect remaining arguments as per https://stackoverflow.com/a/7418440/98903
    [Parameter(Position = 1, Mandatory = 0, ValueFromRemainingArguments = $true)]
    $remaining
)


# Thank you, aggieNick02 for https://stackoverflow.com/a/44810914/98903
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'
function ThrowOnNativeFailure {
    if (-not $?) {
        throw 'Native Failure'
    }
}

function Apply {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = 1)][string]$checkpointName
    )
    
    # See if the requested VM & checkpoint exist before going further...
    Get-VMSnapshot -VMName $vmName -Name $checkpointName | Out-Null

    Write-Host "Turning off '${vmName}'..."
    Stop-VM -Name $vmName -TurnOff

    Write-Host "Restoring '${vmName}' to '${checkpointName}'..."
    Restore-VMCheckpoint -VMName $vmName -Name $checkpointName -Confirm:$false

    Write-Host "Turning on '${vmName}'..."
    Start-VM -Name $vmName

    Write-Host "Waiting for '${vmName}'..."
    # Inspired by https://johntaurins.wordpress.com/2014/08/22/hyper-v-start-vms-in-order-wait-for-vm-heartbeat/
    Do {
        Start-Sleep -milliseconds 100
    }
    Until ((Get-VMIntegrationService -VMName $vmName |`
                Where-Object { $_.name -eq "Heartbeat" }).PrimaryStatusDescription -eq "OK")

    # TODO: there could be more than one network adapter
    $addresses = (Get-VMNetworkAdapter -VMName $vmName).IPAddresses
    Write-Host $addresses
}

$configFile = "HyperHoboConfig.ps1";
if (-not (Test-Path -Path $configFile -PathType Leaf)) {
    throw "ERROR: Could not find ${configFile}!"
}

. ".\${configFile}"

switch ($verb) {
    "Apply" {
        Apply @remaining
    }
    # TODO: add more verbs
    default {
        throw "ERROR: The verb ${verb} is not recognized!"
    }
}
