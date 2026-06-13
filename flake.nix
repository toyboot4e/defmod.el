{
  description = "defmod.el — a package-configuration macro that only schedules";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems =
        f: nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            (pkgs.emacs.pkgs.withPackages (epkgs: [ epkgs.package-lint ]))
            pkgs.just
            pkgs.pinact
            pkgs.zizmor
          ];
        };
      });

      checks = forAllSystems (pkgs: {
        # Static security audit of the GitHub Actions workflows.  Offline so
        # the build stays pure; pinning is verified by pinact in CI.
        zizmor = pkgs.runCommand "zizmor-check" { nativeBuildInputs = [ pkgs.zizmor ]; } ''
          cd ${self}
          zizmor --offline . && touch $out
        '';
      });
    };
}
