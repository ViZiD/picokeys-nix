{
  lib,
  stdenvNoCC,
  sources,
}:

stdenvNoCC.mkDerivation {
  pname = "tinycbor";
  version = (lib.mkSourceVersion sources.tinycbor true);

  src = sources.tinycbor;

  dontBuild = true;
  dontConfigure = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/tinycbor
    cp -r . $out/share/tinycbor
    runHook postInstall
  '';

  meta = {
    description = "Concise Binary Object Representation (CBOR) Library";
    homepage = "https://github.com/intel/tinycbor/tree/e27261ed5e2ed059d160f16ae776951a08a861fc";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ vizid ];
  };
}
