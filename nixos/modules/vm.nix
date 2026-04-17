{config, pkgs, ...}: {# ==========================================
  # VIRTUALIZACIÓN (KVM / QEMU / VIRT-MANAGER)
  # ==========================================
  
  # 1. Habilitamos el demonio de virtualización nativo de Linux
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true; # Soporte para TPM simulado (útil si luego quieres emular Windows 11)
    };
  };

  # 2. Habilitamos la interfaz gráfica para gestionar las VMs
  programs.virt-manager.enable = true;

  # 3. CRÍTICO: Virt-Manager necesita dconf para guardar tus preferencias (tamaño de ventana, etc.)
  programs.dconf.enable = true;

  # 4. AÑADE TU USUARIO A LOS GRUPOS (Cambia "necro" por tu usuario real si es distinto)
  # 'libvirtd' te permite crear VMs sin usar sudo. 'kvm' te da acceso a la aceleración por hardware.
  users.users.necro.extraGroups = [ "networkmanager" "wheel" "libvirtd" "kvm" ];

  # (Opcional) Instalar un visor alternativo ligero si lo deseas
  environment.systemPackages = with pkgs; [
    spice-vdagent # Permite copiar/pegar entre tu NixOS y la máquina virtual
  ];
}