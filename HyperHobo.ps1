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

# Configuration; some of these could be overriden by $configFile
$dependenciesFolder = "dependencies"
$carbonVersion = "2.10.2"
$hostsFileComment = "Set by HyperHobo"

function Assert-Folder {
    param(
        [Parameter(Position = 0, Mandatory = 1)][string]
        $folder
    )
    $result = $true
    if (-not (Test-Path -Path $folder -PathType Container)) {
        New-Item -Path $folder -ItemType Directory | Out-Null
        $result = $false
    }
    return $result
}

function Assert-CarbonModule {
    # https://github.com/webmd-health-services/Carbon/releases/download/2.10.2/Carbon-2.10.2.zip
    Assert-Folder $dependenciesFolder | Out-Null
    $carbonFolder = Join-Path -Path $dependenciesFolder -ChildPath "Carbon-${carbonVersion}"
    if (-not (Assert-Folder $carbonFolder)) {
        $carbonFile = Join-Path -Path $dependenciesFolder -ChildPath "Carbon-${carbonVersion}.zip"
        $url = "https://github.com/webmd-health-services/Carbon/releases/download/${carbonVersion}/Carbon-${carbonVersion}.zip"
        Invoke-WebRequest -Uri $url -OutFile $carbonFile
        Expand-Archive -Path $carbonFile -DestinationPath $carbonFolder
        Remove-Item -Path $carbonFile
    }
    . ".\${carbonFolder}\Carbon\Import-Carbon.ps1"
}

function Set-HostsFilePair {
    param(
        [Parameter(Position = 0, Mandatory = 1)][string]
        $hostsFile,

        [Parameter(Position = 1, Mandatory = 1)][Net.IPAddress]
        $ipAddress,

        [Parameter(Position = 2, Mandatory = 1)][string[]]
        $hostNames
    )
    Assert-CarbonModule
    Write-Host "Setting ${hostNames} -> ${ipAddress}..."
    Set-CHostsEntry -IPAddress $ipAddress -HostName "${hostNames}" -Description $hostsFileComment -Path $hostsFile

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

    Update-HostsFile
}

function Update-HostsFile {
    Write-Host "Waiting for '${vmName}'..."
    # Inspired by https://johntaurins.wordpress.com/2014/08/22/hyper-v-start-vms-in-order-wait-for-vm-heartbeat/
    Do {
        Start-Sleep -milliseconds 100
    }
    Until ((Get-VMIntegrationService -VMName $vmName |`
                Where-Object { $_.name -eq "Heartbeat" }).PrimaryStatusDescription -eq "OK")

    if ($null -ne $hostName) {
        Write-Host "Waiting for an IPv4 address..."
        # TODO: there could be more than one network adapter, and there's both IPv4 & IPv6
        $addresses = (Get-VMNetworkAdapter -VMName $vmName).IPAddresses
        if ($addresses) {
            # if it looks like a single IPv6 address, keep looking
            while ($addresses[0].Contains(":")) {
                Start-Sleep -milliseconds 100
                $addresses = (Get-VMNetworkAdapter -VMName $vmName).IPAddresses
            }
            $ipv4Address = $addresses[0]
            Assert-CarbonModule
            $hostsFile = (Get-CPathToHostsFile)
            Set-HostsFilePair -hostsFile $hostsFile -ipAddress $ipv4Address -hostNames $hostName
        }
        else {
            Write-Host "WARNING: Unable to determine IP address(es)!"
            Write-Host "Running a non-Windows OS? You might need to install an 'Integration Service'."
            Write-Host "See https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/supported-linux-and-freebsd-virtual-machines-for-hyper-v-on-windows"
            Write-Host "Short version:"
            Write-Host " - Ubuntu: sudo apt-get install `"linux-cloud-tools-`$(uname -r)`""
            Write-Host " - CentOS: sudo yum install hyperv-daemons"
            Write-Host ""
            Write-Host "...once you've installed, reboot."
            Write-Host "Confirm you can see IP Addresses and create a new CheckPoint."
        }
    }
}

if ($null -eq $vmName) {
    $configFile = "HyperHoboConfig.ps1";
    if (-not (Test-Path -Path $configFile -PathType Leaf)) {
        throw "ERROR: Could not find ${configFile}!"
    }

    . ".\${configFile}"
}

switch ($verb) {
    "Apply" {
        Apply @remaining
    }
    "Assert-CarbonModule" {
        # Runs a test of the Carbon module download & import in isolation
        Assert-CarbonModule
        Write-Host (Get-CPathToHostsFile)
    }
    "Set-HostsFilePair" {
        # Runs some tests of the Set-HostsFilePair method
        Write-Host "---"
        Set-HostsFilePair -hostsFile "one.txt" "192.0.2.1" "one.example"
        Write-Host "---"
        # TODO: there's a defect in Set-CHostsEntry whereby a line with aliases will be duplicated on subsequent runs
        Set-HostsFilePair -hostsFile "one-to-many.txt" "192.0.2.1" ("one.example", "one-to-many.example")
        Write-Host "---"
    }
    "Update-HostsFile" {
        Update-HostsFile
    }
    # TODO: add more verbs
    default {
        throw "ERROR: The verb ${verb} is not recognized!"
    }
}
