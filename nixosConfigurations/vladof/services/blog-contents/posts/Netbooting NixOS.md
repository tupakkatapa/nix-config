---
date: "2024-03-27"
---

Let's talk about NixOS for a second. It has a declarative configuration model: you create or edit a description of the desired configuration of your system, and then NixOS takes care of making it happen. This means that you are defining *what* the system should be like, not *how* it achieves that state.

So, it is declarative programming.. [or is it?](https://youtu.be/TN25ghkfgQA?si=8iDYxKcA4dyNwoC0&t=2s)

> Only when we combine the declarative nature of NixOS with an ephemeral environment can we say that we have a truly declarative system. What do I mean by "truly declarative"? Isn't NixOS already declarative enough? It's that NixOS still allows for long-term changes outside of its configuration if it has been installed on an internal hard drive. Our approach enforces a truly declarative system, as non-declarative changes won't persist to the next session.

That is a quote from documentation I wrote recently for the project I have been working on for the last six months. It states that getting rid of the "works on my machine" mantra can not only be dealt with a declarative operating system alone. And since the operating system "does not exist" until you start up your computer, it has the potential to adapt and optimize to the machine's hardware on-the-fly. For example, the right kernel modules and drivers can be enabled automatically using the data from PCI bus configuration registers.

Also, starting up your everyday machines and servers via netbooting only starts to make sense when we introduce pre-configured images anyway, so this is kind of a perfect combination.

## Booting Process

Before trying to understand the netbooting from a NixOS point of view, we need to know about the outline of the booting process. Linux booting involves two primary stages, Stage 1 and Stage 2, orchestrated to transition the system from the bootloader to a fully operational state.

### Stage N° 1

The process starts with Stage 1, initiated directly by the bootloader. We are interested in what happens at the end of Stage 1; here is a quick rundown what happens until then.

The Linux kernel prepares the system for booting by:

  - Decompressing itself
  - Setting up the computer's memory and configuring hardware
  - Preparing the initrd image for use
  - Loading necessary drivers and virtual devices
  - Cleaning up and setting the stage for user space initiation

At this point, the system is ready for the transition to user space, guided by the init process which we are interested in.

#### Init process

This is basically just a shell script that is run by the kernel, the location of which should be specified with the `init` kernel parameter.

In the context of NixOS, it might look something like this:

```
init=/nix/store/0d2hzxxclcg60gxwgph9sjl0wzy7l9ag-nixos-system-vladof-24.05.20240322.4f3bceb/init
```

It points to an `init` symlink within the Nix store, that symlink points to another derivation within the Nix store `init -> /nix/store/wbp286g2jzflgarp6qrpd47grqv0gqfv-stage-1-init.sh`, containing the actual init script called `stage-1-init.sh`.

This script performs various tasks to prepare the system for the transition from Stage 1 to Stage 2:

  - Setting essential environment variables and creating symbolic links for key binaries
  - Managing filesystems, including checks and "[neededForBoot](https://nixos.org/manual/nixos/stable/options#opt-fileSystems._name_.neededforboot)" mounts
  - Preparing the system for Stage 2, including device management and system cleanup

Upon completion, Stage 1 effectively hands over control to Stage 2 which is also a script.

### Stage N° 2

Completely irrelevant here but for the sake of explaining the whole booting process:

  - Processing rest of the boot options and setting up the filesystem
  - Mounting necessary system directories and handling DNS configurations
  - Activating the system configuration and running post-boot commands
  - Starting systemd in a clean environment for system management

## Netbooting

If you don't know what netbooting is and how it works, honestly, I don't know what you are doing here, but [here](https://networkboot.org/fundamentals/) you go. Let's check out the requirements of hardware and configuration to enable booting of NixOS configurations.

### Server Requirements

We need to have a server running DHCP/TFTP and HTTP(s) to serve the boot images. Preferably it has to be able to serve certain boot images for specific hosts. Luckily, there is a NixOS module that does exactly that; [Nixie](https://github.com/majbacka-labs/nixos.fi). It significantly simplifies the process of setting up and managing our network-based boot environment, and its only requirements are that the host is running NixOS and is capable of compiling NixOS hosts and kernel, hardware-wise.

### Client Requirements

The requirements for the bootable client, regardless of whether we are talking about hardware or operating system configuration, should be as close as possible to non-existent. The only legitimate requirement should be that the client configuration has a compatible format for netbooting.

- **Kernel + initrd**

    ```
    #!ipxe
    kernel bzImage init=/nix/store/w95bhycbcnx5npfrvp88p8993qcj8nk1-nixos-system-bandit-23.11.20240308.2be119a/init initrd=initrd.zst loglevel=4
    initrd initrd.zst
    boot
    ```

    This format is a traditional boot configuration that includes the Linux kernel (bzImage) and an initial RAM disk (initrd). The initrd is a temporary root file system that is loaded into memory when the system boots. It contains our whole, pre-configured operating system and is bound to the kernel and loaded as part of the kernel boot procedure.

    There are also some additional use cases for this format. It can be used to [kexec](https://wiki.archlinux.org/title/Kexec) into another kernel from the currently running kernel, and it is suitable for use with the [rEFInd](http://www.rodsbooks.com/refind/) boot manager.

    >>> /boot/EFI/BOOT/refind.conf

        timeout 1
        default_selection 1

        menuentry "Bandit" = {
          icon /EFI/BOOT/icons/os_linux.png
          volume "EFI system partition"
          loader images/bandit/bzImage
          initrd images/bandit/initrd.zst
          options "init=/nix/store/w95bhycbcnx5npfrvp88p8993qcj8nk1-nixos-system-bandit-23.11.20240308.2be119a/init loglevel=4"
        }

    >>>

    You can apply this format with [this](https://github.com/ponkila/nixobolus/blob/1667a313ed21acf69daf749208b1e42bc5814e1c/modules/netboot-kexec.nix) netboot-kexec NixOS module, but please be aware that there is an [issue](https://github.com/NixOS/nixpkgs/issues/203593) that prevents booting if the initrd exceeds 2.1 GB.

- **Kernel + initrd + squashfs**

    ```
    #!ipxe
    kernel bzImage rootfs=squashfs.img init=/nix/store/0d2hzxxclcg60gxwgph9sjl0wzy7l9ag-nixos-system-vladof-24.05.20240322.4f3bceb/init initrd=initrd.zst ip=dhcp boot.shell_on_fail boot.shell_on_fail mitigations=off l1tf=off mds=off no_stf_barrier noibpb noibrs nopti nospec_store_bypass_disable nospectre_v1 nospectre_v2 tsx=on tsx_async_abort=off loglevel=4
    initrd initrd.zst
    boot
    ```

    To address the issue of booting larger images, we had to slightly modify the previous format to this. Now, most of the initrd contents have been moved to a squashfs image, leaving only a minimal set of directories and executables in the initrd. This change allows the squashfs to be downloaded during the init process, bypassing the size limitation introduced by the issue. To achieve this, we need to use a [patched init script](https://github.com/majbacka-labs/nixpkgs/commits/patch-init1sh/) that introduces a `rootfs` kernel parameter.

    The client has to be able to download the squashfs in Stage 1; for this, we need to make the drivers built-in to the kernel. This can be automated, but you can manually use [lspci](https://www.man7.org/linux/man-pages/man8/lspci.8.html) and [kernelconfig.io](https://www.kernelconfig.io/index.html) to get kernel module names.

    Then enable them like this:

    ```nix
    boot.kernelPatches = [
      {
        name = "enable r8169 (NIC)";
        patch = null;
        extraConfig = ''
          ETHERNET y
          NET_VENDOR_REALTEK y
          R8169 y
        '';
      }
    ];
    ```

    Unlike the previous format, this cannot be used to kexec into another kernel because it does not support a separate squashfs image. I am currently attempting to make this format compatible with the rEFInd boot manager. Let's see how it progresses.

    We've successfully implemented this format as NixOS module; however, it's part of the Nixie project, which is closed-source, preventing me from sharing it.

- **ISO**

    It should be possible to use the ISO format, although I haven't experimented with it since we've got along with the previous formats. If you want to give it a go, check out the [sanboot](https://ipxe.org/cmd/sanboot) command.
    **Nixie does not support the ISO format**.

## Debug

If you decide to get your hands dirty regarding booting process, here are some tips for debugging when facing issues.

1. **Debug Mode**

    To gain a shell at the Stage 1 aka. single-user mode, you have to enable debug mode like this:

    ```nix
    boot.kernelParams = [
      # Initiates a an interactive shell at Stage 1
      "boot.debug1"

      # Same as debug1, but waits until kernel modules are loaded
      "boot.debug1devices"

      # Same as debug1, but waits until 'neededForBoot' filesystems are mounted
      "boot.debug1mounts"

      # Same as debug1, but only if the boot process encounters an error
      "boot.shell_on_fail"
    ];
    ```

2. **Kernel Log**

    In case of errors, drop in a shell and check `/dev/kmsg`.

## References

- [Wikipedia - Booting process of Linux](https://en.wikipedia.org/wiki/Booting_process_of_Linux#cite_ref-redhat_startup_14-1)
- [Nixpkgs - stage-1-init.sh](https://github.com/NixOS/nixpkgs/blob/8ef6d577a5e581ed770d4ffa94539440b8e7a8f1/nixos/modules/system/boot/stage-1-init.sh)
- [Nixpkgs - stage-2-init.sh](https://github.com/NixOS/nixpkgs/blob/b95879a53b898a42f5f4633fa9fbaa6eae9f04e2/nixos/modules/system/boot/stage-2-init.sh)
- [NixOS Manual - Boot Problems](https://nixos.org/manual/nixos/stable/index.html#sec-boot-problems)

