{
  lib,
  fetchFromGitHub,
  python3Packages,
  pycvc,
  ...
}:
python3Packages.buildPythonPackage (
  lib.fix (final: {
    pname = "pypicohsm";
    version = "1.7";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "polhenarejos";
      repo = "pypicohsm";
      rev = "v${final.version}";
      hash = "sha256-4Ejsn7MR6AhRygTPFh7qIf+oc0zlNH4DD8aTI8tlhVo=";
    };

    build-system = with python3Packages; [
      setuptools
    ];

    dependencies = with python3Packages; [
      cryptography
      base58
      pyusb
      pycvc
      pyscard
    ];

    doCheck = false;

    pythonImportsCheck = [
      "picohsm"
    ];

    meta = {
      description = "Pico HSM client for Python";
      homepage = "https://github.com/polhenarejos/pypicohsm";
      license = lib.licenses.gpl3Only;
      maintainers = with lib.maintainers; [ vizid ];
    };
  })
)
