final: prev: rec {
  pico-sdk = prev.pico-sdk.overrideAttrs {
    # author: https://github.com/leo60228 ##
    setupHook = prev.writeText "setupHook.sh" ''
      addPicoSdkPath() {
        if [ -e "$1/lib/pico-sdk" ]; then
          export PICO_SDK_PATH="$1/lib/pico-sdk"
        fi
      }
      addEnvHooks "$hostOffset" addPicoSdkPath
      ##
    '';
  };
  pico-sdk-full = pico-sdk.override {
    withSubmodules = true;
  };

  pycvc = prev.callPackage ./pkgs/pycvc.nix { };
  pypicohsm = prev.callPackage ./pkgs/pypicohsm.nix { };

  pico-openpgp = prev.callPackage ./pkgs/pico-openpgp.nix { };

  pico-hsm-packages = prev.callPackage ./pkgs/pico-hsm-packages.nix { };
  pico-hsm = prev.callPackage (pico-hsm-packages.pico-hsm) { };
  pico-hsm-tool = prev.callPackage (pico-hsm-packages.pico-hsm-tool) { };

  pico-nuke = prev.callPackage ./pkgs/pico-nuke.nix { };

  pico-fido-packages = prev.callPackage ./pkgs/pico-fido-packages.nix { };
  pico-fido = prev.callPackage (pico-fido-packages.pico-fido) { };
  pico-fido-tool = pico-fido-packages.pico-fido-tool;
}
