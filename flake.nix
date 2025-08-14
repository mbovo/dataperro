{
  description = "generic venv flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, poetry2nix, ... }@inputs: inputs.flake-utils.lib.eachDefaultSystem(
    system:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication defaultPoetryOverrides mkPoetryPackages;
      formatter = pkgs.nixfmt-rfc-style;
      python = pkgs.python313;
      venv = "./.venv";
      projectDir = ./.;
      preferWheels = true;
      #overrides = "";
      poetryPkgs = mkPoetryPackages {
        inherit projectDir preferWheels; #overrides;
      };
    in {
      inherit formatter;

      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          pre-commit
          go-task
          poetry
          docker
          cachix
          statix
        ];
        buildInputs = with pkgs.python311Packages; [
          python
          venvShellHook
        ];
        venvDir = venv;
        postVenvCreation = ''
          unset SOURCE_DATE_EPOCH
          python -m venv .venv --prompt $(echo $PWD | sed 's?.*prjs/\([-a-zA-z0-9]*\)/.*?\1?') --upgrade-deps
          poetry env use ${venv}/bin/python
          poetry install --no-root
        '';
        postShellHook = ''
          unset SOURCE_DATE_EPOCH
          poetry env info
        '';
        PYTHONDONTWRITEBYTECODE = 1;
        POETRY_VIRTUALENVS_IN_PROJECT = 1;
      };

      packages = {
        default = self.packages.${system}.cli;
        cli = mkPoetryApplication {
          inherit projectDir preferWheels; #overrides;
          propagatedBuildInputs = [ poetryPkgs.poetryPackages ];
        };
        module = pkgs.python3Packages.buildPythonPackage {
          name = "dataperro";
          src = self;
          projectDir = ./.;
          format = "pyproject";
          nativeBuildInputs = [
            pkgs.python3Packages.poetry-core
            pkgs.python3Packages.setuptools
          ];
          propagatedBuildInputs = [
            poetryPkgs.poetryPackages
            pkgs.python3Packages.setuptools
          ];
          nativeCheckInputs = [
            pkgs.python3Packages.pytestCheckHook
          ];
          pythonImportsCheck = [
            "dataperro"
          ];
        };
      };
    }
  );
}
