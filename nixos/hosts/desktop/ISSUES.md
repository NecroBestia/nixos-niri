# Desktop — Problemas conocidos y diagnóstico

> Documentación de problemas del host `desktop`, con evidencia de logs y
> argumentación de cada decisión. Este documento es la fuente de verdad para
> el historial de fixes aplicados a este host.
>
> Host: `desktop` · GPU: GeForce GTX 970 (GM204, Maxwell) · Driver: 570.195.03
> Kernel: linuxPackages_zen 6.18.13 (pinneado vía `nixpkgs-kernel`).
> Última actualización: 2026-08-24.

---

## 1. Greeter de SDDM con pantalla negra intermitente

**Estado: ABIERTO — mitigado (2 fixes aplicados), causa del greeter pendiente de probar.**

### 1.1 Síntoma

El arranque a veces se cuelga y el greeter (SDDM) no carga, dejando una
pantalla negra. El usuario reporta que el greeter "muchas veces no funciona
o no carga". No es determinista: el mismo sistema arranca bien en unos
intentos y mal en otros.

### 1.2 Evidencia (journalctl)

Boots relevantes del host (duración = vida del boot antes del apagado forzado):

| Boot | Fecha | Duración | Observación |
|---|---|---|---|
| -5 | 2026-08-21 16:36:50 | **10 s** | Coredump de proceso Qt6: threads de `Qt6LabsFolderListModel` (`FileInfoThread`) colgados en `pthread_cond_wait` (stack trace completo en journalctl -b -5). El usuario apagó. |
| -4 | 2026-08-21 16:37:37 | **63 s** | Kernel y driver nvidia cargan OK (`NVRM: loading ... 570.195.03`, `nvidia-drm` inicializado, `fbcon: nvidia-drmdrmfb is primary device`), pero el Xorg del greeter (`xserver-wrapper`) recién inicializa dispositivos de entrada a los **~60 s** del boot (16:38:37) → timeout típico de algo bloqueado. El usuario apagó. |
| -3 | 2026-08-21 16:39:21 | 8 h | Greeter funcionó (login OK). |
| -2 | 2026-08-24 00:21:04 | ~2 min | Arranque corto, probablemente otro fallo del greeter. |
| -1 | 2026-08-24 00:24:01 | ~1.5 h | Greeter funcionó; noctalia reporta `EGL vendor="NVIDIA"` y `OpenGL ES 3.2 NVIDIA 570.195.03` con renderer `GeForce GTX 970` → **el driver SÍ renderiza con esta GPU**. |
| 0 | 2026-08-24 17:48:11 | actual | Greeter funcionó. SDDM loguea `Loaded empty theme configuration`. |

Hallazgos adicionales:
- El coredump (boot -5) apunta al **greeter Qt6** de SDDM colgado listando
  carpetas (`Qt6LabsFolderListModel`), no al driver ni al kernel.
- SDDM reporta `Loaded empty theme configuration` (boot actual) → el tema
  `sddm-astronaut-theme` no está cargando su `theme.conf` correctamente.
- En boots buenos, noctalia confirma render NVIDIA funcional con la GTX 970
  (OpenGL ES 3.2, driver 570.195.03).

### 1.3 Causa raíz probable

Dos factores combinados:

1. **Carga del driver NVIDIA en el initrd** (`boot.initrd.kernelModules =
   [ "nvidia" "nvidia_modeset" "nvidia_drm" ]`, ahora eliminado). Con
   `boot.initrd.systemd.enable = true`, la carga temprana de nvidia en el
   initrd es una fuente conocida de cuelgues/intermitencia en el arranque.
   Además era **redundante**: `systemd-modules-load` inserta los módulos
   igual a los ~2 s del boot (evidencia: boot -4, `16:37:38 systemd-modules-load[153]: Inserted module 'nvidia'`). El initrd ya usaba `simpledrm`
   para el framebuffer temprano (evidencia: `simple-framebuffer.0 ... fb0:
   simpledrmdrmfb` en el mismo boot), por lo que nvidia en el initrd no
   aportaba nada.

2. **El greeter/tema de SDDM** (`sddm-astronaut-theme`): el coredump en
   `Qt6LabsFolderListModel` y el `Loaded empty theme configuration` apuntan
   a que el tema se cuelga al listar recursos (wallpapers/carpetas) que no
   responden. No descartado: el home del usuario contiene symlinks hacia
   `/mnt/not_to_lose` (NTFS con `x-systemd.automount`); si el greeter lista
   esos directorios, dispara el montaje del disco (que puede tardar o
   colgarse, p. ej. disco dormido) → pantalla negra durante el timeout.

### 1.4 Fixes aplicados (2026-08-24)

1. **NVIDIA fuera del initrd** — `nixos/modules/nvidia.nix`: eliminado
   `boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_drm" ]`.
   - Argumento: elimina el riesgo de cuelgue temprano sin perder nada
     (los módulos se insertan post-boot igual).
   - Verificación: `journalctl` del próximo boot debe mostrar la carga de
     nvidia vía `systemd-modules-load` (no en initrd), y `lsmod` debe
     listar `nvidia*` después del arranque.

2. **Eliminado `nvidia.NVreg_EnableGpuFirmware=0`** de `boot.kernelParams`.
   - Argumento: esa opción solo aplica a GPUs con GSP firmware (Turing+).
     La GTX 970 es Maxwell (GM204) y no tiene GSP; el parámetro era código
     muerto. Se elimina para no arrastrar configuración sin efecto.

### 1.5 Pendiente

- **Probar el tema del greeter (fix 2, NO aplicado por decisión del usuario)**: cambiar
  `services.displayManager.sddm.theme = "sddm-astronaut-theme"` → `"default"` para
  aislar si el cuelgue del greeter es del tema. Si la pantalla negra
  desaparece con el tema default, el problema es `sddm-astronaut-theme`
  (y su `theme.conf` vacío).
- Si el problema persiste tras los fixes 1-2, investigar la interacción del
  greeter con el automount NTFS (`x-systemd.automount` en
  `nixos/hosts/desktop/configuration.nix`).

---

## 2. Errores Xid de la GPU en sesión

**Estado: ABIERTO — observado, sin impacto en el arranque.**

### 2.1 Evidencia

Boot actual, 2026-08-24 18:27:53 (durante una sesión iniciada):

```
kernel: NVRM: GPU at PCI:0000:08:00: GPU-8ce1ce1a-0258-499a-a950-4b0d4b19710a
kernel: NVRM: Xid (PCI:0000:08:00): 13, Graphics Exception: MISSING_MACRO_DATA
kernel: NVRM: Xid (PCI:0000:08:00): 13, Graphics Exception: ESR 0x404490=0x80000001
kernel: NVRM: Xid (PCI:0000:08:00): 13, pid=2395, name=Renderer, Graphics Exception: ChID 0036, ...
```

### 2.2 Interpretación

Xid 13 = Graphics Exception. El proceso `Renderer` (pid 2395) generó un
error de GPU (datos de macro faltantes en un shader). Ocurre en sesión, no
en el arranque, y no se ha relacionado con la pantalla negra del greeter.

### 2.3 Acción

- No requiere fix por ahora; monitorear si se repite con alguna app concreta
  (juego/compilación de shaders). Si se vuelve frecuente, probar
  `powerManagement.finegrained = true` o revisar la app que lo dispara.

---

## 3. Observaciones menores (sin fix)

- **`system.stateVersion = "25.05"`** en ambos hosts mientras nixpkgs es
  `nixos-26.05` y Home Manager usa `26.05`. Correcto NO subir `stateVersion`
  (regla de NixOS: nunca cambiar), solo coherencia documentada.
- **Git tree del flake sucio**: al momento de esta documentación hay cambios
  sin commitear. Committear para reproducibilidad.
- **Input `noctalia` en rama `cachix`**: el lock fija el commit (a34e23c5),
  reproducible; un `nix flake update noctalia` futuro podría fallar si la
  rama cambia.

---

## Cómo verificar los fixes tras un reboot

```bash
# 1. El driver se carga post-boot (no en initrd):
journalctl -b | grep -E "Inserted module 'nvidia'"
lsmod | grep nvidia

# 2. No debe haber nvidia en el initrd:
journalctl -b | grep -i "initrd.*nvidia"   # sin resultados

# 3. El greeter arranca sin "empty theme configuration" (si se aplica fix 2):
journalctl -u display-manager | grep -i theme
```
