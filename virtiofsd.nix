{ pkgs, ... }:

with pkgs;

stdenv.mkDerivation rec {
  name = "virtiofsd";
  buildCommand = ''
    mkdir -p $out/bin
    ln -s ${pkgs.kvm}/libexec/virtiofsd $out/bin/
    ln -s ${pkgs.kvm}/libexec/virtfs-proxy-helper $out/bin/
  '';
}
