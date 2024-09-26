{ lib, newScope }:
lib.makeScope newScope (self: {
  pico-sdk = self.callPackage ./picosdk.nix { };
  pico-sdk-minimal = self.callPackage ./picosdk.nix {
    minimal = true;
    picotool = null;
  };
  picotool = self.callPackage ./picotool.nix { };

  pycvc = self.callPackage ./pycvc.nix { };
  pypicohsm = self.callPackage ./pypicohsm.nix { };

  pico-openpgp = self.callPackage ./pico-openpgp.nix { };

  pico-hsm-packages = self.callPackage ./pico-hsm-packages.nix { };
  pico-hsm = self.callPackage (self.pico-hsm-packages.pico-hsm) {
    picoBoard = "pimoroni_plasma2040";
  };
  pico-hsm-tool = self.callPackage (self.pico-hsm-packages.pico-hsm-tool) { };
})
