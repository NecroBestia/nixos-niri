#===================================================================
# AUDIO — PipeWire + WirePlumber
#===================================================================
# PipeWire es el servidor de audio/video moderno para Linux.
# Reemplaza PulseAudio y JACK con una sola capa:
#   - pipewire: núcleo de procesamiento de audio/video.
#   - wireplumber: gestor de sesiones (dispositivos, rutas, volumen).
#   - ALSA: compatibilidad con apps que usan ALSA directamente.
#   - PulseAudio: compatibilidad con apps que usan PulseAudio.
#   - JACK: compatibilidad con apps de audio profesional.
#
# CONFIGURACIÓN DE LATENCIA:
#   - quantum (tamaño de buffer): 1024 frames (~21ms a 48kHz).
#     Valor equilibrado: funcionamiento fluido en general, sin
#     clicks/pops, pero sin la ultra-baja latencia para producción.
#   - min-quantum: 32 (~0.6ms) para apps que solicitan baja latencia.
#   - max-quantum: 8192 (~170ms) para streaming sin cortes.
#   - rate: 48000 Hz (Frecuencia estándar de estudio/DVD).
#===================================================================
{
  # rtkit: Permite a PipeWire ejecutarse con prioridad en tiempo real
  # (necesario para baja latencia en reproducción de audio).
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;              # Activa el servidor multimedia.
    alsa.enable = true;         # Soporte para apps ALSA nativas.
    alsa.support32Bit = true;   # Soporte 32-bit (Steam, Wine).
    pulse.enable = true;        # Compatibilidad con apps PulseAudio.
    jack.enable = true;         # Compatibilidad con apps JACK.
    wireplumber.enable = true;  # Gestor de sesiones moderno.

    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 8192;
      };
    };
  };
}
