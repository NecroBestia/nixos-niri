# NixFlake — Configuración NixOS + Home Manager

Flake NixOS que gestiona dos máquinas con Niri como compositor Wayland:

| Host | Descripción |
|------|-------------|
| **desktop** | PC sobremesa, GPU NVIDIA serie 570, discos NTFS, kernel pinneado |
| **notebook** | ThinkPad, batería Intel, sin virtualización, thermald |

## Estructura

```
nixFlake/
├── flake.nix                 # Entrada principal (inputs + outputs)
├── flake.lock                # Lockfile (trackear en git)
├── .gitignore
│
├── nixos/                    # ← Configuración del SISTEMA
│   ├── hosts/
│   │   ├── desktop/          # Host: PC sobremesa
│   │   │   ├── configuration.nix
│   │   │   └── hardware-configuration.nix
│   │   ├── notebook/         # Host: ThinkPad
│   │   │   ├── configuration.nix
│   │   │   └── hardware-configuration.nix
│   │   └── shared/
│   │       └── default.nix   # Módulos + config común
│   └── modules/              # Módulos funcionales
│       ├── audio.nix         # PipeWire + WirePlumber
│       ├── bluetooth.nix     # Blueman
│       ├── bootloader.nix    # GRUB EFI + osProber
│       ├── containers.nix    # Podman/Docker (toggleable)
│       ├── displayManager.nix# SDDM + tema astronauta
│       ├── fileManager.nix   # Nautilus (toggleable)
│       ├── firewall.nix      # nftables + OpenSnitch (toggleable)
│       ├── locale.nix        # es_MX / es_CL
│       ├── niri.nix          # Niri compositor (system-level)
│       ├── nvidia.nix        # Driver NVIDIA pinneado 570
│       ├── services.nix      # SSH, Syncthing, Flatpak, portales XDG
│       ├── steam.nix         # Steam + Gamescope + Proton-GE
│       └── vm.nix            # libvirtd (toggleable)
│
├── home-manager/             # ← Configuración de USUARIO
│   ├── hosts/
│   │   ├── desktop/
│   │   │   └── default.nix   # Waybar desktop
│   │   └── notebook/
│   │       └── default.nix   # Waybar notebook
│   ├── shared/
│   │   └── default.nix       # Temas, scripts, alias, GTK/Qt, opencode
│   ├── modules/
│   │   ├── firefox.nix       # Firefox desde nixpkgs-unstable
│   │   ├── niri.nix          # Niri (user-level) + swayidle + mako
│   │   ├── nvim.nix          # Neovim aislado con LSPs
│   │   ├── scripts.nix       # niri-clipboard, niri-wallpaper, spotify-startup
│   │   ├── systemd.nix       # wlsunset + timer 22:00
│   │   ├── waybar.nix        # Barra de estado
│   │   └── wlogout.nix       # Menú de apagado
│   └── config/               # Dotfiles
│       ├── fuzzel/
│       ├── kitty/
│       ├── mako/
│       ├── neovim/
│       ├── niri/
│       ├── waybar/
│       ├── wlogout/
│       └── zathura/
```

## Requisitos

- NixOS 25.05+
- Flakes habilitados (`nix.settings.experimental-features = [ "nix-command" "flakes" ]`)
- Git

## Instalación en una máquina nueva

### 1. Clonar el repositorio

```bash
git clone <tu-repo> ~/nixFlake
```

### 2. Generar hardware-configuration.nix

En la máquina nueva, generar el archivo de hardware:

```bash
sudo nixos-generate-config --show-hardware-config > ~/nixFlake/nixos/hosts/<nombre>/hardware-configuration.nix
```

### 3. Crear el host

Copiar la configuración de un host existente como plantilla:

```bash
cp ~/nixFlake/nixos/hosts/desktop/configuration.nix ~/nixFlake/nixos/hosts/<nombre>/configuration.nix
```

Editar `configuration.nix`:
- Cambiar `networking.hostName`
- Ajustar discos, GPU, kernel
- Activar/desactivar módulos toggleables

### 4. Registrar el host en flake.nix

Agregar una entrada en `nixosConfigurations`:

```nix
<nombre> = nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs pkgs-unstable; };
  modules = [
    ./nixos/hosts/<nombre>/configuration.nix
  ];
};
```

### 5. Hacer rebuild

```bash
sudo nixos-rebuild switch --flake ~/nixFlake#<nombre>
```

## Uso diario

### Reconstruir sistema

```bash
sudo nixos-rebuild switch --flake ~/nixFlake#<nombre>
# o usando el alias (si ya corre Home Manager):
sys-switch
```

### Reconstruir Home Manager

```bash
home-manager switch --flake ~/nixFlake#"necro@<hostname>"
# o usando el alias:
hm-switch
```

### Ambos a la vez

```bash
sys-switch && hm-switch
```

## Módulos toggleables

| Opción | Default | Descripción |
|--------|---------|-------------|
| `vm.libvirtd` | `true` | Virtualización KVM/QEMU |
| `services.opensnitch.enable` | `true` | Firewall interactivo |
| `programs.containers.enable` | `true` | Runtime de contenedores |
| `programs.containers.backend` | `"podman"` | `"podman"` o `"docker"` |
| `fileManager.enable` | `true` | Nautilus + GVFS + UDisks2 |

Cada host puede overridear:

```nix
# notebook/configuration.nix
vm.libvirtd = false;
services.opensnitch.enable = false;
```

## Personalización

### Wallpapers

Los scripts `niri-wallpaper` y `niri-wallpaper-blur` buscan imágenes en `~/Pictures/Wallpapers/`. Formatos: `.jpg` y `.png`.

### Tema GTK/Qt/Cursor

Editar variables al inicio de `home-manager/shared/default.nix`:

```nix
themeName = "Colloid-Dark";
cursorName = "Bibata-Modern-Ice";
cursorSize = 24;
MyTerminal = "kitty";
```

### Atajos de teclado

Editar `home-manager/config/niri/binds.kdl`.

## A futuro: Disko + Impermanence

Está planificado integrar dos herramientas avanzadas de NixOS:

### Disko — Particionado declarativo

[Disko](https://github.com/nix-community/disko) permite definir el particionado y formateo de discos directamente desde Nix, sin intervención manual. El flake completo (SO + particiones) se aplica de una sola vez.

Estructura planeada:

```
nixos/
├── disk-configs/
│   ├── desktop.nix      # EFI + ext4 root + swap + NTFS data
│   └── notebook.nix      # EFI + ext4 root + swap
```

Ejemplo de uso futuro:

```bash
# Particionar y formatear desde cero
sudo nix run github:nix-community/disko -- --mode disko ./nixos/disk-configs/desktop.nix

# Luego instalar el sistema
sudo nixos-install --flake ~/nixFlake#desktop
```

### Impermanence — Sistema de archivos efímero

[Impermanence](https://github.com/nix-community/impermanence) monta `/` en tmpfs y solo persiste lo declarado explícitamente (via `/persist`). Cada reinicio obtiene un sistema limpio.

```
nixos/
├── modules/
│   └── impermanence.nix  # Directorios y archivos a persistir
```

Lo que se persiste típicamente:

| Ruta | Motivo |
|------|--------|
| `/etc/ssh/ssh_host_*` | Claves del host SSH |
| `/var/lib/bluetooth` | Dispositivos emparejados |
| `/var/lib/flatpak` | Apps Flatpak instaladas |
| `/var/lib/systemd` | Estados de servicios |
| `/home` | Datos de usuario |
| `/persist/root` | Dotfiles de root |

Ambos módulos son compatibles y se complementan: **Disko** declara la estructura de particiones (incluyendo `/persist`), e **Impermanence** define qué vive en `/persist` y qué se regenera en cada boot.

## Solución de problemas

### `docker` group no existe con Podman

El grupo `docker` solo se agrega cuando `programs.containers.backend = "docker"`. Con Podman no se necesita.

### OpenSnitch bloquea todo al inicio

`services.opensnitch.settings.DefaultAction = "deny"`. Usar `opensnitch-ui` para permitir apps. Desactivar con `services.opensnitch.enable = false` en el host si es muy restrictivo.

### NVIDIA + kernel pinneado

El kernel está fijado a una revisión específica de nixpkgs (rev `d756e13`). No cambiar sin verificar compatibilidad con el driver 570.195.03.

### Syncthing no monta disco

Los discos NTFS usan `x-systemd.automount` — Syncthing espera automáticamente a que el disco esté disponible.
