{ lib, modulesPath, ... }: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.loader = {
    efi = {
      canTouchEfiVariables = false;
      efiSysMountPoint = "/boot";
    };
    grub = {
      enable = true;
      efiInstallAsRemovable = true;
      efiSupport = true;
    };
  };

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "sd_mod"
    "sr_mod"
    "uhci_hcd"
    "virtio_pci"
    "virtio_scsi"
  ];

  networking = {
    useDHCP = lib.mkDefault false;
    nameservers = [
      "2a01:4ff:ff00::add:2"
      "2a01:4ff:ff00::add:1"
    ];
  };

  systemd.network.enable = true;
  systemd.network.networks."30-wan" = {
    matchConfig.Name = "enp1s0 ens3 eth0";
    networkConfig.DHCP = "ipv4";
    address = [
      "2a01:4f9:c014:e9ce::1/64"
    ];
    routes = [
      { Gateway = "fe80::1"; }
    ];
  };

  services.qemuGuest.enable = true;
  zramSwap.enable = true;

  # This wipes only the VPS root disk. The Hetzner volume is /dev/sdb and is
  # mounted separately below by UUID.
  disko.devices.disk.root = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02";
          priority = 1;
        };
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };

  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/4adb0ee0-b15b-4dbb-8c41-b13d011988e2";
    fsType = "ext4";
    options = [
      "nofail"
      "x-systemd.device-timeout=10s"
    ];
  };
}
