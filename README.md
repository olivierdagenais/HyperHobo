# HyperHobo

HyperHobo is a bit of automation around Windows Hyper-V

## Requirements

1. Windows 10 Pro or Enterprise. This might also work on Windows Server 2019 and up.
1. The "Hyper-V" feature enabled (HyperHobo was only tested with all of the sub-features enabled), which can can be done via the following, with more details available at [Install Hyper-V on Windows 10](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v):
    1. Open an elevated PowerShell prompt
    1. Run `Enable-WindowsOptionalFeature -FeatureName "Microsoft-Hyper-V-All" -All -Online`
    1. Reboot
1. A virtual machine with at least one checkpoint.
