# Elegoo Centauri Carbon - Yocto Firmware Build

This repository contains a Yocto Project-based firmware build system for the Elegoo Centauri Carbon 3D printer family. The mainboard of these printers is powered by an Allwinner R528 SoC.

_**Unsure about what COSMOS is? [Check the FAQ to learn more](https://docs.opencentauri.cc/klipper-conversion/cosmos/cosmos/#faq)**_

## Prerequisites

Before starting the build process, you need to install the required dependencies on your host system (Ubuntu/Debian is assumed):

```bash
sudo apt update
sudo apt install gawk wget git diffstat unzip texinfo gcc build-essential \
     chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
     iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev \
     pylint xterm python3-subunit mesa-common-dev zstd liblz4-tool file locales \
     bmap-tools sunxi-tools
```

## Build Configuration Options

### Machine Selection (CC1 vs CC2)

The build supports different machine configurations for the Centauri Carbon variants:

| Machine | Description |
|---------|-------------|
| `centauri-carbon-1` | Centauri Carbon 1 (default) |
| `centauri-carbon-2` | Centauri Carbon 2 (including C2, C2C, CC2C) |

The default in `build/conf/local.conf` is set to CC1:
```bash
MACHINE ?= "centauri-carbon-1"
```

To build for CC2, specify the machine on the command line:
```bash
MACHINE=centauri-carbon-2 bitbake cosmos-image-usb
```

### Image Type Selection (USB vs eMMC)

Choose the appropriate image type based on your target boot media:

| Image Recipe | Target Media | Use Case |
|--------------|--------------|----------|
| `cosmos-image-usb` | USB drive | Development, testing, or running from USB |
| `cosmos-image-mmc` | Internal eMMC | Production installation on printer internal storage |

#### USB Image (`cosmos-image-usb`)
- Boots from USB drive
- Read-write root filesystem
- Suitable for development and testing
- Larger partition layout for USB storage

#### eMMC Image (`cosmos-image-mmc`)
- Installs to internal eMMC storage
- Read-only SquashFS root with overlay filesystem for `/etc` on `/data` partition
- Optimized for production use
- Includes A/B boot partition scheme for safe updates via swupdate

## How to Build

1. **Initialize the build environment:**
   Source the environment setup script provided by Openembedded Core to prepare your shell for BitBake.
   ```bash
   TEMPLATECONF="$PWD/meta-opencentauri/conf/templates/opencentauri" source openembedded-core/oe-init-build-env build
   ```

2. **Configure your target (if needed):**
   Ensure `MACHINE` is set correctly in `build/conf/local.conf`:
   ```bash
   # For CC1 or CC2
   MACHINE ?= "centauri-carbon-1"
   ```

3. **Run BitBake:**
   Choose the appropriate image recipe for your target:
   
   **For USB booting:**
   ```bash
   bitbake cosmos-image-usb
   ```
   
   **For eMMC/internal storage:**
   ```bash
   bitbake cosmos-image-mmc
   ```
   
   *Note: The first build will take a significant amount of time as it downloads and compiles all necessary packages from source.*

## Build Outputs

After a successful build, the output files are located in:

```
tmp/deploy/images/centauri-carbon-1/
```

### USB Image Outputs
- `cosmos-image-usb-centauri-carbon-1.wic.gz` - Compressed disk image for USB drives

### eMMC Image Outputs
- `cosmos-image-mmc-centauri-carbon-1.wic.gz` - Full disk image for eMMC
- `bootA.img` - Extracted boot partition image (for swupdate)
- `bootlogos.img` - Extracted boot logos partition image (for swupdate)
- `cosmos-image-mmc-centauri-carbon-1.squashfs` - SquashFS root filesystem

## Disk Space Requirements

Building a complete Yocto image requires a substantial amount of disk space. Based on current build sizes, you should expect the project directory (including downloaded sources, build artifacts, and caches) to use approximately **38GB to 40GB** of disk space. Please ensure you have adequate free space before starting the build.

## Running on the Centauri Carbon 1

### USB Boot Method (Development)

Note that the current install requires having a serial UART connected to the CC1 motherboard, as well as a FEL USB cable attached. This will prevent the toolhead from being plugged in!

1. **Install built firmware image to a USB drive.**
   *(Warning: This is a destructive operation! Replace `sdX` with your actual USB drive device like `sdb`, `sdc`, etc.)*
   ```bash
   sudo bmaptool copy tmp/deploy/images/centauri-carbon-1/cosmos-image-usb-centauri-carbon-1.wic.gz /dev/sdX
   ```

2. **Boot into FEL Mode.**
   Connect via serial UART. Power on the printer and boot into the Elegoo u-boot, pressing any key to abort the normal boot process. Issue the following command to boot to FEL mode:
   ```
   efex
   ```

3. **Boot the new Yocto firmware image via USB from FEL mode.**
   Run the following commands on your host machine to load the mainline u-boot:
   ```bash
   sunxi-fel uboot tmp/deploy/images/centauri-carbon-1/u-boot-sunxi-with-spl.bin
   ```

   The mainline u-boot followed by the mainline Linux kernel should now boot! This will start up Klipper, Moonraker, Mainsail daemons, and a dropbear SSH server.

   **Important:** You need to unplug the FEL USB as it will conflict with the mainboard's ability to talk to the toolhead.

4. **Connect and Configure WiFi.**
   Login as the `root` user via the serial UART console.

   Configure your WiFi SSID and password:
   ```bash
   wpa_passphrase "SSID" "password" > /etc/wpa_supplicant.conf
   ```
   Then restart the WiFi adapter:
   ```bash
   ifdown wlan0 && sleep 5 && ifup wlan0
   ```

5. **Access the Printer Interface.**
   Find the printer's IP address by running `ip a`. Access the Mainsail interface by visiting the printer's IP address via HTTP (port 80) in your web browser!

### eMMC Install Method (CC1)

For installing to internal eMMC storage, use the swupdate-based installation:

1. Build the `cosmos` target. This recipe depends on `cosmos-image-mmc` and produces the SWUpdate bundle:
   ```bash
   bitbake cosmos
   ```
2. Locate the generated `.swu` file in `tmp/deploy/images/centauri-carbon-1/` (e.g. `cosmos-centauri-carbon-1.swu`).
3. Copy the `.swu` file to a FAT32-formatted USB drive in the `install_opencentauri` folder, renaming it to `update.swu`.
4. Insert the USB drive into the printer
5. Import the `IMPORT_ME_DO_NOT_PRINT` file via the printer screen as you would for stock OpenCentauri

### eMMC Install Method (CC2)

For installing to internal eMMC storage, use the signed archive installation:

1. Build the `cosmos` target. This recipe depends on `cosmos-image-mmc` and produces the .zip.sig bundle:
   ```bash
   bitbake cosmos
   ```
2. Locate the generated `.zip.sig` file in `tmp/deploy/images/centauri-carbon-2/` (e.g. `cc2_eeb001_26.09.00.00.zip.sig`).
3. Copy the `.zip.sig` file to the root of a FAT32-formatted USB drive.
4. Insert the USB drive into the printer
5. Import the offline update via the printer screen

## Tailscale

Tailscale is off unless you opt in. The package is the combined
`tailscaled` binary from the `tailscale` recipe already in
`meta-networking` (1.94.2 in the pinned layer), built static for
armv7 with the CLI linked in (`ts_include_cli`) and the integrations
this board cannot use left out (Kubernetes, Tailscale SSH, Taildrop,
subnet routing, exit nodes, iptables, and similar).

A normal image does not contain it and the kernel stays as it is.
`fragment.cfg` still leaves out `CONFIG_NETFILTER`. Turning the
feature on adds a TUN device, IPv6, and policy routing, which
tailscaled needs to put a real 100.x address on the printer. It does
not turn netfilter on. The conntrack table is about 1 MB, and basic
tailnet access does not need it. Subnet routers and exit nodes will
not work.

### Build and flash

In `build/conf/local.conf`:

```bash
DISTRO_FEATURES:append = " tailscale"
```

The leading space is required. Then build and flash the same way as a
normal eMMC image:

```bash
bitbake cosmos
```

The `.swu` (CC1) or `.zip.sig` (CC2) is installed with the usual USB
update. The feature also applies to `cosmos-image-usb`.

### Log in

`tailscaled` starts at boot, after Klipper and Moonraker. Node state
is `/data/tailscale` when `/data` is mounted, so it survives an OTA
update. On a writable USB root it is `/var/lib/tailscale`. `/etc` is
the overlay on `/data`, so the files below survive an update too.

The first login has to pass three flags. The kernel has no netfilter,
and Tailscale's defaults would also take over DNS:

```bash
tailscale up --accept-dns=false --ssh=false --netfilter-mode=off
```

Open the URL it prints, in a browser on a machine that is already on
the tailnet (or that can log into the Tailscale admin console).
Afterwards `tailscale ip -4` is the address to use for Mainsail,
Fluidd, and SSH. Dropbear is already listening on port 22.

To log in without a console, create an auth key in the Tailscale admin
console (a reusable, tagged key is the least annoying on a printer;
disable key expiry or the node will drop off later). Either:

- write that one line to `/etc/tailscale/authkey` (mode `600`) and run
  `service tailscaled restart`, or
- put the same line in a file named `tailscale-authkey` on a FAT USB
  stick and insert it. The stick is handled like `wpa_supplicant.conf`:
  the file is copied to `/etc/tailscale/authkey`, removed from the
  stick, and the service is started.

Moonraker only trusts LAN ranges by default. A tailscale build also
trusts `100.64.0.0/10` and `fd7a:115c:a1e0::/48`, which is what makes
the web UI answer on the tailscale address. `tailscaled` is added to
Moonraker's service list so it can be restarted from the UI.

`/etc/default/tailscaled` has `TS_ENABLE`, the memory cap, and the
`tailscale up` flags. Set `TS_ENABLE=0` to keep the packages installed
but not run the daemon.

A factory reset wipes the `/etc` overlay, including the auth key, and
does not delete `/data/tailscale`. The printer stays on the tailnet.
`tailscale logout`, or `rm -rf /data/tailscale` followed by a reboot,
removes it.

If `/dev/net/tun` cannot be opened, the service falls back to
userspace networking. In that mode other devices cannot open
`http://100.x.x.x` until you publish the UI:

```bash
tailscale serve --bg 80
```

### Size and memory

Measured from a `CGO_ENABLED=0` `GOARM=7` build of the same 1.94.2
sources and the same omit tags the recipe uses (Go 1.25.5, stripped):

| Build | Uncompressed | lz4 -1 (squashfs is lz4) |
| --- | --- | --- |
| This recipe (combined binary) | 18.6 MiB (19529912 bytes) | 10.5 MiB |
| Same version with only the stock meta-oe omit set | 30.1 MiB | 16.0 MiB |

Idle RSS on x86_64, userspace networking, before login, with
`GOMEMLIMIT=40MiB` and `GOMAXPROCS=1`: about 24 MB. About 19 MB of
that is the mapped binary (reclaimable file cache) and about 6 MB is
anonymous heap. The 40 MiB cap was not binding at idle. A connected
node on a larger tailnet will use more heap, up to that cap, and then
the Go collector runs more often. Kernel mode was not measured here
(opening a TUN device was not permitted in the build environment); it
is the mode the init script uses when `/dev/net/tun` exists, and it is
the one that puts the printer's own ports on the tailscale address.

The eMMC rootfs partition is 128 MB. About 11 MB of compressed
Tailscale fits only if the rest of the image still leaves that much
room. If `wic` fails because the squashfs is larger than the
partition, the image is over the limit.

The daemon is niced to 10 so Klipper is preferred. There is no memory
cgroup: the kernel build turns cgroups off.

### What this does not do

- Subnet routing and exit nodes. Those need netfilter.
- Tailscale SSH. Dropbear is the SSH server. It is reachable on the
  tailscale address once the TUN device is up.
- MagicDNS on the printer itself (`--accept-dns=false`). Other
  devices still resolve the printer's name.
- A stock build. Leave the `DISTRO_FEATURES` line commented out.

## Configuration and Services

- **Klipper Configuration:** In the current build, the Klipper `printer.cfg` is located in `/etc/klipper/config/printer.cfg`.
- **Services:** Everything is running as an `init.d` service. You can restart Klipper by running:
  ```bash
  service klipper restart
  ```

## Troubleshooting Build Issues

### Where to put the tree (WSL2)

Clone and build under your Linux home directory (`/home/...`). That disk is ext4. A tree on `/mnt/c` (the Windows drive) is case-insensitive and breaks unpack and `autoreconf`. Check with:

```bash
pwd
findmnt -T .
```

`pwd` must not start with `/mnt/`, and the filesystem type must be `ext4`. If the tree is on the Windows drive, clone it again under `$HOME` and build there. Do not copy `build/tmp` across.

Source the environment in each new shell so `bitbake` is the copy in this repo (`bitbake/bin/bitbake`, 2.18), not a copy from apt:

```bash
TEMPLATECONF="$PWD/meta-opencentauri/conf/templates/opencentauri" source openembedded-core/oe-init-build-env build
which bitbake
bitbake --version
```

### bzip2-native and `configure.ac`

Upstream bzip2 1.0.8 has no Autotools input. The recipe adds one from the layer:

`openembedded-core/meta/recipes-extended/bzip2/bzip2/configure.ac`

via `file://configure.ac;subdir=${BP}`. Unpack places it at:

`build/tmp/work/x86_64-linux/bzip2-native/1.0.8/sources/bzip2-1.0.8/configure.ac`

`do_configure` then rewrites `%BZIP2_VERSION%` in that file and runs `autoreconf`. The layer file contains `AC_INIT`. Two failures come from the work directory, not from that recipe:

- `autoreconf: error: configure.ac: AC_INIT not found` means the `configure.ac` that was unpacked is empty or is not the layer file. Check the layer copy, then the unpacked copy (commands below).
- `sed: can't read .../sources/bzip2-1.0.8/configure.ac` means configure ran without unpacking. Deleting `tmp/work/.../bzip2-native` by hand removes the sources but leaves the task stamps in `tmp/stamps`, so BitBake skips unpack. `bitbake -c cleansstate` takes a recipe name, not a path to a `.bb` file. `virtual:native:.../bzip2_1.0.8.bb` does not clean `bzip2-native`.

```bash
grep AC_INIT openembedded-core/meta/recipes-extended/bzip2/bzip2/configure.ac
bitbake -c cleansstate bzip2-native
bitbake -c unpack bzip2-native
f=tmp/work/x86_64-linux/bzip2-native/1.0.8/sources/bzip2-1.0.8/configure.ac
grep AC_INIT "$f"
bitbake bzip2-native
```

`grep` on the layer file and on `$f` must both print `AC_INIT(bzip2, %BZIP2_VERSION%)`. The version token is filled in during configure.

Warnings that are not this failure: a fetch falling back to a mirror, and `SOURCE_DATE_EPOCH value '' is invalid`. The latter is an empty stamp left by an interrupted task or a deleted source tree. `cleansstate` removes it. BitBake then uses its fallback timestamp.

### Clean Build
If you encounter build issues, try cleaning the specific package. Use the recipe name:
```bash
bitbake -c cleansstate <package-name>
bitbake <image-target>
```

### Full Reset
For a complete clean build (removes all build artifacts):
```bash
rm -rf tmp/
source openembedded-core/oe-init-build-env build
bitbake <image-target>
```
