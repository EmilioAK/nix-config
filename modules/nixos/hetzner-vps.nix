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
    # Bitbucket SSH prefers IPv6 when it is available, but the work VPN/IP
    # whitelist only covers NetBird IPv4 egress. Disable IPv6 on this VPS so
    # outbound traffic consistently follows the NetBird IPv4 exit route.
    enableIPv6 = false;
    # DNS follows the normal outbound path through NetBird. Hetzner's
    # link-local resolvers are only reachable on the public WAN path, so use
    # public resolvers that work from the VPN exit route.
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
      "9.9.9.9"
    ];

    firewall = {
      # Match the pre-Nix VPS behavior: public WAN inbound is open. NetBird
      # can still own normal outbound/default routing, while the Capisoft
      # netbird-public-route service keeps replies sourced from the public IP
      # on the Hetzner main route.
      trustedInterfaces = [
        "enp1s0"
        "eth0"
      ];
    };
  };

  systemd.network = {
    enable = true;
    config.networkConfig = {
      # NetBird owns policy rules/routes for VPN egress. Do not let networkd
      # delete those "foreign" entries when NixOS switches reload networkd.
      ManageForeignRoutes = false;
      ManageForeignRoutingPolicyRules = false;
    };
  };
  systemd.network.networks."30-wan" = {
    matchConfig.Name = "en* eth*";
    networkConfig = {
      IPv6AcceptRA = false;
      LinkLocalAddressing = "ipv4";
    };
    address = [
      "89.167.112.78/32"
    ];
    routes = [
      { Destination = "172.31.1.1/32"; Scope = "link"; }
      {
        Gateway = "172.31.1.1";
        GatewayOnLink = true;
      }
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
