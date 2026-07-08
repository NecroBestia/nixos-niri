#===================================================================
# LOCALE — Zona Horaria e Idioma
#===================================================================
# Configura la zona horaria, idioma principal y valores regionales.
# Se usa es_CL (Chile) para la mayoría de configuraciones regionales,
# y es_MX como locale por defecto por compatibilidad con teclados latam.
#===================================================================
{
  time.timeZone = "America/Santiago";
  i18n.defaultLocale = "es_MX.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_CL.UTF-8";
    LC_IDENTIFICATION = "es_CL.UTF-8";
    LC_MEASUREMENT = "es_CL.UTF-8";
    LC_MONETARY = "es_CL.UTF-8";
    LC_NAME = "es_CL.UTF-8";
    LC_NUMERIC = "es_CL.UTF-8";
    LC_PAPER = "es_CL.UTF-8";
    LC_TELEPHONE = "es_CL.UTF-8";
    LC_TIME = "es_CL.UTF-8";
  };
}
