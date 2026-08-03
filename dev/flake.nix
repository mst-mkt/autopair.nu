{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nushell-skills = {
      url = "github:nushell/nu_scripts";
      flake = false;
    };
    nutest = {
      url = "github:vyadh/nutest/v1.2.0";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      agent-skills,
      nushell-skills,
      nutest,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      agentLib = agent-skills.lib.agent-skills;
      sources.nushell = {
        path = nushell-skills;
        subdir = "skills";
      };
      selection = agentLib.selectSkills {
        inherit sources;
        catalog = agentLib.discoverCatalog sources;
        allowlist = [ "nushell" ];
      };
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.just
            pkgs.knope
            pkgs.nushell
          ];

          env.NU_LIB_DIRS = "${nutest}";

          shellHook = agentLib.mkShellHook {
            inherit pkgs;
            bundle = agentLib.mkBundle { inherit pkgs selection; };
            targets.claude.dest = ".claude/skills";
          };
        };
      });

      checks = forAllSystems (pkgs: {
        tests =
          pkgs.runCommand "autopair-tests"
            {
              nativeBuildInputs = [
                pkgs.just
                pkgs.nushell
              ];
              NU_LIB_DIRS = "${nutest}";
            }
            ''
              cp ${../autopair.nu} autopair.nu
              cp ${../justfile} justfile
              cp -r ${../tests} tests

              just test
              touch $out
            '';
      });
    };
}
