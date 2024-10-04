{
  lib,
  fetchurl,
  stdenvNoCC,
  unzip,
}:
let
  components = {
    tinyusb = {
      version = "0.15.010";
      url = "https://components.espressif.com/api/download/?object_type=component&object_id=55142eec-a3a4-47a5-ad01-4ba3ef44444b";
      hash = "sha256-J45+u7YReAUE5EJQmkchv2a6zDJDUUUwEBmoTQB+2lU=";
      targetDir = "espressif__tinyusb";
    };
    esp_tinyusb = {
      version = "1.4.5";
      url = "https://components.espressif.com/api/download/?object_type=component&object_id=8115ffc9-366a-4340-94ab-e327aed20831";
      hash = "sha256-9dEqJYprgEKS7Fz0LKjjHSOJD0b6c/g2NN6rjmoYvmw=";
      targetDir = "esp_tinyusb";
    };
    neopixel = {
      version = "1.0.4";
      url = "https://components.espressif.com/api/download/?object_type=component&object_id=9e9938df-1535-46a1-9156-20b3351e8961";
      hash = "sha256-xkvjiawtaiAfFPFpzKYz6opPawSmfAQLjaRcLxyJzfk=";
      targetDir = "zorxx__neopixel";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "idf-components";
  version = "0.0.1";

  nativeBuildInputs = [ unzip ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value: ''
        mkdir -p $out/${value.targetDir}
        unzip -q ${
          fetchurl {
            url = value.url;
            hash = value.hash;
            name = "${name}-${value.version}.zip";
          }
        } -d $out/${value.targetDir}
      '') components
    )}
    runHook postInstall
  '';
}
