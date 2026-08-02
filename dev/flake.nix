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
  };

  outputs =
    {
      nixpkgs,
      agent-skills,
      nushell-skills,
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
          packages = [ pkgs.nushell ];

          shellHook = agentLib.mkShellHook {
            inherit pkgs;
            bundle = agentLib.mkBundle { inherit pkgs selection; };
            targets.claude.dest = ".claude/skills";
          };
        };
      });
    };
}
