{
  lib,
  python3Packages,

  pycvc,
  pypicohsm,
  pico-hsm,
  ...
}:
python3Packages.buildPythonApplication (
  lib.fix (final: {
    pname = "pico-hsm-tool";

    inherit (pico-hsm) src;

    version = "2.4";
    pyproject = true;

    doCheck = false;

    sourceRoot = "source/tools";

    patchPhase = ''
      mv pico-hsm-tool.py pico-hsm-tool
      cat > setup.py <<EOF
      from setuptools import setup
      setup(
        name = "${final.pname}",
        version = "${final.version}",
        scripts = ["pico-hsm-tool"],
        package_dir = {"": "."}
      )
      EOF
    '';

    build-system = with python3Packages; [ setuptools ];

    dependencies = with python3Packages; [
      keyring
      cryptography
      pycvc
      pypicohsm
    ];

    meta = {
      description = "Tool for interacting with the Pico HSM";
      homepage = "https://github.com/polhenarejos/pico-hsm";
      license = lib.licenses.gpl3Only;
      maintainers = with lib.maintainers; [ vizid ];
    };
  })
)
