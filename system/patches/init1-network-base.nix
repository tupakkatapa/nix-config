{
  pkgs,
  lib,
  ...
}: {
  boot.initrd.extraFiles."/etc/resolv.conf".source = pkgs.writeText "resolv.conf" ''
    nameserver 1.1.1.1
  '';
  boot.kernelParams = [
    "ip=dhcp"
    "boot.shell_on_fail"
    #"boot.debug1"

    "mitigations=off"
    "l1tf=off"
    "mds=off"
    "no_stf_barrier"
    "noibpb"
    "noibrs"
    "nopti"
    "nospec_store_bypass_disable"
    "nospectre_v1"
    "nospectre_v2"
    "tsx=on"
    "tsx_async_abort=off"
  ];
  boot.kernelPatches = [
    {
      name = "kernel network config";
      patch = null;
      extraConfig = ''
        # IP Configuration and DNS
        IP_PNP y
        IP_PNP_DHCP y
        IP_PNP_BOOTP y
        IP_PNP_RARP y
        DNS_RESOLVER y

        # Transport Layer Security
        TLS y
        CRYPTO_AEAD y
        CRYPTO_NULL y
        CRYPTO_GCM y
        CRYPTO_CTR y
        CRYPTO_CRC32C y
        CRYPTO_GHASH y
        CRYPTO_AES y
        CRYPTO_LIB_AES y

        # Misc
        PHYLIB y

        # PTP clock
        PPS y
        PTP_1588_CLOCK y

        # Filesystem
        BLK_DEV_LOOP y
        LIBCRC32C y
        OVERLAY_FS y
        SQUASHFS y

        # USB and HID
        HID y
        HID_GENERIC y
        KEYBOARD_ATKBD y
        TYPEC y
        USB y
        USB_COMMON y
        USB_EHCI_HCD y
        USB_EHCI_PCI y
        USB_HID y
        USB_OHCI_HCD y
        USB_UHCI_HCD y
        USB_XHCI_HCD y

        # Virtualization
        VIRTIO y
        VIRTIO_CONSOLE y
        VIRTIO_INPUT y
      '';
    }
  ];
}
