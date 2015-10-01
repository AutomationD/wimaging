# Provision Windows hosts with [Foreman](http://theforeman.org/)

[![Join the chat at https://gitter.im/helge000/wimaging-ng](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/helge000/wimaging-ng?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

## Introduction
`wimaging-ng` a set of scripts to prepare [WIM images](https://en.wikipedia.org/wiki/Windows_Imaging_Format) and templates for Foreman to provision Windows hosts.
Except for the boot process official Microsoft deployment tools are used; most notably `dism.exe`.

All relevant configuration files like `unattend.xml` are rendered by Foreman and downloaded at build time.

### Features
- __Linux style installation__ using `http://` or `ftp://` installation media
- __No extra servers__ like WDS needed - all relevant settings can be configured in Foreman directly
- __Official Mircosoft utilities__ are used for all relevant setup stages making it easy to add (future) operating systems
- __Driver installation__ during build time
- Support for __localization__ settings (like time zone, locale, UI language)
- Optional __domain join__ including target OU
- Optional __local user creation__
- Support for Foreman's __root password__ using Base64 encoding
- Optional software installation and user tasks at the end of the build (like __installing puppet__ ect)

## Prerequisites
Requirements for using wimaging-ng, they are __not__ covered in this guide.

- A working Foreman __version 1.8+__ installation (obviously), capable of net booting clients along with a working DNS / DHCP infrastructure
- Currently, [Safe Mode Render](http://theforeman.org/manuals/1.9/index.html#3.5.2ConfigurationOptions) must be disabled in foreman
- A utility Windows VM or physical host to prepare the WIM images (Microsoft likes the term [Technician Computer](https://technet.microsoft.com/en-us/library/cc766148(v=ws.10).aspx))
- A file server serving http and/or ftp protocols; fast machine recommended for production
- Installation media for each Windows version
- Driver files (`.inf`) you want to inject
- A VM / bare metal machine to test your setup (start with VMs ;)

## Getting started with wimaging
The tasks can be broken down in two steps:

#### 1. [Configure wimaging and create WIM images](doc/wimaging.md)
#### 2. [Configuring Foreman](doc/foreman.md)
---
#### A. [Script Reference](doc/reference.md)

## Provision work flow
An outline of the process to better understand the tasks witch need to be done. Basically, there are three phases:

### Phase I
1. Create a new host in Foreman.

Simple as that. For Bare Metal hosts [Foreman discovery](https://github.com/theforeman/foreman_discovery) is recommended.

### Phase II
1. PXE / [wimboot](http://ipxe.org/wimboot) boots customized boot.wim (winpe)
2. Winpe downloads the script `foreman_url('script')`; executes it:
  1. Drive 0 is cleaned, partitioned and mounted using foreman partition table (simple `diskpart` script)
  4. `install.wim` is downloaded via http/ftp and applied using `dism.exe`
  5. `unattend.xml` (`foreman_url('provision')`) is download and applied using `dism.exe`
  6. Drivers are download and added using `dism.exe`
  6. Required tools are added to the new host (most prominently `wget`)
  6. Optionally, download extra software (like puppet)
  6. Optionally, domain join script (`foreman_url('user_data')`)
  7. The finish script (`foreman_url('finish')`) is download and 'armed'
8. reboot to new OS

### Phase III
1. Windows native finish tasks are done ('starting devices...')
1. The finish script gets called by [`SetupComplete.cmd`](https://technet.microsoft.com/en-us/library/cc766314%28v=ws.10%29.aspx)
  1. Set the time server; sync time
  2. Optionally, the local administrator account is activated
  2. Optionally, join domain
  3. Optionally, execute extra scripts (eg, install puppet)
  3. Securely cleanup (sensitive) scripts using [`SDelete.exe`](https://technet.microsoft.com/en-us/sysinternals/bb897443.aspx)
2. Reboot the host; ready for further configuration by Puppet, SCCM ect.

## Acknowledgments
`wimaging-ng` is a fork of [wimaging](https://github.com/kireevco/wimaging). Many thanks to [Dmitry Kireev](https://github.com/kireevco), the original author.
SDelete and other PStools by SysInternals are the work of [Mark Russinovich](http://blogs.technet.com/b/markrussinovich/about.aspx).

## License
[wimaging-ng license](licenses/wimaging-ng.license)

Other licenses:

- [Original wimaging Dmitry Kireev](licenses/wimaging.license)
- [SysInternals](licenses/sysinternals.license)
- [Gnu General Public License v3 for GNU wget and other utilities](licenses/gpl-v3.license)
