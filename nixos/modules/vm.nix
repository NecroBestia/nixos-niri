#===================================================================
# VIRTUALIZACIÓN — KVM / QEMU / Virt-Manager
#===================================================================
# libvirtd: Demonio de virtualización que gestiona máquinas virtuales
# KVM/QEMU. Virt-Manager es la interfaz gráfica.
#
# TOGGLEABLE: vm.libvirtd = false desactiva todo (útil en portátiles
# donde no se necesita virtualización).
#
#   - qemu_kvm: Emulador optimizado con aceleración KVM.
#   - runAsRoot = true: QEMU corre con permisos elevados para
#     acceder a dispositivos KVM.
#   - swtpm.enable = true: TPM simulado (esencial para Windows 11).
#   - necro extraGroups: "libvirtd" + "kvm" para crear VMs sin sudo.
#   - spice-vdagent: Copiar/pegar entre host y VM.
#===================================================================
{ config, pkgs, lib, ... }: {
  options.vm.libvirtd = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable libvirtd, virt-manager and virtualization tools";
  };

  config = lib.mkIf config.vm.libvirtd {
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
      };
    };

    programs.virt-manager.enable = true;
    programs.dconf.enable = true;
    users.users.necro.extraGroups = [ "libvirtd" "kvm" ];
    environment.systemPackages = with pkgs; [ spice-vdagent ];
  };
}
