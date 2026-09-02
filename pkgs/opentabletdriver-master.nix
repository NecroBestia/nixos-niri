#===================================================================
# OpenTabletDriver — build desde master (nightly) con fix del kernel 6.11+
#===================================================================
# nixpkgs solo tiene 0.6.7, incompatible con Linux >= 6.11 (hidraw
# multi-report descriptor, ioctl devuelve EBADF). Este paquete usa la
# rama master del repo con un commit pinneado y .NET 10.
#===================================================================
{ lib
, buildDotnetModule
, copyDesktopItems
, coreutils
, dotnetCorePackages
, fetchFromGitHub
, gtk3
, jq
, libappindicator
, libevdev
, libnotify
, libx11
, libxrandr
, makeDesktopItem
, udev
, wrapGAppsHook3
, versionCheckHook
, udevCheckHook
}:

buildDotnetModule (finalAttrs: {
  pname = "OpenTabletDriver";
  version = "0.7.0-master-19ff643";

  src = fetchFromGitHub {
    owner = "OpenTabletDriver";
    repo = "OpenTabletDriver";
    rev = "19ff64385e21a466b5bfb47d2791fcb3d9a9a334";
    hash = "sha256-XBQiRztfa6E8W85mI3fIbSNhXHETvVa/cQCsTHv4AXA=";
  };

  dotnet-sdk = dotnetCorePackages.sdk_10_0;

  projectFile = [
    "OpenTabletDriver.Console"
    "OpenTabletDriver.Daemon"
    "OpenTabletDriver.UX.Gtk"
  ];
  nugetDeps = ./deps.json;

  executables = [
    "OpenTabletDriver.Console"
    "OpenTabletDriver.Daemon"
    "OpenTabletDriver.UX.Gtk"
  ];

  nativeBuildInputs = [
    copyDesktopItems
    wrapGAppsHook3
    udevCheckHook
    jq
  ];

  runtimeDeps = [
    gtk3
    libappindicator
    libevdev
    libnotify
    libx11
    libxrandr
    udev
  ];

  buildInputs = finalAttrs.runtimeDeps;

  doCheck = true;
  testProjectFile = "OpenTabletDriver.Tests/OpenTabletDriver.Tests.csproj";

  disabledTests = [
    "OpenTabletDriver.Tests.UpdaterTests.*"
    "OpenTabletDriver.Tests.TimerTests.TimerAccuracy"
  ];

  preBuild = ''
    patchShebangs generate-rules.sh
    substituteInPlace generate-rules.sh \
      --replace-fail '/usr/bin/env rm' '${lib.getExe' coreutils "rm"}'
  '';

  dontWrapGApps = true;

  postFixup = ''
    mv $out/bin/OpenTabletDriver.Console $out/bin/otd
    mv $out/bin/OpenTabletDriver.Daemon $out/bin/otd-daemon
    mv $out/bin/OpenTabletDriver.UX.Gtk $out/bin/otd-gui

    install -Dm644 $src/OpenTabletDriver.UX/Assets/otd.png -t $out/share/icons

    mkdir -p $out/lib/udev/rules.d
    ./generate-rules.sh > $out/lib/udev/rules.d/70-opentabletdriver.rules

    wrapProgram $out/bin/otd-gui \
      "''${gappsWrapperArgs[@]}" \
      --add-flags --skipupdate
  '';

  desktopItems = [
    (makeDesktopItem {
      desktopName = "OpenTabletDriver";
      name = "OpenTabletDriver";
      exec = "otd-gui";
      icon = "otd";
      comment = "Open source, cross-platform, user-mode tablet driver";
      categories = [ "Utility" ];
    })
  ];

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgram = "${placeholder "out"}/bin/otd-daemon";

  meta = {
    changelog = "https://github.com/OpenTabletDriver/OpenTabletDriver/commits/${finalAttrs.src.rev}";
    description = "Open source, cross-platform, user-mode tablet driver (master/nightly build)";
    homepage = "https://github.com/OpenTabletDriver/OpenTabletDriver";
    license = lib.licenses.lgpl3Plus;
    mainProgram = "otd";
    maintainers = with lib.maintainers; [ ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
