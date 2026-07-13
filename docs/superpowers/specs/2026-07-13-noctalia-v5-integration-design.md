# Diseño de Integración: Noctalia v5 + Stylix Dinámico

**Fecha**: 2026-07-13
**Estado**: Aprobado
**Branch**: `feature/noctalia-v5`

## Objetivo

Reemplazar progresivamente Waybar, Fuzzel, SwayNC, Wlogout, Swaylock, cliphist, awww, swaybg y scripts personalizados por Noctalia v5, manteniendo estética rectangular/simétrica con transparencia, e integrando Stylix de forma dinámica basada en el wallpaper.

## Arquitectura

```
Noctalia v5 (C++ native, OpenGL ES) — runtime dynamic
├── Bar (reemplaza Waybar)
├── Launcher (reemplaza Fuzzel)
├── Notifications + Control Center (reemplaza SwayNC)
├── Wallpaper engine (reemplaza awww + swaybg)
│   └── automation → picks random wallpaper every 30 min
│   └── theme.source = "wallpaper" → generates palette
├── OSD (volume, brightness)
├── Lock screen (reemplaza Swaylock)
├── Clipboard (reemplaza cliphist)
├── Session actions (reemplaza Wlogout)
└── Templates → Firefox, kitty (dynamic colors at runtime)

Stylix (build-time) — static between rebuilds
├── image = symlink to ~/.cache/current-stylix-wallpaper
├── polarity = "dark"
├── base16Scheme = catppuccin-mocha (fallback if symlink missing)
├── GTK theme, cursor, GRUB, console
└── hm-switch to regenerate based on current wallpaper
```

## Flujo de datos

```
Noctalia wallpaper automation (cada 30 min)
  → cambia wallpaper (random, fade transition)
  → genera paleta via theme.source = "wallpaper"
  → hook: ln -sf "$NOCTALIA_WALLPAPER_PATH" ~/.cache/current-stylix-wallpaper
  → hook: regenera templates (Firefox, kitty) con colores actuales

Usuario: hm-switch (manual, cuando se desee)
  → Stylix lee ~/.cache/current-stylix-wallpaper como imagen
  → regenera paleta GTK, Firefox (fallback), cursor, GRUB, consola
```

No se usa `--impure`. Stylix usa symlink a path absoluto fuera del store, que Nix resuelve en build-time.

## Archivos nuevos

| Archivo | Propósito |
|---------|-----------|
| `home-manager/config/noctalia/config.toml` | Config TOML de Noctalia v5 |
| `home-manager/modules/noctalia.nix` | Módulo HM que importa y configura Noctalia |

## Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `flake.nix` | + input noctalia, + import noctalia homeModules |
| `home-manager/shared/default.nix` | Import noctalia.nix, remove waybar/swaync/wlogout/cliphist |
| `home-manager/modules/niri.nix` | Remove swaync service ref, fuzzel |
| `home-manager/modules/scripts.nix` | Remove niri-wallpaper, niri-clipboard. Keep niri-symlinks |
| `home-manager/modules/waybar.nix` | Remove |
| `home-manager/modules/wlogout.nix` | Remove |
| `home-manager/modules/swaync.nix` | Remove |
| `home-manager/config/niri/binds.kdl` | Update to noctalia msg commands |
| `home-manager/config/niri/startup.kdl` | waybar→noctalia, remove awww/niri-wallpaper |
| `nixos/modules/stylix.nix` | image = symlink path |

## Configuración Noctalia

Detallada en el archivo `config.toml`. Puntos clave:
- `corner_radius_scale = 0` (rectangular)
- `bar.main.radius = 0`, `capsule = false`
- `bar.main.margin_h = 180`, `margin_v = 6` (simétrico)
- `transparency_mode = "glass"`, `background_opacity = 0.88`
- `theme.source = "wallpaper"`, `scheme = "m3-tonal-spot"`
- `wallpaper.automation` cada 30 min
- Hook: actualiza symlink para Stylix

## Componentes reemplazados vs conservados

| Eliminar | Conservar |
|----------|-----------|
| programs.waybar | programs.niri |
| services.swaync | services.swayidle |
| programs.wlogout | niri-symlinks script |
| services.cliphist | Stylix (GTK, GRUB, cursor) |
| awww, swaybg | Kitty + Bash + Starship |
| niri-wallpaper script | WirePlumber |
| niri-clipboard script | SDDM |
| fuzzel | swaylock → parcialmente (Noctalia lockscreen) |

## Decisión técnica: --impure

No se usa. Stylix lee un symlink a un path absoluto (`~/.cache/current-stylix-wallpaper`).
Entre rebuilds, Noctalia mantiene todo dinámico via su theme engine + templates.

## Verificación

- `home-manager switch` debe pasar sin errores
- `nix flake check` debe pasar sin errores
- Noctalia debe iniciar correctamente con Niri
- Barra debe mostrar workspaces, clock, volume, tray, session
- Launcher debe abrir aplicaciones
- Notificaciones deben funcionar (DND toggle, MPRIS, volume)
- Wallpaper debe cambiar cada 30 min con fade
- Lock screen debe funcionar
- Clipboard history debe funcionar
