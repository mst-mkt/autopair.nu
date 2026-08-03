{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      mkAutopair =
        pkgs:
        pkgs.stdenvNoCC.mkDerivation {
          pname = "autopair.nu";
          version = "0.0.0";

          src = ./autopair.nu;
          dontUnpack = true;

          installPhase = ''
            runHook preInstall
            install -Dm444 $src $out/share/nushell/vendor/autoload/autopair.nu
            runHook postInstall
          '';

          meta = {
            description = "Auto-pair brackets and quotes as you type in Nushell";
            homepage = "https://github.com/mst-mkt/autopair.nu";
            license = nixpkgs.lib.licenses.mit;
            platforms = nixpkgs.lib.platforms.all;
          };
        };
    in
    {
      packages = forAllSystems (pkgs: rec {
        autopair-nu = mkAutopair pkgs;
        default = autopair-nu;
      });

      checks = forAllSystems (pkgs: {
        load = pkgs.runCommand "autopair-load" { nativeBuildInputs = [ pkgs.nushell ]; } ''
          nu -n -c 'source ${./autopair.nu}'
          touch $out
        '';
      });

      overlays.default = final: _prev: {
        autopair-nu = mkAutopair final;
      };

      homeModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.programs.autopair-nu;
        in
        {
          options.programs.autopair-nu = {
            enable = lib.mkEnableOption "autopair.nu";

            package = lib.mkOption {
              type = lib.types.package;
              default = mkAutopair pkgs;
              defaultText = lib.literalMD "the `autopair.nu` package from this flake";
              description = "The autopair.nu package to use.";
            };
          };

          config = lib.mkIf cfg.enable {
            home.file."${config.programs.nushell.configDir}/autoload/autopair.nu".source =
              "${cfg.package}/share/nushell/vendor/autoload/autopair.nu";
          };
        };
    };
}
