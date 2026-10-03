{
  perSystem =
    { pkgs, ... }:
    let
      py = pkgs.python314.pkgs;

      # jj-stack requires httpx2 >= 2.12.0, but nixpkgs pins httpx2/httpcore2 at
      # 2.9.1. Build the matching upstream wheels instead.
      httpcore2 = py.buildPythonPackage {
        pname = "httpcore2";
        version = "2.12.0";
        format = "wheel";
        src = pkgs.fetchurl {
          url = "https://files.pythonhosted.org/packages/d2/74/d370e55600d9bcfa0d9794b0166126d49291a3d2b20c268fc98c453a4948/httpcore2-2.12.0-py3-none-any.whl";
          sha256 = "sha256-fgQljOAQE9fWFeW5EKOyf6yTfXqVA4In55ZStLo7TOs=";
        };
        propagatedBuildInputs = [
          py.h11
          py.truststore
        ];
        doCheck = false;
        doInstallCheck = false;
        meta = {
          description = "A minimal low-level HTTP client";
          homepage = "https://github.com/pydantic/httpx2";
          license = pkgs.lib.licenses.bsd3;
        };
      };

      httpx2 = py.buildPythonPackage {
        pname = "httpx2";
        version = "2.12.0";
        format = "wheel";
        src = pkgs.fetchurl {
          url = "https://files.pythonhosted.org/packages/c8/95/411ba65569158e862368917aaf56597f3e5fa3b91b0502919638465a08f3/httpx2-2.12.0-py3-none-any.whl";
          sha256 = "sha256-zItu7LhmHBRrj4mmDpdFbuCG6Rp4TtMaxFDDqeYT3TY=";
        };
        propagatedBuildInputs = [
          httpcore2
          py.anyio
          py.idna
          py.truststore
        ];
        doCheck = false;
        doInstallCheck = false;
        meta = {
          description = "A next generation HTTP client for Python";
          homepage = "https://github.com/pydantic/httpx2";
          license = pkgs.lib.licenses.bsd3;
        };
      };
    in
    {
      packages.jj-stack = py.buildPythonPackage {
        pname = "jj-stack";
        version = "0.1.6";
        format = "wheel";
        src = pkgs.fetchurl {
          url = "https://files.pythonhosted.org/packages/c2/b6/4e9f783f4d90020454cbe59abca6b7d634888cf947d7820ece8215329c8b/jj_stack-0.1.6-py3-none-any.whl";
          sha256 = "sha256-wYp6GZH0g9ueGcKNk+Wrr22f+seYRjUx2wByekX2usA=";
        };

        propagatedBuildInputs = [
          httpx2
          py.markdown-it-py
          py.pydantic
          py.rich
        ];

        doCheck = false;
        doInstallCheck = false;
        meta = {
          description = "Stacked GitHub pull requests for Jujutsu";
          homepage = "https://github.com/bos/jj-stack";
          license = pkgs.lib.licenses.asl20;
          mainProgram = "jj-stack";
        };
      };
    };
}
