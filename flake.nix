{
  description = "Dev shell and Linting";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    precommit = {
      url = "github:FredSystems/pre-commit-checks";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      precommit,
      ...
    }:
    let
      systems = precommit.lib.supportedSystems;
      inherit (nixpkgs) lib;
    in
    {
      ##########################################################################
      ## PRE-COMMIT CHECKS
      ##########################################################################
      checks = lib.genAttrs systems (system: {
        pre-commit = precommit.lib.mkCheck {
          inherit system;
          src = ./.;

          # ── Feature toggles ─────────────────────────────
          check_rust = false;
          check_docker = true;
          check_python = false;

          # Rust-specific knobs (safe to leave here)
          enableXtask = false;

          # Python-specific knobs (safe to leave here)
          python = {
            enableBlack = true;
            enableFlake8 = true;
          };
        };
      });

      ##########################################################################
      ## DEV SHELL
      ##########################################################################
      devShells = lib.genAttrs systems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          chk = self.checks.${system}.pre-commit;
        in
        {
          default = pkgs.mkShell {
            buildInputs =
              chk.enabledPackages
              ++ (chk.passthru.devPackages or [ ])
              ++ (with pkgs; [
                pre-commit
                check-jsonschema
                codespell
                typos
                nixfmt
                markdownlint-cli2
              ]);

            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (chk.passthru.libPath or [ ]);

            shellHook = ''
              ${chk.shellHook}
              alias pre-commit="pre-commit run --all-files"
            '';
          };
        }
      );
    };
}
