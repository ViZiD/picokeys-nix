# author: https://github.com/leo60228/nix-rp2040
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  libusb1,
  pico-sdk-minimal,
}:

stdenv.mkDerivation rec {
  pname = "picotool";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = pname;
    rev = version;
    hash = "sha256-z7EFk3qxg1PoKZQpUQqjhttZ2RkhhhiMdYc9TkXzkwk=";
  };

  buildInputs = [
    libusb1
    pico-sdk-minimal
  ];
  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  postInstall = ''
    install -Dm444 ../udev/99-picotool.rules -t $out/etc/udev/rules.d
  '';

  meta = with lib; {
    homepage = "https://github.com/raspberrypi/picotool";
    description = "Tool for interacting with a RP2040 device in BOOTSEL mode, or with a RP2040 binary";
    mainProgram = "picotool";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
}
