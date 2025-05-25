{
  lib,
  stdenv,
  cmake,

  sources,

  # Options

  # The submodules in the pico-sdk contain important additional functionality
  # such as tinyusb, but not all these libraries might be bsd3.
  # Off by default.
  withSubmodules ? false,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pico-sdk";

  src = if withSubmodules then sources.pico-sdk-full else sources.pico-sdk;

  version = (lib.mkSourceVersion finalAttrs.src false);

  nativeBuildInputs = [ cmake ];

  # SDK contains libraries and build-system to develop projects for RP2040 chip
  # We only need to compile pioasm binary
  sourceRoot = "${lib.removePrefix "${(builtins.substring 0 32 (builtins.baseNameOf finalAttrs.src))}-" (builtins.baseNameOf finalAttrs.src)}/tools/pioasm";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/pico-sdk
    cp -a ../../../* $out/lib/pico-sdk/
    chmod 755 $out/lib/pico-sdk/tools/pioasm/build/pioasm
    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/raspberrypi/pico-sdk";
    description = "SDK provides the headers, libraries and build system necessary to write programs for the RP2040-based devices";
    license = licenses.bsd3;
    maintainers = with maintainers; [
      vizid
    ];
    platforms = platforms.unix;
  };
})
