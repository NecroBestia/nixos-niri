{ config, pkgs, lib, ... }:

let
  user = "necro";
in
{
  options.fileManager.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Nautilus + GVFS + UDisks2 + Polkit Agent";
  };

  config = lib.mkIf config.fileManager.enable {
    environment.systemPackages = with pkgs; [
      nautilus
      gvfs
      polkit_gnome
      udisks2
    ];

    services = {
      dbus.enable = true;
      gvfs.enable = true;
      udisks2.enable = true;
    };

    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.user == "${user}") {
          if (action.id.startsWith("org.freedesktop.udisks2.")) {
            return polkit.Result.YES;
          }
        }
      });
    '';

    # Polkit agent para sesiones no GNOME
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "Polkit GNOME Authentication Agent";
      after = [ "graphical-session.target" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        Environment = "DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000";
      };
    };
  };
}

