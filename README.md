# HyperHobo

HyperHobo is a bit of automation around Windows Hyper-V

## Requirements

1. Windows 10 Pro or Enterprise. This might also work on Windows Server 2019 and up.
1. The "Hyper-V" feature enabled (HyperHobo was only tested with all of the sub-features enabled), which can can be done via the following, with more details available at [Install Hyper-V on Windows 10](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v):
    1. Open an elevated PowerShell prompt
    1. Run `Enable-WindowsOptionalFeature -FeatureName "Microsoft-Hyper-V-All" -All -Online`
    1. Reboot
1. A virtual machine with at least one checkpoint.

## Try it

Assuming you've cloned this repository and that `hh.bat` is available in your `PATH` (or you prefix a path before any `hh.bat`):

1. Create a file called `HyperHoboConfig.ps1` in the current folder, adding the following variables and values for them:
    | Variable Name | Description                                |
    | ------------- | ------------------------------------------ |
    | `$vmName`     | The name of the virtual machine in Hyper-V |
1. Run `hh.bat apply "<checkpoint name>"`

## Example

I imported the "MSEdge on Win10 (x64) Stable 1809" from [Virtual Machines - Microsoft Edge Developer](https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/) into Hyper-V and the VM was named `MSEdge - Win10`.  I created a checkpoint (called `Imported`) before booting the first time and then created another checkpoint (called `example`) after playing around for a bit.

My `HyperHoboConfig.ps1` file looks like this:

```powershell
$vmName = "MSEdge - Win10";
```

I can then run `hh.bat apply "example"` from that directory and the output will be something like:

```txt
Turning off 'MSEdge - Win10'...
Restoring 'MSEdge - Win10' to 'example'...
Turning on 'MSEdge - Win10'...
Waiting for 'MSEdge - Win10'...
172.28.34.89 fe80::2d59:5e17:270b:e8d9
```
