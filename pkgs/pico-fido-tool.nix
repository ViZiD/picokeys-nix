{
  lib,
  python3Packages,

  pico-fido,
  ...
}:
python3Packages.buildPythonApplication (
  lib.fix (final: {
    pname = "pico-fido-tool";
    version = "1.8";

    inherit (pico-fido) src;

    doCheck = false;

    sourceRoot = "source/tools";

    pyproject = true;

    patchPhase = ''
      mv pico-fido-tool.py pico-fido-tool
      cat > setup.py <<EOF
      from setuptools import setup
      setup(
        name = "${final.pname}",
        version = "${final.version}",
        scripts = ["pico-fido-tool"],
        package_dir = {"": "."}
      )
      EOF
    '';

    build-system = with python3Packages; [ setuptools ];

    dependencies = with python3Packages; [
      keyring
      cryptography
      fido2
    ];

    meta = {
      description = "Tool for interacting with the Pico Fido";
      homepage = "https://github.com/polhenarejos/pico-fido";
      license = lib.licenses.gpl3Only;
      maintainers = with lib.maintainers; [ vizid ];
    };
  })
)
