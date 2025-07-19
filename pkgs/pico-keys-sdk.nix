{
  fetchFromGitHub,

  stdenvNoCC,

  pico-keys-sdk-src ? fetchFromGitHub {
    owner = "polhenarejos";
    repo = "pico-keys-sdk";
    tag = "v7.0";
    hash = "sha256-+G71D8VwF0aTnVDZELzWUBaJKOQlhzSdnSkRpgdpCyI=";
  },
  pico-keys-sdk-version ? "7.0",
  mbedtls-src ? fetchFromGitHub {
    owner = "Mbed-TLS";
    repo = "mbedtls";
    rev = "107ea89daaefb9867ea9121002fbbdf926780e98";
    hash = "sha256-CigOAezxk79SSTX6Z7rDnt64qI6nkCD0piY9ZVNy+e0=";
  },
  tinycbor-src ? fetchFromGitHub {
    owner = "intel";
    repo = "tinycbor";
    rev = "e27261ed5e2ed059d160f16ae776951a08a861fc";
    hash = "sha256-/5FcwsEhJfh6noV0HJAQVTHBGHDBc99KwOnPsaeUlLw=";
  },

  ...
}:
stdenvNoCC.mkDerivation {
  pname = "pico-keys-sdk";

  version = pico-keys-sdk-version;
  src = pico-keys-sdk-src;

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    outpath="$out/share/pico-keys-sdk"
    mkdir -p "$outpath"
    cp -r "$src/." "$outpath"
    rm -rf "$outpath/mbedtls" "$outpath/tinycbor"
    cp -r "${mbedtls-src}" "$outpath/mbedtls"
    cp -r "${tinycbor-src}" "$outpath/tinycbor"
    runHook postInstall
  '';
}
