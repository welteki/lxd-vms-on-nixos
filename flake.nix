{
  description = "Make VMs work on LXD";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";

  outputs = { self, nixpkgs }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
      };
    in {
      nixosModules.lxd-vm = {
        # used by lxd to communicate with instances
        boot.kernelModules = [ "vhost_vsock" ];

        networking.firewall.enable = false;  # has to be off with nftables enabled
        networking.nftables.enable = true;
        networking.nftables.ruleset = "";  # you might want something here

        # lxcfs will give your lxd containers a limited view of /proc and /sys
        # including making them aware of their CPU and memory limits!
        #
        # WARNING: If you enable this, and later run nixos-generate-config, be sure to
        # edit hardware-configuration.nix and remove the /var/lib/lxcfs filesystem or
        # your system will fail to boot!
        #
        virtualisation.lxc.lxcfs.enable = true;

        virtualisation.lxd.enable = true;
        virtualisation.lxd.package = pkgs.lxd;
        # virtualisation.lxd.zfsSupport = true;  # zfs is recommended
        virtualisation.lxd.recommendedSysctlSettings = true;
        systemd.services.lxd.path = with pkgs; [

          # the lxd-agent in nixpkgs is dynamically linked and will fail in your guest VM!
          # this builds a statically compiled version
          ( import ./lxd-agent.nix pkgs )

          # lxd won't find virtiofsd or virtfs-proxy-helper without making sure they're in the path
          ( import ./virtiofsd.nix pkgs )

          # the lxd nixpkg doesn't know it needs kvm in its path to run qemu!
          kvm

          # the lxd nixpkg doesn't know it needs gptfisk in its path
          # to create the right partitions on the vm block device
          gptfdisk

          # optionally, if you want to mount your cloud-init stuff by virtual CD, lxd
          # will use mkisofs, which the nixpkg doesn't know about
          cdrkit

        ];

        systemd.services.lxd.environment = {

          # lxd will look for EFI firmware in /usr/share, but will not find it there
          # so we need to tell it about our metapackage
          LXD_OVMF_PATH = ( import ./ovmf-meta.nix pkgs );

        };
      };
    };
}
