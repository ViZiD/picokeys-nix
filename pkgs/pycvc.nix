{
  lib,
  fetchFromGitHub,
  python3Packages,
  ...
}:
python3Packages.buildPythonPackage (
  lib.fix (final: {
    pname = "pycvc";
    version = "1.5.0";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "polhenarejos";
      repo = "pycvc";
      rev = "v${final.version}";
      hash = "sha256-h0KwHS8V347GQQL0uLGwmQPKVb29PIwOTnvIEa5NTq8=";
    };

    build-system = with python3Packages; [ setuptools ];

    dependencies = with python3Packages; [ cryptography ];

    doCheck = false;

    pythonImportsCheck = [
      "cvc"
    ];

    meta = {
      description = "Card Verifiable Certificates (CVC) tools for Python";
      homepage = "https://github.com/polhenarejos/pycvc";
      license = lib.licenses.gpl3Only;
      maintainers = with lib.maintainers; [ vizid ];
    };
  })
)
