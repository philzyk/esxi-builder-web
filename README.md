# esxi-iso-builder based on originasl vmware-powercli

VMware's PowerCLI with PowerShell Core and Python for ImageBuilder Support in Linux. For those who need to mount, edit and re-package ISO images from ImageBuilder, this container also has the appropriate system tools to do so. Published for 64-bit `x86` and `ARM` architectures.

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/jmcombs/vmware-powercli/docker-publish.yml?logo=github)
[![Docker Pulls](https://img.shields.io/docker/pulls/jmcombs/vmware-powercli)](https://hub.docker.com/r/jmcombs/vmware-powercli "Click to view the image on Docker Hub")
[![Docker Stars](https://img.shields.io/docker/stars/jmcombs/vmware-powercli)](https://hub.docker.com/r/jmcombs/vmware-powercli "Click to view the image on Docker Hub")
[![Github Issues](https://img.shields.io/github/issues/jmcombs/vmware-powercli)](https://github.com/jmcombs/vmware-powercli/issues "Click to view or open issues")

## About

This container is based on Ubuntu 20.04, contains both `xorriso` and `mkisofs` packages (for repacking ISO images) and has the following software installed, per the [Compatibility Matrixes for VMware PowerCLI 13.1.0](https://vdc-repo.vmware.com/vmwb-repository/dcr-public/f479301e-3164-47bc-9584-89b84a1bf5ce/c4ea2d2f-bf6d-4c18-bb20-6c4782ac6576/powercli1310-compat-matrix.html) and [Compatibility Matrixes for VMware PowerCLI 13.0.0](https://developer.vmware.com/docs/17472//powercli1300-compat-matrix.html#install-prereq):

- .NET Core 3.1 (which is now [End of Support](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core))
- PowerShell Core 7.2 LTS (Automated)
- Python 3.7 (via ["deadsnakes" team](https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa))
- VMware PowerCLI 13.1.0 (for `x64`) or 13.0.0 (for `ARM64`)

**NOTE**:

- Python is configured per requirements outlined in [Install and Configure Python on Linux](https://developer.vmware.com/docs/15315/powercli-user-s-guide/GUID-101A5D2A-6BEB-43B0-8328-3B2F9F80C628.html)
- For `ARM64` (aka Apple Silicone) users, there is a bug in PowerCLI 13.1.0 with ImageBuilder and it will not run so, `ARM64` images contain PowerCLI 13.0.0. VMware states its due to one of their modules not being compiled for ARM and have provided no ETA on when they'll fix it. Until then, I am keeping PowerCLI 13.0.0 for ARM64 images.

## How to Use

### **Requirements**

- Container's non-root user is `coder`
- Container defaults to using user `coder` when ran
- If leveraging Image Builder and/or `mkisofs`, it is assumed and recommended that a volume will be mapped to `/home/coder/files` for sharing files between Host and Container

### **Running Container**

For most use cases where the intent is to only use PowerCLI (without Image Builder):

```shell
docker run -it jmcombs/vmware-powercli
```

If the intent is to use PowerCLI with Image Builder and use `xorriso` to repackage modified Images, a volume will need to be mapped:

```shell
docker run -it --volume=/your/local/filesystem/files:/home/coder/files jmcombs/vmware-powercli
```

If the intent is to use PowerCLI with Image Builder and use `mkisofs` to repackage modified Images, a volume will need to be mapped `mkisofs` requires the container to be ran in Privileged Mode

```shell
docker run -it --privileged --volume=/your/local/filesystem/files:/home/coder/files jmcombs/vmware-powercli
```

## Examples

### Create ESXi Image with Image Builder

The following are instructions for

- Adding VIBs to Image Builder
- Cloning an ESXi Image Profile (Offline Bundle)
- Adding VIBs to Cloned Image
- Exporting to ISO

#### **NOTE:** The example below:

- Has the following VIBs:
  - [Community Networking Driver for ESXi](https://flings.vmware.com/community-networking-driver-for-esxi)
  - [Synology NFS Plug-in for VMware VAAI](https://kb.synology.com/en-us/DSM/tutorial/How_do_I_install_Synology_NFS_VAAI_Plug_in_on_an_ESXi_host)
- Is using the `VMware-ESXi-7.0U3g-20328353-depot.zip` ESXi Offline Bundle
- Cloned Image Profile is named `ESXi-7.0U3g-nuc12-syn`
- Exported ISO file is named `VMware-VMvisor-Installer-7.0U3g-20328353.x86_64.nuc12-syn.iso`
- Location of files is in `/home/coder/files`

#### **Assumptions:**

- It is assumed the user has access to download software from VMware

#### **Instructions**

1. Add VIBs

```powershell
PS /home/coder/files> Get-EsxSoftwarePackage -PackageUrl /home/coder/files/Synology_bootbank_synology-nfs-vaai-plugin_2.0-1109.vib

Name                     Version                        Vendor     Creation Date
----                     -------                        ------     -------------
synology-nfs-vaai-plugin 2.0-1109                       Synology   10/25/2021 2:34…

PS /home/coder/files> Get-EsxSoftwarePackage -PackageUrl /home/coder/files/VMW_bootbank_net-community_1.2.7.0-1vmw.700.1.0.15843807.vib

Name                     Version                        Vendor     Creation Date
----                     -------                        ------     -------------
net-community            1.2.7.0-1vmw.700.1.0.15843807  VMW        3/10/2022 9:21:…
```

2. Confirm VIBs were added

```powershell
PS /home/coder/files> Get-EsxSoftwarePackage

Name                     Version                        Vendor     Creation Date
----                     -------                        ------     -------------
net-community            1.2.7.0-1vmw.700.1.0.15843807  VMW        3/10/2022 9:21:…
synology-nfs-vaai-plugin 2.0-1109                       Synology   10/25/2021 2:34…
```

3. Add ESXi Offline Bundle

```powershell
PS /home/coder/files> Add-EsxSoftwareDepot -DepotUrl /home/coder/files/VMware-ESXi-7.0U3g-20328353-depot.zip

Depot Url
---------
zip:/home/coder/files/VMware-ESXi-7.0U3g-20328353-depot.zip?index.xml
```

4. Confirm Offline Bundle was added

```powershell
PS /home/coder/files> Get-EsxImageProfile

Name                           Vendor          Last Modified   Acceptance Level
----                           ------          -------------   ----------------
ESXi-7.0U3g-20328353-no-tools  VMware, Inc.    8/23/2022 3:00… PartnerSupported
ESXi-7.0U3g-20328353-standard  VMware, Inc.    9/1/2022 12:00… PartnerSupported
```

5. (Optional) List all Software Packages to confirm all packages from Offline Bundle and previously added VIBs are listed

```powershell
PS /home/coder/files> Get-EsxSoftwarePackage

Name                     Version                        Vendor     Creation Date
----                     -------                        ------     -------------
net-community            1.2.7.0-1vmw.700.1.0.15843807  VMW        3/10/2022 9:21:…
synology-nfs-vaai-plugin 2.0-1109                       Synology   10/25/2021 2:34…
< Text omitted for brevity. Should match output in Step 10 >
```

6. Clone ESXi Image Profile (from Step 4)

```powershell
PS /home/coder/files> New-EsxImageProfile -Vendor "VMware, Inc." -CloneProfile ESXi-7.0U3g-20328353-standard -Name ESXi-7.0U3g-nuc12-syn -AcceptanceLevel PartnerSupported

Name                           Vendor          Last Modified   Acceptance Level
----                           ------          -------------   ----------------
ESXi-7.0U3g-nuc12-syn          VMware, Inc.    9/1/2022 12:00… PartnerSupported
```

7. Add VIBs to new ESXi Image Profile

```powershell
PS /home/coder/files> Add-EsxSoftwarePackage -ImageProfile ESXi-7.0U3g-nuc12-syn -SoftwarePackage synology-nfs-vaai-plugin -Confirm

Name                           Vendor          Last Modified   Acceptance Level
----                           ------          -------------   ----------------
ESXi-7.0U3g-nuc12-syn          VMware, Inc.    12/13/2022 9:2… PartnerSupported

PS /home/coder/files> Add-EsxSoftwarePackage -ImageProfile ESXi-7.0U3g-nuc12-syn -SoftwarePackage net-community -Confirm

Name                           Vendor          Last Modified   Acceptance Level
----                           ------          -------------   ----------------
ESXi-7.0U3g-nuc12-syn          VMware, Inc.    12/13/2022 9:2… PartnerSupported
```

8. Confirm all VIBs are in Cloned ESXi Image Profile

```powershell
PS /home/coder/files> (Get-EsxImageProfile -Name ESXi-7.0U3g-nuc12-syn).VibList

Name                     Version                        Vendor     Creation Date
----                     -------                        ------     -------------
net-community            1.2.7.0-1vmw.700.1.0.15843807  VMW        3/10/2022 9:21:…
mtip32xx-native          3.9.8-1vmw.703.0.20.19193900   VMW        1/11/2022 11:21…
iser                     1.1.0.1-1vmw.703.0.50.20036589 VMW        6/30/2022 2:35:…
cpu-microcode            7.0.3-0.55.20328353            VMware     8/23/2022 2:02:…
esx-base                 7.0.3-0.55.20328353            VMware     8/23/2022 2:02:…
elx-esx-libelxima.so     12.0.1200.0-4vmw.703.0.20.191… VMware     1/11/2022 11:22…
nmlx4-en                 3.19.16.8-2vmw.703.0.20.19193… VMW        1/11/2022 11:21…
qfle3i                   1.0.15.0-15vmw.703.0.20.19193… VMW        1/11/2022 11:21…
lsi-mr3                  7.718.02.00-1vmw.703.0.20.191… VMW        1/11/2022 11:21…
pvscsi                   0.1-4vmw.703.0.20.19193900     VMW        1/11/2022 11:21…
qflge                    1.1.0.11-1vmw.703.0.20.191939… VMW        1/11/2022 11:21…
lsuv2-oem-lenovo-plugin  1.0.0-1vmw.703.0.20.19193900   VMware     1/11/2022 11:22…
esx-update               7.0.3-0.55.20328353            VMware     8/23/2022 2:02:…
nmlx5-core               4.19.16.11-1vmw.703.0.20.1919… VMW        1/11/2022 11:21…
vdfs                     7.0.3-0.55.20328353            VMware     8/23/2022 2:03:…
vsanhealth               7.0.3-0.55.20328353            VMware     8/23/2022 2:03:…
nhpsa                    70.0051.0.100-4vmw.703.0.20.1… VMW        1/11/2022 11:21…
crx                      7.0.3-0.55.20328353            VMware     8/23/2022 2:03:…
lsi-msgpt35              19.00.02.00-1vmw.703.0.20.191… VMW        1/11/2022 11:21…
esxio-combiner           7.0.3-0.55.20328353            VMware     8/23/2022 2:03:…
vmware-esx-esxcli-nvme-… 1.2.0.44-1vmw.703.0.20.191939… VMware     1/11/2022 11:22…
bnxtnet                  216.0.50.0-44vmw.703.0.50.200… VMW        6/30/2022 2:35:…
esx-dvfilter-generic-fa… 7.0.3-0.55.20328353            VMware     8/23/2022 2:02:…
esx-xserver              7.0.3-0.55.20328353            VMware     8/23/2022 2:02:…
nmlx4-rdma               3.19.16.8-2vmw.703.0.20.19193… VMW        1/11/2022 11:21…
synology-nfs-vaai-plugin 2.0-1109                       Synology   10/25/2021 2:34…
nvmxnet3                 2.0.0.30-1vmw.703.0.20.191939… VMW        1/11/2022 11:21…
irdman                   1.3.1.22-1vmw.703.0.50.200365… VMW        6/30/2022 2:35:…
lsuv2-intelv2-nvme-vmd-… 2.7.2173-1vmw.703.0.20.191939… VMware     1/11/2022 11:22…
nmlx4-core               3.19.16.8-2vmw.703.0.20.19193… VMW        1/11/2022 11:21…
iavmd                    2.7.0.1157-2vmw.703.0.20.1919… VMW        1/11/2022 11:21…
rste                     2.0.2.0088-7vmw.703.0.20.1919… VMW        1/11/2022 11:21…
lsuv2-nvme-pcie-plugin   1.0.0-1vmw.703.0.20.19193900   VMware     1/11/2022 11:22…
elxnet                   12.0.1250.0-5vmw.703.0.20.191… VMW        1/11/2022 11:21…
trx                      7.0.3-0.55.20328353            VMware     8/23/2022 2:03:…
nvmerdma                 1.0.3.5-1vmw.703.0.20.19193900 VMW        1/11/2022 11:21…
nvmetcp                  1.0.0.1-1vmw.703.0.35.19482537 VMW        3/11/2022 2:12:…
vsan                     7.0.3-0.55.20328353            VMware     8/23/2022 2:03:…
bmcal                    7.0.3-0.55.20328353            VMware     8/23/2022 2:03:…
lsuv2-lsiv2-drivers-plu… 1.0.0-12vmw.703.0.50.20036589  VMware     6/30/2022 2:36:…
gc                       7.0.3-0.55.20328353            VMware     8/23/2022 2:02:…
qcnic                    1.0.15.0-14vmw.703.0.20.19193… VMW        1/11/2022 11:21…
elxiscsi                 12.0.1200.0-9vmw.703.0.20.191… VMW        1/11/2022 11:21…
igbn                     1.4.11.2-1vmw.703.0.20.191939… VMW        1/11/2022 11:21…
sfvmk                    2.4.0.2010-6vmw.703.0.20.1919… VMW        1/11/2022 11:21…
bnxtroce                 216.0.58.0-23vmw.703.0.50.200… VMW        6/30/2022 2:35:…
nvme-pcie                1.2.3.16-1vmw.703.0.20.191939… VMW        1/11/2022 11:21…
vmkfcoe                  1.0.0.2-1vmw.703.0.20.19193900 VMW        1/11/2022 11:21…
ixgben                   1.7.1.35-1vmw.703.0.20.191939… VMW        1/11/2022 11:21…
ionic-en                 16.0.0-16vmw.703.0.20.19193900 VMW        1/11/2022 11:21…
lpfc                     14.0.169.26-5vmw.703.0.50.200… VMW        6/30/2022 2:35:…
icen                     1.4.1.20-1vmw.703.0.50.200365… VMW        6/30/2022 2:35:…
lsi-msgpt3               17.00.12.00-1vmw.703.0.20.191… VMW        1/11/2022 11:21…
atlantic                 1.0.3.0-8vmw.703.0.20.19193900 VMW        1/11/2022 11:21…
lsuv2-smartpqiv2-plugin  1.0.0-8vmw.703.0.20.19193900   VMware     1/11/2022 11:22…
nvmxnet3-ens             2.0.0.22-1vmw.703.0.20.191939… VMW        1/11/2022 11:21…
qfle3f                   1.0.51.0-22vmw.703.0.20.19193… VMW        1/11/2022 11:21…
ntg3                     4.1.7.0-0vmw.703.0.20.19193900 VMW        1/11/2022 11:21…
ne1000                   0.9.0-1vmw.703.0.50.20036589   VMW        6/30/2022 2:35:…
vmw-ahci                 2.0.11-1vmw.703.0.20.19193900  VMW        1/11/2022 11:21…
brcmfcoe                 12.0.1500.2-3vmw.703.0.20.191… VMW        1/11/2022 11:21…
qlnativefc               4.1.14.0-26vmw.703.0.20.19193… VMware     1/11/2022 11:21…
loadesx                  7.0.3-0.55.20328353            VMware     8/23/2022 2:02:…
qedentv                  3.40.5.53-22vmw.703.0.20.1919… VMW        1/11/2022 11:21…
qfle3                    1.0.67.0-22vmw.703.0.20.19193… VMW        1/11/2022 11:21…
lsuv2-oem-dell-plugin    1.0.0-1vmw.703.0.20.19193900   VMware     1/11/2022 11:22…
smartpqi                 70.4149.0.5000-1vmw.703.0.20.… VMW        1/11/2022 11:21…
native-misc-drivers      7.0.3-0.55.20328353            VMware     8/23/2022 2:02:…
vmkusb                   0.1-7vmw.703.0.50.20036589     VMW        6/30/2022 2:35:…
lpnic                    11.4.62.0-1vmw.703.0.20.19193… VMW        1/11/2022 11:21…
vmkata                   0.1-1vmw.703.0.20.19193900     VMW        1/11/2022 11:21…
qedrntv                  3.40.5.53-18vmw.703.0.20.1919… VMW        1/11/2022 11:21…
nfnic                    4.0.0.70-1vmw.703.0.20.191939… VMW        1/11/2022 11:21…
i40en                    1.11.1.31-1vmw.703.0.20.19193… VMW        1/11/2022 11:21…
lsi-msgpt2               20.00.06.00-4vmw.703.0.20.191… VMW        1/11/2022 11:21…
tools-light              12.0.0.19345655-20036586       VMware     6/30/2022 1:04:…
esx-ui                   1.43.8-19798623                VMware     5/13/2022 11:32…
nenic                    1.0.33.0-1vmw.703.0.20.191939… VMW        1/11/2022 11:21…
lsuv2-hpv2-hpsa-plugin   1.0.0-3vmw.703.0.20.19193900   VMware     1/11/2022 11:22…
lsuv2-oem-hp-plugin      1.0.0-1vmw.703.0.20.19193900   VMware     1/11/2022 11:22…
nmlx5-rdma               4.19.16.11-1vmw.703.0.20.1919… VMW        1/11/2022 11:21…
```

9. Export Cloned ESXi Image Profile to ISO

```powershell
PS /home/coder/files> Export-EsxImageProfile -ImageProfile ESXi-7.0U3g-nuc12-syn -ExportToIso -FilePath /home/coder/files/VMware-VMvisor-Installer-7.0U3g-20328353.x86_64.nuc12-syn.iso -NoSignatureCheck
```

10. Happy ESXi Installing!

### Modify & Repackage ESXi ISO with `xorriso`

The following are instructions for

- This is the recommended approach
- Mounting an ESXi ISO image
- Copying ESXi ISO image to a temporary location (for modification) & Repackaging using `xorriso`

#### **NOTE:** The example below:

- Is using an ESXi `7.0U3g` ISO image created with Image Builder which includes [Community Networking Driver for ESXi](https://flings.vmware.com/community-networking-driver-for-esxi) and [Synology NFS Plug-in for VMware VAAI](https://kb.synology.com/en-us/DSM/tutorial/How_do_I_install_Synology_NFS_VAAI_Plug_in_on_an_ESXi_host) VIBs
- Image Builder ISO file is named `VMware-VMvisor-Installer-7.0U3g-20328353.x86_64.nuc12-syn.iso`
- Repackaged ISO file is named `custom_esxi.iso`
- Location of files is in `/home/coder/files`

#### **Assumptions:**

- It is assumed the user knows how to modify an ESXi Image (adding Kickstart scripts, modifying `boot.cfg`, creating Boot Menus, etc.) and, as such, are not demonstrated below

#### **Instructions**

1. Verify ISO Information

```shell
isoinfo -d -i ./VMware-VMvisor-Installer-7.0U3g-20328353.x86_64.nuc12-syn.iso
CD-ROM is in ISO 9660 format
System id:
Volume id: ESXI-7.0U3G-NUC12-SYN
Volume set id:
Publisher id:
Data preparer id:
Application id: ESXIMAGE
Copyright File id:
Abstract File id:
Bibliographic File id:
Volume set size is: 1
Volume set sequence number is: 1
Logical block size is: 2048
Volume size is: 196201
El Torito VD version 1 found, boot catalog is in sector 1419
NO Joliet present
NO Rock Ridge present
Eltorito validation header:
    Hid 1
    Arch 0 (x86)
    ID ''
    Key 55 AA
    Eltorito defaultboot header:
        Bootid 88 (bootable)
        Boot media 0 (No Emulation Boot)
        Load segment 0
        Sys type 0
        Nsect 4
        Bootoff 4699 18073
```

2. Create temporary folder for ESXi Installer (for modifications to boot commands, adding kickstart scripts, adding boot loader menus, etc)

```shell
mkdir /home/coder/files/custom_esxi_cdrom/
```

3. Extract ESXi installer files from mounted ISO to temporary folder and change permissions (to enable editing):

```shell
osirrox -indev ./VMware-VMvisor-Installer-7.0U3l-21424296.x86_64.nuc-syn.iso -extract / ./custom_esxi_cdrom/
chmod -R u+w /home/coder/files/custom_esxi_cdrom
```

4. Make changes to ESXi Installer
5. Create new ESXi Installer ISO

```shell
cd /home/coder/files/custom_esxi_cdrom
xorriso -as mkisofs -relaxed-filenames -joliet-long --norock -appid ESXIMAGE -volid ESXI70U3G_NUC12-SYN -output /home/coder/files/custom_esxi.iso -eltorito-boot ISOLINUX.BIN -eltorito-catalog BOOT.CAT -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -eltorito-platform 0xEF -e EFIBOOT.IMG -no-emul-boot /home/coder/files/custom_esxi_cdrom
```

**NOTE:** `--norock` is for ESXi Images only

8. Happy ESXi Installing!

### Modify & Repackage ESXi ISO with `mkisofs`

The following are instructions for

- Mounting an ESXi ISO image
- Copying ESXi ISO image to a temporary location (for modification)
- Repackaging using `mkisofs`

#### **NOTE:** The example below:

- Is using an ESXi `7.0U3g` ISO image created with Image Builder which includes [Community Networking Driver for ESXi](https://flings.vmware.com/community-networking-driver-for-esxi) and [Synology NFS Plug-in for VMware VAAI](https://kb.synology.com/en-us/DSM/tutorial/How_do_I_install_Synology_NFS_VAAI_Plug_in_on_an_ESXi_host) VIBs
- Image Builder ISO file is named `VMware-VMvisor-Installer-7.0U3g-20328353.x86_64.nuc12-syn.iso`
- Repackaged ISO file is named `custom_esxi.iso`
- Location of files is in `/home/coder/files`

#### **Assumptions:**

- It is assumed the user knows how to modify an ESXi Image (adding Kickstart scripts, modifying `boot.cfg`, creating Boot Menus, etc.) and, as such, are not demonstrated below

#### **Instructions**

1. Verify ISO Information

```shell
isoinfo -d -i ./VMware-VMvisor-Installer-7.0U3g-20328353.x86_64.nuc12-syn.iso
CD-ROM is in ISO 9660 format
System id:
Volume id: ESXI-7.0U3G-NUC12-SYN
Volume set id:
Publisher id:
Data preparer id:
Application id: ESXIMAGE
Copyright File id:
Abstract File id:
Bibliographic File id:
Volume set size is: 1
Volume set sequence number is: 1
Logical block size is: 2048
Volume size is: 196201
El Torito VD version 1 found, boot catalog is in sector 1419
NO Joliet present
NO Rock Ridge present
Eltorito validation header:
    Hid 1
    Arch 0 (x86)
    ID ''
    Key 55 AA
    Eltorito defaultboot header:
        Bootid 88 (bootable)
        Boot media 0 (No Emulation Boot)
        Load segment 0
        Sys type 0
        Nsect 4
        Bootoff 4699 18073
```

2. Create temporary folder for and mount ESXi Installer ISO Image

```shell
sudo mkdir /mnt/esxi_cdrom
sudo mount -o loop /home/coder/files/VMware-VMvisor-Installer-7.0U3g-20328353.x86_64.nuc12-syn.iso /mnt/esxi_cdrom
mount: /mnt/esxi_cdrom: WARNING: device write-protected, mounted read-only.
```

3. Create temporary folder for ESXi Installer (for modifications to boot commands, adding kickstart scripts, adding boot loader menus, etc)

```shell
sudo mkdir /home/coder/files/custom_esxi_cdrom/
```

4. Copy ESXi installer files from mounted ISO to temporary folder and change permissions (to enable editing)

```shell
cp -r /mnt/esxi_cdrom/* /home/coder/files/custom_esxi_cdrom/
chmod -R u+w /home/coder/files/custom_esxi_cdrom
```

5. Unmount ESXi Installer ISO and remove temporary mountpoint

```shell
sudo umount /mnt/esxi_cdrom/
sudo rmdir /mnt/esxi_cdrom/
```

6. Make changes to ESXi Installer
7. Create new ESXi Installer ISO

```shell
cd /home/coder/files/custom_esxi_cdrom
mkisofs -relaxed-filenames -J -R -A ESXIMAGE -V ESXI70U3G_NUC12-SYN -o /home/coder/files/custom_esxi.iso -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -eltorito-platform -e efiboot.img -no-emul-boot /home/coder/files/custom_esxi_cdrom
```

8. Happy ESXi Installing!
